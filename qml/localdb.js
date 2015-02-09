.import QtQuick.LocalStorage 2.0 as LS

function getUnixTime() {
    return (new Date()).getTime()
}

function connectDB() {
    // connect to the local database
    return LS.LocalStorage.openDatabaseSync("TaskList", "1.0", "TaskList Database", 100000);
}

function initializeDB() {
    // initialize DB connection
    var db = connectDB();

    // run initialization queries
    db.transaction(
        function(tx) {
            // delete db for clean setup
            //tx.executeSql("DROP TABLE tasks");
            //tx.executeSql("DROP TABLE lists");
            //tx.executeSql("DROP TABLE settings");
            // create the task and list tables
            tx.executeSql("CREATE TABLE IF NOT EXISTS tasks(ID INTEGER PRIMARY KEY AUTOINCREMENT, Task TEXT, ListID INTEGER, Status INTEGER, LastUpdate INTEGER, CreationDate INTEGER, DueDate INTEGER, Duration INTEGER, CONSTRAINT unq UNIQUE (Task, ListID))");
            tx.executeSql("CREATE TABLE IF NOT EXISTS lists(ID INTEGER PRIMARY KEY AUTOINCREMENT, ListName TEXT UNIQUE)");
            tx.executeSql("CREATE TABLE IF NOT EXISTS settings(ID INTEGER PRIMARY KEY AUTOINCREMENT, Setting TEXT UNIQUE, Value TEXT)");
            tx.executeSql("CREATE UNIQUE INDEX IF NOT EXISTS uid ON tasks(ID, Task, ListID)");

            // if lists are empty, create default list
            var result = tx.executeSql("SELECT count(ID) as cID FROM lists");
            if (result.rows.item(0)["cID"] == 0) {
                tx.executeSql("INSERT INTO lists (ListName) VALUES ('Tasks')");
            }

            /****************************/
            /*** ADD DEFAULT SETTINGS ***/
            /****************************/
            // if no default list is set, set to 1
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='defaultList'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('defaultList', '1')");
            }
            // coverListSelection
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='coverListSelection'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('coverListSelection', '1')");
            }
            // coverListChoose
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='coverListChoose'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('coverListChoose', '1')");
            }
            // coverListOrder
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='coverListOrder'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('coverListOrder', '0')");
            }
            // taskOpenAppearance
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='taskOpenAppearance'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('taskOpenAppearance', '1')");
            }
            // dateFormat
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='dateFormat'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('dateFormat', '0')");
            }
            // timeFormat
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='timeFormat'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('timeFormat', '0')");
            }
            // remorseOnDelete
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='remorseOnDelete'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('remorseOnDelete', '5')");
            }
            // remorseOnMark
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='remorseOnMark'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('remorseOnMark', '2')");
            }
            // remorseOnMultiAdd
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='remorseOnMultiAdd'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('remorseOnMultiAdd', '5')");
            }
            // startPage
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='startPage'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('startPage', '0')");
            }
            // backFocusAddTask
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='backFocusAddTask'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('backFocusAddTask', '1')");
            }
            // smartListVisibility
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='smartListVisibility'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('smartListVisibility', '1')");
            }
            // recentlyAddedOffset
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='recentlyAddedOffset'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('recentlyAddedOffset', '3')");
            }
            // doneTasksStrikedThrough
            var result = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting='doneTasksStrikedThrough'");
            if (result.rows.item(0)["cSetting"] == 0) {
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('doneTasksStrikedThrough', '0')");
            }
        }
    );

    return db;
}

/***************************************/
/*** SQL functions for TASK handling ***/
/***************************************/

// select tasks and push them into the tasklist
function readTasks(listid, status, sort) {
    var db = connectDB();
    var statusSql;
    var orderby;

    if (status != "") {
        statusSql = " AND Status='" + status + "'"
    }
    else {
        statusSql = ""
    }

    if (sort != "") {
        orderby = sort;
    }
    else {
        orderby = ", LastUpdate DESC";
    }

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        var result = tx.executeSql("SELECT * FROM tasks WHERE ListID=?" + statusSql + " ORDER BY Status DESC" + orderby + ";", [listid]);
        for(var i = 0; i < result.rows.length; i++) {
            taskPage.appendTask(result.rows.item(i).ID, result.rows.item(i).Task, result.rows.item(i).Status == "1" ? true : false, result.rows.item(i).ListID);
        }
    });
}

// select tasks on a global basis instead of list basis
function readSmartListTasks(smartListType) {
    var db = connectDB();
    var query;
    //join lists table to hide tasks from deleted lists (however they should not exist)
    var joinquery = "JOIN lists ON lists.ID=tasks.ListID";
    var rowstoselect = "tasks.ID AS taskID,*";
    var recentlyAddedOffsetTime = getUnixTime() - taskListWindow.recentlyAddedPeriods[taskListWindow.recentlyAddedOffset] * 1000;

    switch(smartListType ) {
    case 0:
        query = "SELECT " + rowstoselect + " FROM tasks " + joinquery + " WHERE Status='0';";
        break;
    case 1:
        query = "SELECT " + rowstoselect + " FROM tasks " + joinquery + " WHERE Status='1';";
        break;
    case 2:
        query = "SELECT " + rowstoselect + " FROM tasks " + joinquery + " WHERE CreationDate>'" + recentlyAddedOffsetTime + "';";
        break;
    }

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        var result = tx.executeSql(query);
        for(var i = 0; i < result.rows.length; i++) {
            taskPage.appendTask(result.rows.item(i).taskID, result.rows.item(i).Task, result.rows.item(i).Status == "1" ? true : false, result.rows.item(i).ListID);
        }
    });
}

// select task and return count
function checkTask(listid, taskname) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        result = tx.executeSql("SELECT count(ID) as cID FROM tasks WHERE ListID=? AND Task=?;", [listid, taskname]);
    });

    return result.rows.item(0).cID;
}

// insert new task and return id
function writeTask(listid, task, status, dueDate, duration) {
    var db = connectDB();
    var result;
    var creationDate = getUnixTime();

    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT INTO tasks (Task, ListID, Status, LastUpdate, CreationDate, DueDate, Duration) VALUES (?, ?, ?, ?, ?, ?, ?);", [task, listid, status, creationDate, creationDate, dueDate, duration]);
            tx.executeSql("COMMIT;");
            result = tx.executeSql("SELECT ID FROM tasks WHERE Task=? AND ListID=?;", [task, listid]);
        });

        return result.rows.item(0).ID;
    } catch (sqlErr) {
        return "ERROR";
    }
}

// delete task from database
function removeTask(listid, id) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM tasks WHERE ID=? AND ListID=?;", [id, listid]);
        tx.executeSql("COMMIT;");
    });
}

// update task
function updateTask(listid, newlistid, id, task, status, dueDate, duration) {
    var db = connectDB();
    var result;
    var lastUpdate = getUnixTime();

    try {
        db.transaction(function(tx) {
            result = tx.executeSql("UPDATE tasks SET ListID=?, Task=?, Status=?, LastUpdate=?, DueDate=?, Duration=? WHERE ID=? AND ListID=?;", [newlistid, task, status, lastUpdate, dueDate, duration, id, listid]);
            tx.executeSql("COMMIT;");
        });

        return result.rows.count;
    } catch (sqlErr) {
       return "ERROR";
    }
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

// dump tasks from all lists
function dumpTasks() {
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
            var result = tx.executeSql("SELECT * from tasks WHERE ListID=" + ListID);
            for (var j = 0; j < result.rows.length; ++j) {
                var item = result.rows.item(j);
                items.push({ID: item.ID, Task: item.Task, ListID: item.ListID, Status: item.Status,
                            LastUpdate: item.LastUpdate, CreationDate: item.CreationDate,
                            DueDate: item.DueDate, Duration: item.Duration});
            }
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

// select lists and push them into the listList
function readLists(listArt, recentlyAddedTimestamp) {
    var db = connectDB();
    var resultString = "";

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        var result = tx.executeSql("SELECT *, (SELECT COUNT(ID) FROM tasks WHERE ListID=parent.ID) AS tCount,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID=parent.ID AND Status='1') AS tCountPending,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID=parent.ID AND CreationDate>'" + recentlyAddedTimestamp + "') AS tCountNew FROM lists AS parent ORDER BY ID ASC;");
        for(var i = 0; i < result.rows.length; i++) {
            if (listArt == "string") {
                resultString += (resultString == "" ? result.rows.item(i).ID : "," + result.rows.item(i).ID)
            }
            else {
                appendList(result.rows.item(i).ID, result.rows.item(i).ListName, result.rows.item(i).tCount, result.rows.item(i).tCountPending, result.rows.item(i).tCountNew);
            }
        }
    });

    if (resultString != "")
        return resultString;
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
