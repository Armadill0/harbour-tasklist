.import QtQuick.LocalStorage 2.0 as LS

var DAY_LENGTH = 24 * 3600 * 1000;

var PRIORITY_MIN = 1;
var PRIORITY_MAX = 5;
var PRIORITY_STEP = 1;
var PRIORITY_DEFAULT = 3;

function getUnixTime() {
    return (new Date()).getTime()
}

// return the next midnight in milliseconds since the epoch
function getMidnight() {
    var today = new Date();
    var start = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
    return start + DAY_LENGTH;
}

// return the start of the current day
function getDayStart() {
    var today = new Date();
    var start = Date.UTC(today.getFullYear(), today.getMonth(), today.getDate());
    return start;
}

// create DB with schema v2.0 from scratch
function createDB(tx) {
    console.log("creating DB v2.0 from scratch..");

    tx.executeSql("CREATE TABLE lists(ID INTEGER PRIMARY KEY AUTOINCREMENT, ListName TEXT UNIQUE);");

    tx.executeSql("CREATE TABLE tasks(ID INTEGER PRIMARY KEY AUTOINCREMENT, \
                        Task TEXT NOT NULL, ListID INTEGER NOT NULL, Status INTEGER, \
                        LastUpdate INTEGER NOT NULL, CreationDate INTEGER NOT NULL, \
                        DueDate INTEGER, Duration INTEGER, Priority INTEGER NOT NULL, Note TEXT, \
                        FOREIGN KEY(ListID) REFERENCES lists(ID), CONSTRAINT unq UNIQUE (Task, ListID));");

    tx.executeSql("CREATE TABLE tags(ID INTEGER PRIMARY KEY AUTOINCREMENT, Tag TEXT NOT NULL UNIQUE)");

    tx.executeSql("CREATE TABLE task_tags(TaskID INTEGER NOT NULL, TagID INTEGER NOT NULL,\
                    FOREIGN KEY(TaskID) REFERENCES tasks(ID), FOREIGN KEY(TagID) REFERENCES tags(ID), \
                    CONSTRAINT unq UNIQUE (TaskID, TagID));");

    tx.executeSql("CREATE TABLE IF NOT EXISTS settings(ID INTEGER PRIMARY KEY AUTOINCREMENT, Setting TEXT UNIQUE, Value TEXT);");

    tx.executeSql("CREATE UNIQUE INDEX uid ON tasks(ID, Task, ListID);");
}

// drop current database and recreate everything from scratch
function dropDB() {
    console.log("dropping all tables from DB...");

    var db = connectDB();
    db.transaction(function(tx) {
        tx.executeSql("DROP TABLE IF EXISTS lists");
        tx.executeSql("DROP TABLE IF EXISTS tasks");
        tx.executeSql("DROP TABLE IF EXISTS tags");
        tx.executeSql("DROP TABLE IF EXISTS task_tags");
        tx.executeSql("DROP TABLE IF EXISTS settings");
        tx.executeSql("COMMIT;");
    });

    db.transaction(function(tx) {
        createDB(tx);
    });

    return db;
}

function connectDB() {
    // connect to the local database: a version is not specified, so that it could be increased later
    return LS.LocalStorage.openDatabaseSync("TaskList", "", "TaskList Database", 100000);
}

// check if the DB schema has the latest version
function schemaIsUpToDate() {
    var db = connectDB();
    // create DB if it's the first run
    if (db.version === "") {
        db.changeVersion("", "2.0", createDB);
        // db.version is still empty, but the version is actually 2.0 now
        return true;
    }
    return db.version === "2.0";
}

// delete the existing DB and create from scratch
//  if @keepData is true, try to convert data
function replaceOldDB(keepData) {
    var db = connectDB();
    if (db.version === "1.0") {
        // save the existing data if necessary
        var data = keepData ? dumpData() : undefined;
        // drop 'tasks' and 'lists', but keep 'settings'
        db.transaction(function(tx) {
            tx.executeSql("DROP INDEX uid;")
            tx.executeSql("DROP TABLE tasks;");
            tx.executeSql("DROP TABLE lists;");
            tx.executeSql("COMMIT;");
        });
        // create brand new tables
        db.changeVersion("1.0", "2.0", createDB);
        // pour data in if necessary
        if (keepData && !importData(data))
            return false;
    }
    return true;
}

function initializeDB() {
    var db = connectDB();

    // run initialization queries
    db.transaction(
        function(tx) {
            // if lists are empty, create default list
            var result = tx.executeSql("SELECT count(ID) as cID FROM lists;");
            if (result.rows.item(0).cID === 0) {
                tx.executeSql("INSERT INTO lists (ListName) VALUES ('Tasks');");
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
                var res = tx.executeSql("SELECT count(Setting) as cSetting FROM settings WHERE Setting = ?;", settingKey);
                if (res.rows.item(0).cSetting === 0) {
                    var defaultValue = defaultSettings[settingKey];
                    tx.executeSql("INSERT INTO settings (Setting, Value) VALUES (?, ?);", [settingKey, defaultValue]);
                }
            }
            // check that 'defaultList' is a valid ID
            var defaultListId = getSettingAsNumber("defaultList");
            result = tx.executeSql("SELECT ID FROM lists WHERE ID = ?;", defaultListId);
            if (result.rows.length !== 1) {
                result = tx.executeSql("SELECT ID FROM lists ORDER BY ID;");
                // set 'defaultList' to the least existing ID
                tx.executeSql("UPDATE settings SET Value = ? WHERE Setting = ?;", [result.rows.item(0).ID, "defaultList"]);
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
        callback(task.ID, task.Task, task.Status === 1, task.ListID,
                 task.DueDate, task.Priority || PRIORITY_DEFAULT, task.Note);
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

function getSimpleList(listID) {
    var db = connectDB();
    var names = [];
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tasks WHERE ListID = ? AND Status = '1' ORDER BY Task ASC;", listID);
        for (var i = 0; i < result.rows.length; ++i) {
            names.push(result.rows.item(i).Task);
        }
    });
    return names.join("\n")
}

// select tasks on a global basis instead of list basis
function readSmartListTasks(smartListType, callback) {
    var db = connectDB();
    var recentlyAddedOffsetTime = getUnixTime() - taskListWindow.recentlyAddedPeriods[taskListWindow.recentlyAddedOffset] * 1000;
    var midnight = getMidnight();
    var tomorrowMidnight = midnight + DAY_LENGTH;
    var dayStart = getDayStart();
    var condition = "";

    if (smartListType === 0)
        condition = "Status = '0'";
    else if (smartListType === 1)
        condition = "Status = '1'";
    else if (smartListType === 2)
        condition = "CreationDate > '" + recentlyAddedOffsetTime + "'";
    else if (smartListType === 3)
        condition = "'" + dayStart + "' <= DueDate AND DueDate < '" + midnight + "' AND Status= '1'";
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

// select task and return id
function getTaskId(listID, taskname) {
    var db = connectDB();
    var result;

    db.transaction(function(tx) {
        result = tx.executeSql("SELECT ID FROM tasks WHERE ListID=? AND Task=?;", [listID, taskname]);
    });

    return result.rows.item(0).ID;
}

// insert new task and return id or -1 if error
function writeTask(listID, task, status, dueDate, duration, priority, note) {
    var db = connectDB();
    var creationDate = getUnixTime();
    var taskID = -1;

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

// dump data from DB
function dumpData() {
    var db = connectDB();
    var version = Number(db.version);
    var lists = [];
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * from lists;");
        for (var i = 0; i < result.rows.length; ++i) {
            var item = result.rows.item(i);
            lists.push({ID: item.ID, ListName: item.ListName});
        }
    });

    var tasksGrouped = [];
    db.transaction(function(tx) {
        for (var i in lists) {
            var ListID = lists[i].ID;
            var items = [];
            var result = tx.executeSql("SELECT * FROM tasks WHERE ListID = ?;", ListID);
            for (var j = 0; j < result.rows.length; ++j) {
                var item = packTask(result.rows.item(j));
                // add tags to task if tags are introduced already
                if (db.version > 1.0) {
                    var tagsResult = tx.executeSql("SELECT TagID FROM task_tags WHERE TaskID = ?;", item.ID);
                    var tagIds = [];
                    for (var k = 0; k < tagsResult.rows.length; ++k)
                        tagIds.push(tagsResult.rows.item(k).TagID);
                    item["Tags"] = tagIds;
                }
                items.push(item);
            }
            tasksGrouped.push({ID: ListID, ListName: lists[i].ListName, items: items});
        }
    });
    // that's it for v1.0
    if (version === 1)
        return JSON.stringify(tasksGrouped);
    // v2.0 also contains tags
    var tags = [];
    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT * FROM tags;");
        for (var i = 0; i < result.rows.length; ++i) {
            var item = result.rows.item(i);
            tags.push({ID: item.ID, Tag: item.Tag});
        }
    });
    var data = {
        schema: "2.0",
        tasklists: tasksGrouped,
        tags: tags
    };
    return JSON.stringify(data);
}

function clearTable(table) {
    var db = connectDB();

    db.transaction(function(tx) {
        tx.executeSql("DELETE FROM " + table);
        tx.executeSql("COMMIT;");
    });
}

function validateParsed(tasksGrouped, version) {

    var _check = function(field) {
        return typeof field !== 'undefined';
    }

    if (!_check(tasksGrouped)) return false;

    for (var i in tasksGrouped) {
        var g = tasksGrouped[i];
        if (!_check(g.ListName)) return false;
        if (!_check(g.ID)) return false;
        var items = g.items;
        if (!_check(items)) return false;
        for (var j in items) {
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
            if (version > 1) {
                if (!_check(it.Priority)) return false;
                if (!_check(it.Note)) return false;
                if (!_check(it.Tags)) return false;
            }
        }
    }
    return true;
}

function importData(json) {
    var db = connectDB();
    var parsed;
    try {
        parsed = JSON.parse(json);
    } catch (error) {
        console.log("error in parse");
        return false;
    }
    var version = (parsed instanceof Array) ? 1 : 2;

    var tasksGrouped, tags;
    if (version === 1) {
        tasksGrouped = parsed;
        tags = [];
    } else {
        if (parsed.schema !== "2.0") {
            console.log("dump for v2.0: invalid schema");
            return false;
        }
        tasksGrouped = parsed.tasklists;
        tags = parsed.tags;
        if (!(tags instanceof Array)) {
            console.log("invalid tags");
            return false;
        }
    }
    if (!validateParsed(tasksGrouped, version)) {
        console.log("dump is invalid");
        return false;
    }

    clearTable("tags");
    clearTable("task_tags");
    clearTable("tasks");
    clearTable("lists");

    // memorize tags to check tasks' associations with tags later
    var existingTags = {};
    // add tags at first, because tasks depend on them
    db.transaction(function(tx) {
        for (var i in tags) {
            existingTags[tags[i].ID] = 1;
            tx.executeSql("INSERT INTO tags (ID, Tag) VALUES (?, ?);", [tags[i].ID, tags[i].Tag]);
        }
        tx.executeSql("COMMIT;");
    });

    db.transaction(function(tx) {
        for (var i in tasksGrouped) {
            var g = tasksGrouped[i];
            tx.executeSql("INSERT INTO lists (ID, ListName) VALUES (?, ?);", [g.ID, g.ListName]);
            for (var j in g.items) {
                var it = g.items[j];
                tx.executeSql("INSERT INTO tasks (ID, Task, ListID, Status, LastUpdate, CreationDate, \
                               DueDate, Duration, Priority, Note) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?);",
                               [it.ID, it.Task, it.ListID, it.Status, it.LastUpdate, it.CreationDate,
                                it.DueDate || 0, it.Duration || 0, it.Priority || PRIORITY_DEFAULT, it.Note || ""]);
                var tagIds = it.Tags;
                if (typeof (tagIds) !== "undefined")
                    for (var k in tagIds) {
                        // add associations only to existing tags
                        if (existingTags[tagIds[k]] === 1)
                            tx.executeSql("INSERT INTO task_tags (TaskID, TagID) VALUES (?, ?);",
                                          [it.ID, tagIds[k]]);
                    }
            }
        }
        tx.executeSql("COMMIT;");
    });
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
    var dayStart = getDayStart();
    var tomorrowMidnight = midnight + DAY_LENGTH;

    db.transaction(function(tx) {
        var result = tx.executeSql("SELECT *, (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID) AS total,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND Status = '1') AS pending,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND CreationDate > ?) AS recent ,\
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND ? < DueDate AND DueDate < ? AND Status = '1') AS today, \
            (SELECT COUNT(ID) FROM tasks WHERE ListID = parent.ID AND ? <= DueDate AND DueDate < ? AND Status = '1') AS tomorrow \
            FROM lists AS parent ORDER BY ID ASC;",
            [recently, dayStart, midnight, midnight, tomorrowMidnight]);
        for(var i = 0; i < result.rows.length; i++) {
            var item = result.rows.item(i);
            callback(item.ID, item.ListName, item.total, item.pending, item.recent, item.today, item.tomorrow);
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

/* UPSERT as in http://stackoverflow.com/a/15277374 */
function upsertSetting(setting, value) {
    var db = connectDB();
    var ok = false;
    try {
        db.transaction(function(tx) {
            tx.executeSql("INSERT OR IGNORE INTO settings (Setting, Value) VALUES (?, ?);", [setting, value]);
            ok = true;
        });
    } catch (sqlErr) {
        console.log("Unable to insert or ignore setting " + setting);
    }
    if (ok)
        ok = updateSetting(setting, value);
    return ok;
}

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

function getSetting(setting) {
    var db = connectDB();
    var value = undefined;
    try {
        db.transaction(function(tx) {
            var result = tx.executeSql("SELECT * FROM settings WHERE Setting = ?;", setting);
            if (result.rows.length === 1)
                value = result.rows.item(0).Value;
        });
    } catch (sqlErr) {
        console.log("Unable to get setting " + setting);
    }
    return value;
}

function getSettingAsNumber(setting) {
    var value = getSetting(setting);
    if (typeof value !== "undefined")
        value = Number(value);
    return value;
}

var DROPBOX_FIELDS = {
    dropboxUsername: "dropboxUsername",
    dropboxTokenSecret: "dropboxTokenSecret",
    dropboxToken: "dropboxToken"
};

function upsertDropboxCredentials(values) {
    for (var i in DROPBOX_FIELDS)
        if (!upsertSetting(DROPBOX_FIELDS[i], values[i]))
            return false;
    return true;
}

function getDropboxCredentials() {
    var values = {};
    for (var i in DROPBOX_FIELDS)
        values[i] = getSetting(DROPBOX_FIELDS[i]);
    return values;
}

function removeDropboxCredentials() {
    var db = connectDB();
    db.transaction(function(tx) {
        for (var i in DROPBOX_FIELDS)
            tx.executeSql("DELETE FROM settings WHERE Setting = ?;", DROPBOX_FIELDS[i]);
        tx.executeSql("COMMIT;");
    });
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
