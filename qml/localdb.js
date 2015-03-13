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
    console.log("creating DB v2.0 from scratch..");

    tx.executeSql("CREATE TABLE lists(ID INTEGER PRIMARY KEY AUTOINCREMENT, ListName TEXT UNIQUE)");

    tx.executeSql("CREATE TABLE tasks(ID INTEGER PRIMARY KEY AUTOINCREMENT, \
                        Task TEXT NOT NULL, ListID INTEGER NOT NULL, Status INTEGER, \
                        LastUpdate INTEGER NOT NULL, CreationDate INTEGER NOT NULL, \
                        DueDate INTEGER, Duration INTEGER, Priority INTEGER NOT NULL, Note TEXT, \
                        FOREIGN KEY(ListID) REFERENCES lists(ID), CONSTRAINT unq UNIQUE (Task, ListID))");

    tx.executeSql("CREATE TABLE tags(ID INTEGER PRIMARY KEY AUTOINCREMENT, Tag TEXT NOT NULL UNIQUE)");

    tx.executeSql("CREATE TABLE task_tags(TaskID INTEGER NOT NULL, TagID INTEGER NOT NULL,\
                    FOREIGN KEY(TaskID) REFERENCES tasks(ID), FOREIGN KEY(TagID) REFERENCES tags(ID), \
                    CONSTRAINT unq UNIQUE (TaskID, TagID))");

    tx.executeSql("CREATE TABLE settings(ID INTEGER PRIMARY KEY AUTOINCREMENT, Setting TEXT UNIQUE, Value TEXT)");

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
            if (result.rows.item(0).cID === 0) {
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
                var res = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting = ?", settingKey);
                if (res.rows.item(0).cSetting === 0) {
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

function applyCallbackToTasks(callback, result) {
    for (var i = 0; i < result.rows.length; ++i) {
        var task = result.rows.item(i);
        callback(task.ID, task.Task, task.Status === 1, task.ListID, task.DueDate, task.Priority);
    }
}

// select tasks and push them into the tasklist
function readTasks(listID, callback, status, sort) {
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
        applyCallbackToTasks(callback, result);
    });
}

// select tasks on a global basis instead of list basis
function readSmartListTasks(smartListType, callback) {
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
        applyCallbackToTasks(callback, result);
    });
}

function readTasksWithTag(tagId, callback) {
    var db = connectDB();
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tasks INNER JOIN task_tags ON tasks.ID = task_tags.TaskID \
                                    WHERE task_tags.TagID = ? ORDER BY Status DESC, Priority DESC", tagId);
        applyCallbackToTasks(callback, result);
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
            var result = tx.executeSql("SELECT ID FROM tasks WHERE Task = ? AND ListID = ?;", [task, listID]);
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
        tx.executeSql("DELETE FROM tasks WHERE ID = ?;", id);
        tx.executeSql("DELETE FROM task_tags WHERE TaskID = ?;", id);
        tx.executeSql("COMMIT;");
    });
}

// change a task status
function setTaskStatus(id, status) {
    var db = connectDB();
    var lastUpdate = getUnixTime();
    var ok = false;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE tasks SET Status = ?, LastUpdate = ? WHERE ID = ?", [status, lastUpdate, id]);
            tx.executeSql("COMMIT;");
            ok = result.rowsAffected === 1;
        });
    } catch (sqlErr) {
        console.log("Unable to change a task status in DB");
    }
    return ok;
}

// update task
function updateTask(id, newListID, task, status, dueDate, duration, priority, note) {
    var db = connectDB();
    var lastUpdate = getUnixTime();
    var ok = false;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE tasks SET ListID = ?, Task = ?, Status = ?, \
                                        LastUpdate = ?, DueDate = ?, Duration = ?, Priority = ?, Note = ? WHERE ID = ?;",
                                        [newListID, task, status, lastUpdate, dueDate, duration, priority, note, id]);
            tx.executeSql("COMMIT;");
            ok = result.rowsAffected === 1;
        });

    } catch (sqlErr) {
        console.log("Unable to update task in DB");
    }
    return ok;
}

function packTask(record) {
    return {ID: record.ID, Task: record.Task, ListID: record.ListID, Status: record.Status,
            LastUpdate: record.LastUpdate, CreationDate: record.CreationDate,
            DueDate: record.DueDate, Duration: record.Duration,
            Priority: record.Priority, Note: record.Note};
}

function getTaskDetails(id) {
    var db = connectDB();
    var details = {};
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tasks WHERE ID = ?;", id);
        if (result.rows.length === 1)
            details = packTask(result.rows.item(0));
    });
    return details;
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

// select all lists
function allLists(callback) {
    var db = connectDB();
    var ids = [];
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM lists");
        for (var i = 0; i < result.rows.length; ++i) {
            var item = result.rows.item(i);
            ids.push(item.ID);
            if (typeof(callback) !== "undefined")
                callback(item.ID, item.ListName);
        }
    });
    return ids;
}

// select all lists and collect some statistics
function readLists(recently, callback) {
    var db = connectDB();
    var midnight = getMidnight();
    var tomorrowMidnight = midnight + DAY_LENGTH;

    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT *, (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID) AS total,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND Status = '1') AS pending,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND CreationDate > ?) AS recent ,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND '0' < DueDate AND DueDate < ? AND Status = '1') AS today, \
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND ? <= DueDate AND DueDate < ? AND Status = '1') AS tomorrow \
            FROM lists AS parent ORDER BY ID ASC;",
            [recently, midnight, midnight, tomorrowMidnight]);
        for(var i = 0; i < result.rows.length; i++) {
            var item = result.rows.item(i);
            callback({ listid: item.ID, listname: item.ListName, total: item.total,
                       pending: item.pending, recent: item.recent,
                       today: item.today, tomorrow: item.tomorrow });
        }
    });
}

// insert new list and return id
function writeList(name) {
    var db = connectDB();
    var id = -1;
    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO lists (ListName) VALUES (?);", name);
            tx.executeSql("COMMIT;");
            var result = tx.executeSql("SELECT ID FROM lists WHERE ListName = ?;", name);
            if (result.rows.length === 1)
                id = result.rows.item(0).ID;
        });
    } catch (sqlErr) {
        console.log("Unable to create new list in DB");
    }
    return id;
}

// remove a list together with its tasks and their associations with tags
function removeList(id) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM lists WHERE ID = ?;", id);
        tx.executeSql("COMMIT;");
        // remove also dependent tasks
        var result = tx.executeSql("SELECT ID FROM tasks WHERE ListID = ?", id);
        for (var i = 0; i < result.rows.length; ++i)
            removeTask(result.rows.item(i).ID);
    });
}

function updateList(id, newName) {
    var db = connectDB();
    var ok = false;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE lists SET ListName = ? WHERE ID = ?;", [newName, id]);
            tx.executeSql("COMMIT;");
            ok = result.rowsAffected === 1;
        });
    } catch (sqlErr) {
        console.log("Unable to update list name");
    }
    return ok;
}

function getListName(id) {
    var db = connectDB();
    var name = "";
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT ListName FROM lists WHERE ID = ?;", id);
        if (result.rows.length === 1)
            name = result.rows.item(0).ListName;
    });
    return name;
}

/*******************************************/
/*** SQL functions for SETTINGS handling ***/
/*******************************************/

function updateSetting(setting, value) {
    var db = connectDB();
    var ok = false;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("UPDATE settings SET Value = ? WHERE Setting = ?;", [value, setting]);
            tx.executeSql("COMMIT;");
            ok = result.rowsAffected === 1;
        });
    } catch (sqlErr) {
        console.log("Unable to update setting " + setting);
    }
    return ok;
}

function getSettingAsNumber(setting) {
    var db = connectDB();
    var value;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("SELECT * FROM settings WHERE Setting = ?;", setting);
            if (result.rows.length === 1)
                value = Number(result.rows.item(0).Value);
        });
    } catch (sqlErr) {
        console.log("Unable to get setting " + setting);
    }
    return value;
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

// remove tag with its associations
function removeTag(id) {
    var db = connectDB();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM tags WHERE ID = ?;", id);
        tx.executeSql("DELETE FROM task_tags WHERE TagID = ?;", id);
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
        // TagDialog expects the tags being ordered by Tag lexicographically
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

// select tags of the task and return as a sorted list
function readTaskTags(taskId) {
    var db  = connectDB();
    var tags = [];
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT tags.Tag AS TagName \
                                    FROM task_tags INNER JOIN tags ON task_tags.TagID=tags.ID \
                                    WHERE task_tags.TaskID = ? ORDER BY tags.Tag", taskId);
        for (var i = 0; i < result.rows.length; ++i)
            tags.push(result.rows.item(i).TagName);
    });
    return tags;
}

function getTagName(tagId) {
    var db = connectDB();
    var tagName = "";
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT Tag FROM tags WHERE ID = ?", tagId);
        if (result.rows.length !== 1)
            console.log("Unable to find tag with id " + tagId);
        else
            tagName = result.rows.item(0).Tag;
    });
    return tagName;
}

function getTagId(tagName) {
    var db = connectDB();
    var tagId = -1;
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT ID FROM tags WHERE Tag = ?", tagName);
        if (result.rows.length !== 1)
            console.log("Unable to find tag with name: " + tagName);
        else
            tagId = result.rows.item(0).ID;
    });
    return tagId;
}

// add an association
function addTaskTag(taskId, tagName) {
    var tagId = getTagId(tagName);
    if (tagId < 0)
        return;
    var db = connectDB();
    db.transaction(function(tx) {
        tx.executeSql("INSERT INTO task_tags (TaskID, TagID) VALUES (?, ?)", [taskId, tagId]);
    });
}

// remove an association
function removeTaskTag(taskId, tagName) {
    var tagId = getTagId(tagName);
    if (tagId < 0)
        return;
    var db = connectDB();
    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM task_tags WHERE TaskID = ? AND TagID = ?", [taskId, tagId]);
    });
}

// compare the current and the new tags and modify table
// @newTags - a sorted list of the new tags
function updateTaskTags(taskId, newTags) {
    var current = readTaskTags(taskId);
    var i = 0, j = 0;
    var n = newTags.length, m = current.length;
    while (i < n && j < m) {
        if (newTags[i] < current[j]) {
            addTaskTag(taskId, newTags[i]);
            i += 1;
        } else if (newTags[i] > current[j]) {
            removeTaskTag(taskId, current[j]);
            j += 1;
        } else {
            // equal tags
            i += 1;
            j += 1;
        }
    }
    while (i < n) {
        addTaskTag(taskId, newTags[i]);
        i += 1;
    }
    while (j < m) {
        removeTaskTag(taskId, current[j]);
        j += 1;
    }
}
