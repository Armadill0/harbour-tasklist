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
                tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('coverListSelection', '0')");
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
        var result = tx.executeSql("SELECT * FROM tasks WHERE ListID='" + listid + "'" + statusSql + " ORDER BY Status DESC" + orderby);
        for(var i = 0; i < result.rows.length; i++) {
            taskPage.appendTask(result.rows.item(i).ID, result.rows.item(i).Task, result.rows.item(i).Status == "1" ? true : false);
        }
    });
}

// select task and return count
function checkTask(listid, taskname) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        result = tx.executeSql("SELECT count(ID) as cID FROM tasks WHERE ListID='" + listid + "' AND Task='" + taskname + "'");
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
            tx.executeSql("INSERT INTO tasks (Task, ListID, Status, LastUpdate, CreationDate, DueDate, Duration) VALUES ('" + task + "', '" + listid + "', '" + status + "', '" + creationDate + "', '" + creationDate + "', '" + dueDate + "', '" + duration + "')");
            result = tx.executeSql("SELECT ID FROM tasks WHERE Task='" + task + "' AND ListID='" + listid + "'");
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
        tx.executeSql("DELETE FROM tasks WHERE ID='" + id + "' AND ListID='" + listid + "'");
    });
}

// update task
function updateTask(listid, newlistid, id, task, status, dueDate, duration) {
    var db = connectDB();
    var result;
    var lastUpdate = getUnixTime();

    try {
        db.transaction(function(tx) {
            result = tx.executeSql("UPDATE tasks SET ListID='" + newlistid + "', Task='" + task + "', Status='" + status + "', LastUpdate='" + lastUpdate + "', DueDate='" + dueDate + "', Duration='" + duration + "' WHERE ID='" + id + "' AND ListID='" + listid + "'");
        });

        return result.rows.count;
    } catch (sqlErr) {
       return "ERROR";
    }
}

// get task property from database
function getTaskProperty(listid, id, taskproperty) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT " + taskproperty + " FROM tasks WHERE ID='" + id + "' AND ListID='" + listid + "'");
    });

    return eval("result.rows.item(0)." + taskproperty);
}

/***************************************/
/*** SQL functions for LIST handling ***/
/***************************************/

// select lists and push them into the listList
function readLists(listArt) {
    var db = connectDB();
    var resultString = "";

    db.transaction(function(tx) {
        // order by sort to get the reactivated tasks to the end of the undone list
        var result = tx.executeSql("SELECT * FROM lists ORDER BY ID ASC");
        for(var i = 0; i < result.rows.length; i++) {
            if (listArt == "string") {
                resultString += (resultString == "" ? result.rows.item(i).ID : "," + result.rows.item(i).ID)
            }
            else {
                appendList(result.rows.item(i).ID, result.rows.item(i).ListName);
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
            tx.executeSql("INSERT INTO lists (ListName) VALUES ('" + listname + "')");
            result = tx.executeSql("SELECT ID FROM lists WHERE ListName='" + listname + "'");
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
        tx.executeSql("DELETE FROM lists WHERE ID='" + id + "'");
        tx.executeSql("DELETE FROM tasks WHERE ListID='" + id + "'");
    });
}

// update list
function updateList(id, listname) {
    var db = connectDB();
    var result;

    try {
        db.transaction(function(tx) {
            result = tx.executeSql("UPDATE lists SET ListName='" + listname + "' WHERE ID='" + id + "'");
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
        result = tx.executeSql("SELECT " + listproperty + " FROM lists WHERE ID='" + id + "'");
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
            tx.executeSql("INSERT INTO settings (Setting, Value) VALUES ('" + settingname + "', '" + settingvalue + "')");
            result = tx.executeSql("SELECT Value FROM settings WHERE Setting='" + settingname + "'");
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
            tx.executeSql("UPDATE settings SET Value='" + settingvalue + "' WHERE Setting='" + settingname + "'");
            result = tx.executeSql("SELECT Value FROM settings WHERE Setting='" + settingname + "'");
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
        result = tx.executeSql("SELECT * FROM settings WHERE Setting='" + settingname + "'");
    });

    return result.rows.item(0).Value;
}
