.import QtQuick.LocalStorage 2.0 as LS

var DAY_LENGTH = 24 * 3600 * 1000;

function getUnixTime() {
    return (new Date()).getTime()
}

// return the next midnight in milliseconds since the epoch
function getMidnight() {
    var today = new Date();
    var start = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
    return start + DAY_LENGTH;
}

// create DB with schema v2.0 from scratch
function createDB(tx) {
    console.log("createDB is called");
    tx.executeSql("CREATE TABLE lists(" +
                        "ID INTEGER PRIMARY KEY AUTOINCREMENT, " +
                        "ListName TEXT UNIQUE)");
    tx.executeSql("CREATE TABLE tasks(" +
                        "ID INTEGER PRIMARY KEY AUTOINCREMENT, " +
                        "Task TEXT NOT NULL, " +
                        "ListID INTEGER NOT NULL, " +
                        "Status INTEGER, " +
                        "LastUpdate INTEGER NOT NULL, " +
                        "CreationDate INTEGER NOT NULL, " +
                        "DueDate INTEGER, " +
                        "Duration INTEGER, " +
                        "Priority INTEGER NOT NULL, " +
                        "Note TEXT, " +
                        "FOREIGN KEY(ListID) REFERENCES lists(ID), CONSTRAINT unq UNIQUE (Task, ListID))");
    tx.executeSql("CREATE TABLE tags(ID INTEGER PRIMARY KEY AUTOINCREMENT, Tag TEXT NOT NULL UNIQUE)");
    tx.executeSql("CREATE TABLE task_tags(TaskID INTEGER NOT NULL, TagID INTEGER NOT NULL,\
                    FOREIGN KEY(TaskID) REFERENCES tasks(ID), FOREIGN KEY(TagID) REFERENCES tags(ID), \
                    CONSTRAINT unq UNIQUE (TaskID, TagID))");
    tx.executeSql("CREATE TABLE settings(" +
                        "ID INTEGER PRIMARY KEY AUTOINCREMENT, " +
                        "Setting TEXT UNIQUE, Value TEXT)");
    tx.executeSql("CREATE UNIQUE INDEX uid ON tasks(ID, Task, ListID)");
}

// TODO
function upgradeSchema(fromVersion) {
    console.log("upgradeSchema is called. Terminating");
    Qt.quit();
    if (fromVersion === "1.0") {
        // TODO modify lists and tasks..
        tx.executeSql("CREATE TABLE tags(" +
                      "Tag TEXT NOT NULL, TaskID INTEGER NOT NULL, " +
                      "FOREIGN KEY(TaskID) REFERENCES tasks(ID), CONSTRAINT unq UNIQUE (Tag, TaskID))");
        fromVersion = "2.0";
    }
    // here goes later upgrades..
}

function connectDB() {
    // connect to the local database: a version is not specified, so that it could be increased later
    return LS.LocalStorage.openDatabaseSync("TaskList", "", "TaskList Database", 100000);
}

function initializeDB() {
    // initialize DB connection
    var db = connectDB();

    if (db.version === "") {
        db.changeVersion("", "2.0", createDB);
    } else if (db.version === "1.0") {
        db.changeVersion("1.0", "2.0", function(tx) {
            upgradeSchema("1.0");
        });
    }

    // run initialization queries
    db.transaction(
        function(tx) {
            // if lists are empty, create default list
            var result = tx.executeSql("SELECT count(ID) as cID FROM lists");
            if (result.rows.item(0)["cID"] == 0) {
                tx.executeSql("INSERT INTO lists (ListName) VALUES ('Tasks')");
            }

            // if a setting is not assigned, set its value to default
            var defaultSettings = {
                "defaultList": 1,
                "coverListSelection": 1,
                "coverListChoose": 1,
                "coverListOrder": 0,
                "taskOpenAppearance": 1,
                "dateFormat": 0,
                "timeFormat": 0,
                "remorseOnDelete": 5,
                "remorseOnMark": 2,
                "remorseOnMultiAdd": 5,
                "startPage": 0,
                "backFocusAddTask": 1,
                "smartListVisibility": 1,
                "recentlyAddedOffset": 3,
                "doneTasksStrikedThrough": 0
            };
            for (var settingKey in defaultSettings) {
                var res = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting=?", settingKey);
                if (res.rows.item(0)["cSetting"] === 0) {
                    var defaultValue = defaultSettings[settingKey];
                    tx.executeSql("INSERT INTO settings (Setting, Value) VALUES (?, ?);", [settingKey, defaultValue]);
                }
            }
        }
    );

    return db;
}

/***************************************/
/*** SQL functions for TASK handling ***/
/***************************************/

function appendTaskToPage(task) {
    taskPage.appendTask(task.ID, task.Task, task.Status === 1, task.ListID, task.DueDate, task.Priority);
}

// select tasks and push them into the tasklist
function readTasks(listID, status, sort) {
    var db = connectDB();
    var statusSql;
    var order = "Status DESC";
    var condition = "ListID = " + listID;

    if (typeof(status) !== 'undefined')
        condition += " AND Status = " + status;

    if (typeof(sort) !== 'undefined' && sort !== "")
        order += sort;
    else
        order += ", LastUpdate DESC";

    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tasks WHERE " + condition + " ORDER BY " + order);
        for(var i = 0; i < result.rows.length; ++i)
            appendTaskToPage(result.rows.item(i));
    });
}

// select tasks on a global basis instead of list basis
function readSmartListTasks(smartListType) {
    var db = connectDB();
    var recentlyAddedOffsetTime = getUnixTime() - taskListWindow.recentlyAddedPeriods[taskListWindow.recentlyAddedOffset] * 1000;
    var midnight = getMidnight();
    var tomorrowMidnight = midnight + DAY_LENGTH;
    var condition = "";

    if (smartListType === 0)
        condition = "Status = '0'";
    else if (smartListType === 1)
        condition = "Status = '1'";
    else if (smartListType === 2)
        condition = "CreationDate > '" + recentlyAddedOffsetTime + "'";
    else if (smartListType === 3)
        condition = "'0' < DueDate AND DueDate < '" + midnight + "' AND Status= '1'";
    else if (smartListType === 4)
        condition = "'" + midnight + "' <= DueDate AND DueDate < '" + tomorrowMidnight + "' AND Status = '1'";
    else
        return;

    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tasks WHERE " + condition + " ORDER BY Status DESC, Priority DESC");
        for(var i = 0; i < result.rows.length; ++i)
            appendTaskToPage(result.rows.item(i));
    });
}

// select task and return count
function checkTask(listID, taskname) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT count(ID) as cID FROM tasks WHERE ListID=? AND Task=?;", [listID, taskname]);
    });

    return result.rows.item(0).cID;
}

// insert new task and return id or -1 if error
function writeTask(listID, task, status, dueDate, duration, priority, note) {
    var db = connectDB();
    var creationDate = getUnixTime();
    var taskID = -1;

    if (typeof(priority) === 'undefined')
        priority = 0;

    try {
        db.transaction(function(tx) {
            var statement = "INSERT INTO tasks (Task, ListID, Status, LastUpdate, CreationDate, DueDate, Duration, Priority, Note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?);";
            tx.executeSql(statement, [task, listID, status, creationDate, creationDate, dueDate, duration, priority, note]);
            tx.executeSql("COMMIT;");
            var result = tx.executeSql("SELECT ID FROM tasks WHERE Task=? AND ListID=?;", [task, listID]);
            taskID = result.rows.item(0).ID;
        });
    } catch (sqlErr) {
        console.log("Unable to write a new task");
    }
    return taskID;
}

// delete task from database
function removeTask(id) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM tasks WHERE ID=?", id);
        tx.executeSql("COMMIT;");
    });
}

// change a task status
function setTaskStatus(id, status) {
    var db = connectDB();
    var lastUpdate = getUnixTime();

    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE tasks SET Status=?, LastUpdate=? WHERE ID=?", [status, lastUpdate, id]);
            tx.executeSql("COMMIT;");
        });
        return true;
    } catch (sqlErr) {
        console.log("Unable to change a task status in DB");
    }
    return false;
}

// update task
function updateTask(id, newListID, task, status, dueDate, duration, priority, note) {
    var db = connectDB();
    var result;
    var lastUpdate = getUnixTime();

    try {
        db.transaction(function(tx) {
            result = tx.executeSql("UPDATE tasks " +
                                   "SET ListID=?, Task=?, Status=?, LastUpdate=?, DueDate=?, Duration=?, Priority=?, Note=? " +
                                   "WHERE ID=?;",
                                   [newListID, task, status, lastUpdate, dueDate, duration, priority, note, id]);
            tx.executeSql("COMMIT;");
        });
        return result.rowsAffected === 1;
    } catch (sqlErr) {
        console.log("Unable to update task in DB");
    }
    return false;
}

// get task property from database
function getTaskProperty(id, taskproperty) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT " + taskproperty + " FROM tasks WHERE ID=?;", [id]);
    });

    return eval("result.rows.item(0)." + taskproperty);
}

function packTask(record) {
    return {ID: record.ID, Task: record.Task, ListID: record.ListID, Status: record.Status,
            LastUpdate: record.LastUpdate, CreationDate: record.CreationDate,
            DueDate: record.DueDate, Duration: record.Duration,
            Priority: record.Priority, Note: record.Note};
}

// dump tasks from all lists
function dumpData() {
    var db = connectDB();
    var lists = [];

    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT ID, ListName from lists");
        for (var i = 0; i < result.rows.length; ++i) {
            lists.push({ID: result.rows.item(i).ID, ListName: result.rows.item(i).ListName});
        }
    });

    var tasksGrouped = [];
    for (var i = 0; i < lists.length; ++i) {
        var ListID = lists[i].ID;
        var items = [];
        db.transaction(function(tx) {
            var result = tx.executeSql("SELECT * from tasks WHERE ListID=?", ListID);
            for (var j = 0; j < result.rows.length; ++j)
                items.push(packTask(result.rows.item(j)));
        });
        tasksGrouped.push({ID: ListID, ListName: lists[i].ListName, items: items});
    }
    return JSON.stringify(tasksGrouped);
}

function clearTable(table) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM " + table);
        tx.executeSql("COMMIT;");
    });
}

function validateParsed(tasksGrouped) {

    var _check = function(field) {
        return typeof field !== 'undefined';
    }

    if (!_check(tasksGrouped)) return false;
    if (tasksGrouped.length < 1)
        return false;

    for (var i = 0; i < tasksGrouped.length; ++i) {
        var g = tasksGrouped[i];
        if (!_check(g.ListName)) return false;
        if (!_check(g.ID)) return false;
        var items = g.items;
        if (!_check(items)) return false;
        for (var j = 0; j < items.length; ++j) {
            var it = items[j];
            if (!_check(it.ID)) return false;
            if (!_check(it.Task)) return false;
            if (!_check(it.ListID)) return false;
            if (it.ListID !== g.ID)
                return false;
            if (!_check(it.Status)) return false;
            if (!_check(it.LastUpdate)) return false;
            if (!_check(it.CreationDate)) return false;
            if (!_check(it.DueDate)) return false;
            if (!_check(it.Duration)) return false;
        }
    }
    return true;
}

function test_validateParsed() {
    console.log("Testing validateParsed() method");
    var total = 0;
    var passed = 0;

    function _compare(actual, expected, message) {
        if (actual !== expected) {
            console.log(message + ": fail");
        } else {
            console.log(message + ": OK");
            ++passed;
        }
        ++total;
    }
    var list = [];
    // 1. Empty list
    _compare(validateParsed(list), false, "Empty list is invalid");

    var taskIdCounter = 0;
    var _composeTask = function(name, list_id) {
        taskIdCounter += 1;
        return {ID: taskIdCounter, Task: name, ListID: list_id, Status: '0',
                LastUpdate: '1000', CreationDate: '1001', DueDate: '1002', Duration: '5'};
    }

    // 2. A single task list with a single task
    list.push({ID: '1', ListName: 'primary', items: [ _composeTask('task1', '1')]});
    _compare(validateParsed(list), true, "Single task list with a single task");

    // 3. ID is missing in the second list
    list.push({ListName: 'secondary', items: []});
    _compare(validateParsed(list), false, "List ID is missing");
    list[1].ID = '2';

    // 4. Name and items are missing in the 3rd list
    list.push({ID: '3'});
    _compare(validateParsed(list), false, "ListName and items are missing");
    list[2].ListName = 'tertiary';

    // 5. Only 'items' field are missing now in the 3rd list
    _compare(validateParsed(list), false, "Items are missing");

    // 6. Add items to the 3rd list
    list[2].items = [_composeTask('task2', '3'), _composeTask('task3', '3')];
    _compare(validateParsed(list), true, "3 task lists with some tasks");

    // 7. ListID of task is wrong
    list[2].items.push(_composeTask('task4', '2'));
    _compare(validateParsed(list), false, "Wrong ListID of task");

    // 8. Status field of a task is missing
    list[2].items[2].ListID = '3';
    list[1].items.push(_composeTask('task5', '2'));
    list[1].items[0].Status = undefined;
    _compare(validateParsed(list), false, "Missing field of a task");

    // 9. Restore the field
    list[1].items[0].Status = '0';
    _compare(validateParsed(list), true, "List is corrected");

    // 10. Undef as argument
    _compare(validateParsed(), false, "List is undefined");

    console.log("Passed " + passed + " of " + total + " test(s)");
}

function importTasks(json) {
    //test_validateParsed(); return;
    var db = connectDB();

    try {
        var tasksGrouped = JSON.parse(json);
    } catch (error) {
        console.log("error in parse");
        return false;
    }
    if (!validateParsed(tasksGrouped)) {
        console.log("dump is invalid");
        return false;
    }

    clearTable("tasks");
    clearTable("lists");

    for (var i = 0; i < tasksGrouped.length; ++i) {
        var g = tasksGrouped[i];
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO lists (ID, ListName) VALUES (?, ?);", [g.ID, g.ListName]);
            tx.executeSql("COMMIT;");
        });
        for (var j = 0; j < g.items.length; ++j) {
            var it = g.items[j];
            db.transaction(function(tx) {
                tx.executeSql("INSERT INTO tasks (ID, Task, ListID, Status, LastUpdate, CreationDate, DueDate, Duration) " +
                              "VALUES (?, ?, ?, ?, ?, ?, ?, ?);",
                              [it.ID, it.Task, it.ListID, it.Status, it.LastUpdate, it.CreationDate, it.DueDate, it.Duration]);
                tx.executeSql("COMMIT;");
            });
        }
    }

    return true;
}

/***************************************/
/*** SQL functions for LIST handling ***/
/***************************************/

// push all lists to EditPage's list of lists
function allLists() {
    var db = connectDB();
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM lists");
        for (var i = 0; i < result.rows.length; ++i) {
            var item = result.rows.item(i);
            appendListToAll(item.ID, item.ListName);
        }
    });
}

// select lists and push them into the listList
function readLists(listArt, recentlyAddedTimestamp) {
    var db = connectDB();
    var ids = [];
    var midnight = getMidnight();
    var tomorrowMidnight = midnight + DAY_LENGTH;

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        var result = tx.executeSql("SELECT *, (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID) AS tCount,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND Status = '1') AS tCountPending,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND CreationDate > ?) AS tCountNew ,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND '0' < DueDate AND DueDate < ? AND Status = '1') AS tCountToday, \
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND ? <= DueDate AND DueDate < ? AND Status = '1') AS tCountTomorrow \
            FROM lists AS parent ORDER BY ID ASC;",
            [recentlyAddedTimestamp, midnight, midnight, tomorrowMidnight]);
        for(var i = 0; i < result.rows.length; i++) {
            var item = result.rows.item(i);
            if (listArt === "string") {
                ids.push(item.ID);
            } else {
                appendList(item.ID, item.ListName, item.tCount, item.tCountPending, item.tCountNew,
                           item.tCountToday, item.tCountTomorrow);
            }
        }
    });

    if (ids.length > 0)
        return ids.join(",");
}

// insert new list and return id
function writeList(listname) {
    var db = connectDB();
    var result;

    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO lists (ListName) VALUES (?);", [listname]);
            tx.executeSql("COMMIT;");
            result = tx.executeSql("SELECT ID FROM lists WHERE ListName=?;", [listname]);
        });

        return result.rows.item(0).ID;
    } catch (sqlErr) {
        return "ERROR";
    }
}

// delete list from database
function removeList(id) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM lists WHERE ID=?;", [id]);
        tx.executeSql("DELETE FROM tasks WHERE ListID=?;", [id]);
        tx.executeSql("COMMIT;");
    });
}

// update list
function updateList(id, listname) {
    var db = connectDB();
    var result;

    try {
        db.transaction(function(tx) {
            result = tx.executeSql("UPDATE lists SET ListName=? WHERE ID=?;", [listname, id]);
            tx.executeSql("COMMIT;");
        });

        return result.rows.count;
    } catch (sqlErr) {
       return "ERROR";
    }
}

// get list property from database
function getListProperty(id, listproperty) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT " + listproperty + " FROM lists WHERE ID=?;", [id]);
    });

    return eval("result.rows.item(0)." + listproperty);
}

/*******************************************/
/*** SQL functions for SETTINGS handling ***/
/*******************************************/

// insert new setting and return id
function writeSetting(settingname, settingvalue) {
    var db = connectDB();
    var result;

    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO settings (Setting, Value) VALUES (?, ?);", [settingname, settingvalue]);
            tx.executeSql("COMMIT;");
            result = tx.executeSql("SELECT Value FROM settings WHERE Setting=?;", [settingname]);
        });

        return result.rows.item(0).Value;
    } catch (sqlErr) {
        return "ERROR";
    }
}

// update setting
function updateSetting(settingname, settingvalue) {
    var db = connectDB();
    var result;

    try {
        db.transaction(function(tx) {
            tx.executeSql("UPDATE settings SET Value=? WHERE Setting=?;", [settingvalue, settingname]);
            tx.executeSql("COMMIT;");
            result = tx.executeSql("SELECT Value FROM settings WHERE Setting=?;", [settingname]);
        });

        return result.rows.item(0).Value;
    } catch (sqlErr) {
        return "ERROR";
    }
}


// get setting property from database
function getSetting(settingname) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT * FROM settings WHERE Setting=?;", [settingname]);
    });

    return result.rows.item(0).Value;
}

/***************************************/
/*** SQL functions for TAGS handling ***/
/***************************************/

function writeTag(tagName) {
    var db = connectDB();
    var ok = false;
    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO tags (Tag) VALUES (?)", tagName);
            tx.executeSql("COMMIT;");
            var result = tx.executeSql("SELECT ID FROM tags WHERE Tag=?", tagName);
            ok = result.rows.length === 1;
        });
    } catch (sqlErr) {
        console.log("Unable to insert a new tag");
    }
    return ok;
}

function removeTag(id) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM tags WHERE ID=?;", id);
        tx.executeSql("COMMIT;");
    });
}

function updateTag(id, name) {
    var db = connectDB();
    var ok = false;

    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE tags SET Tag = ? WHERE ID = ?;", [name, id]);
            tx.executeSql("COMMIT;");
            ok = result.rowsAffected === 1;
        });
    } catch (sqlErr) {
        console.log("Unable to change tag");
    }
    return ok;
}

// select tags, push them into the list and return amount
function allTags(callback) {
    var db = connectDB();
    var count = 0;
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tags ORDER BY Tag;");
        if (typeof(callback) !== "undefined") {
            for(var i = 0; i < result.rows.length; ++i) {
                var item = result.rows.item(i);
                callback(item.ID, item.Tag);
            }
        }
        count = result.rows.length;
    });
    return count;
}
