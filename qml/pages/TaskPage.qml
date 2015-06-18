/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2014 Thomas Amler
    Contact: Thomas Amler <armadillo@penguinfriends.org>

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
*/

import QtQuick 2.1
import Sailfish.Silica 1.0
import "../localdb.js" as DB
import "."

Page {
    id: taskPage
    allowedOrientations: Orientation.All

    property bool coverAddTask
    property int listId: taskListWindow.listid
    property string listname
    property int smartListType: taskListWindow.smartListType
    property bool doneTasksAvailable

    // human-readable representation of a due date
    function humanDueDate(unixTime) {
        if (typeof(unixTime) !== "number" || unixTime <= 0)
            return ""
        var date = new Date(unixTime)
        var today = new Date()
        var tomorrow = new Date(today.getTime() + DB.DAY_LENGTH)
        var yesterday = new Date(today.getTime() - DB.DAY_LENGTH)
        var dateString = date.toDateString()
        if (dateString === today.toDateString())
            //: due date string for today
            return qsTr("Today")
        if (dateString === tomorrow.toDateString())
            //: due date string for tomorrow
            return qsTr("Tomorrow")
        if (dateString === yesterday.toDateString())
            //: due date string for yesterday
            return qsTr("Yesterday")
        var result = date.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
        return result
    }

    function composeTaskLabel(task) {
        if (typeof(task) === "undefined")
            return ""
        var tokens = []
        var result = []

        if (taskListWindow.smartListType >= 0)
            //: title for the list property in the task description (keep as short as possible)
            result.push(qsTr("List") + ": " + task.listname)

        if (typeof(task.dueDate) === "number" && task.dueDate > 0)
            //: title for the due date in the task description (keep as short as possible)
            result.push(qsTr("Due") + ": " + humanDueDate(task.dueDate))

        var tags = DB.readTaskTags(task.taskid)
        for (var i in tags) {
            var next = tags[i]
            tokens.push(next)
        }
        if (tokens.length > 0)
            //: title for the tags in the task description (keep as short as possible)
            result.push(qsTr("Tags") + ": " + tokens.join(", "))

        if (typeof(task.notes) !== "undefined" && task.notes !== "")
            //: title for the notes in the task description (keep as short as possible)
            result.push(qsTr("Notes") + ": " + task.notes)

        return result.join(" - ")
    }

    // helper function to add tasks to the list
    // @status - boolean
    // @dueDate - number, in milliseconds
    function appendTask(id, task, status, listid, dueDate, priority, notes) {
        taskListModel.append({ taskid: id, task: task, taskstatus: status,
                                 listid: listid, listname: DB.getListName(listid),
                                 dueDate: dueDate, priority: priority || taskListWindow.defaultPriority,
                                 notes: notes })
    }

    function insertNewTask(index, id, task, listid) {
        taskListModel.insert(index, { taskid: id, task: task, taskstatus: true,
                                 listid: listid, listname: DB.getListName(listid),
                                 dueDate: 0, priority: taskListWindow.defaultPriority,
                                 notes: "" })
    }

    // helper function to wipe the tasklist element
    function wipeTaskList() {
        taskListModel.clear()
    }

    function reloadTaskList() {
        wipeTaskList()
        if (taskListWindow.smartListType === 5) {
            var tagId = taskListWindow.tagId
            //: # prefix for the listname because it is used to list the tasks which are tagged by %1, which is the tag name
            listname = qsTr("#%1").arg(DB.getTagName(tagId))
            DB.readTasksWithTag(tagId, appendTask)
        } else if (taskListWindow.smartListType !== -1) {
            listname = taskListWindow.smartListNames[taskListWindow.smartListType]
            DB.readSmartListTasks(taskListWindow.smartListType, appendTask)
        } else {
            listname = DB.getListName(listid)
            DB.readTasks(listid, appendTask)
        }

        // disable pulldown menus if no done tasks available
        updateOptions()
    }

    // function to change the availability of the pull down menu items
    function updateOptions () {
        var doneTaskCheck = false;
        for (var i = 0; i < taskListModel.count; i++) {
            if (taskListModel.get(i).taskstatus === !taskListWindow.taskOpenAppearance)
                doneTaskCheck = true
        }

        // final decision to enable or diable the menu item
        doneTasksAvailable = doneTaskCheck
    }

    // function to delete all done tasks
    function deleteDoneTasks() {
        //: remorse action to delete all done tasks
        tasklistRemorse.execute(qsTr("Deleting all done tasks"),function(){
            // start deleting from the end of the list to not get a problem with already deleted items
            for(var i = taskListModel.count - 1; i >= 0; i--) {
                if (taskListModel.get(i).taskstatus === false) {
                    DB.removeTask(taskListModel.get(i).taskid)
                    taskListModel.remove(i)
                }
                // stop if last open task has been reached to save battery power
                else if (taskListModel.get(i).taskstatus === true) {
                    break
                }
            }
        } , taskListWindow.remorseOnDelete * 1000)
    }

    // function to reset all done tasks
    function resetDoneTasks() {
        //: remorse action to reset all done tasks
        tasklistRemorse.execute(qsTr("Reseting all done tasks"),function(){
            // start reseting from the end of the list to not get a problem with already deleted items
            for(var i = taskListModel.count - 1; i >= 0; i--) {
                if (taskListModel.get(i).taskstatus === false) {
                    DB.setTaskStatus(taskListModel.get(i).taskid, 1)
                }
                // stop if last open task has been reached to save battery power
                else if (taskListModel.get(i).taskstatus === true) {
                    break
                }
            }

            reloadTaskList()
        } , taskListWindow.remorseOnDelete * 1000)
    }

    // workaround timer to push application to background after start
    Timer {
        id: startPageTimer
        interval: 500
        running: false
        repeat: false
        onTriggered: taskListWindow.deactivate()
    }

    // workaround timer to force focus back to textfield after adding new task
    Timer {
        id: timerAddTask
        interval: 100
        running: false
        repeat: false
        onTriggered: taskList.headerItem.children[1].forceActiveFocus()
    }

    // reload list if any change to the global listId property has been occured
    // this reacts currently on all list changes, whether from cover or list page
    // and replaces some former bad hacks and workarounds
    onListIdChanged: {
        reloadTaskList()
    }
    onSmartListTypeChanged: {
        reloadTaskList()
    }

    onStatusChanged: {
        switch(status) {
        case PageStatus.Activating:
            taskListWindow.fillListOfLists()

            // reload tasklist if task has been edited or current list is renamed
            if (taskListWindow.listchanged === true) {
                reloadTaskList()
                taskListWindow.listchanged = false
            }

            break
        case PageStatus.Active:
            // add the list page to the pagestack
            pageStack.pushAttached(Qt.resolvedUrl("ListPage.qml"))

            // if the activation was started by the covers add function, directly focus to the textfield
            if (taskListWindow.coverAddTask === true) {
                timerAddTask.start()
                taskListWindow.coverAddTask = false
            }

            // decide which page should be shown at startup
            if (taskListWindow.switchStartPage === true) {
                taskListWindow.switchStartPage = false

                // switch to list overview at startup
                if (taskListWindow.startPage === 1) {
                    pageStack.navigateForward(PageStackAction.Immediate)
                }
                //minimize to background at startup
                else if (taskListWindow.startPage === 2) {
                    startPageTimer.start()
                }
            }
            break
        }
    }

    // read all tasks after start
    Component.onCompleted: {
        if (taskListWindow.justStarted === true) {
            DB.initializeDB()
            taskListWindow.listid = DB.getSettingAsNumber("defaultList")
            taskListWindow.defaultlist = taskListWindow.listid
            taskListWindow.justStarted = false

            // initialize application settings
            taskListWindow.coverListSelection = DB.getSettingAsNumber("coverListSelection")
            taskListWindow.coverListChoose = DB.getSettingAsNumber("coverListChoose")
            taskListWindow.coverListOrder = DB.getSettingAsNumber("coverListOrder")
            taskListWindow.taskOpenAppearance = DB.getSettingAsNumber("taskOpenAppearance") === 1
            taskListWindow.remorseOnDelete = DB.getSettingAsNumber("remorseOnDelete")
            taskListWindow.remorseOnMark = DB.getSettingAsNumber("remorseOnMark")
            taskListWindow.remorseOnMultiAdd = DB.getSettingAsNumber("remorseOnMultiAdd")
            taskListWindow.startPage = DB.getSettingAsNumber("startPage")
            taskListWindow.backFocusAddTask = DB.getSettingAsNumber("backFocusAddTask")
            taskListWindow.smartListVisibility = DB.getSettingAsNumber("smartListVisibility") === 1
            taskListWindow.recentlyAddedOffset = DB.getSettingAsNumber("recentlyAddedOffset")
            taskListWindow.doneTasksStrikedThrough = DB.getSettingAsNumber("doneTasksStrikedThrough") === 1
        }

        reloadTaskList()
    }

    Component.onDestruction: notification.close()

    RemorsePopup {
        id: tasklistRemorse
    }

    SilicaListView {
        id: taskList
        anchors.fill: parent
        model: ListModel {
            id: taskListModel
        }

        VerticalScrollDecorator { flickable: taskList }

        header: Column {
            width: parent.width
            id: taskListHeaderColumn

            PageHeader {
                width: parent.width
                title: listname + " - TaskList"
            }

            Row {
                width: parent.width - 2 * Theme.paddingLarge
                spacing: Theme.paddingLarge
                visible: smartListType === -1 ? true : false

                TextField {
                    id: taskAdd
                    width: parent.width - nextList.width
                    //: placeholder where the user should enter a name for a new task
                    placeholderText: qsTr("Enter unique task name")
                    //: a label to inform the user how to confirm the new task
                    label: qsTr("Press Enter/Return to add the new task")
                    // enable enter key if minimum task length has been reached
                    EnterKey.enabled: taskAdd.text.length > 0
                    // set allowed chars and task length
                    //validator: RegExpValidator { regExp: /^.{,60}$/ }

                    function addTask(newTask) {
                        var taskNew = newTask !== undefined ? newTask : taskAdd.text
                        if (taskNew.length > 0) {
                            // add task to db and tasklist
                            var newid = DB.writeTask(listid, taskNew, 1, 0, 0, taskListWindow.defaultPriority, "")
                            // catch sql errors
                            if (newid >= 0) {
                                insertNewTask(0, newid, taskNew, listid)
                                taskListWindow.coverAddTask = true
                                // reset textfield
                                taskAdd.text = ""
                            } else {
                                var taskId = DB.getTaskId(listId, taskNew)
                                if (parseInt(DB.getTaskDetails(taskId).Status) === 0) {
                                    DB.setTaskStatus(taskId, 1)
                                    reloadTaskList()
                                    taskAdd.text = ""
                                    //: notifying the user that the status of the task has been reopened
                                    taskListWindow.pushNotification("OK", qsTr("Task has been reopened!"), qsTr("The task already existed and was marked as done."))
                                }
                                else {
                                    // display notification if task already exists
                                    //: notifying the user why the task couldn't be added
                                    taskListWindow.pushNotification("WARNING", qsTr("Task could not be added!"), qsTr("It already exists on this list."))
                                }
                            }
                        }
                        if (taskListWindow.backFocusAddTask === 1)
                            timerAddTask.start()
                    }

                    EnterKey.onClicked: addTask()

                    onTextChanged: {
                        // divide text by new line characters
                        var textSplit = taskAdd.text.split(/\r\n|\r|\n/)
                        // if there are new lines
                        if (textSplit.length > 1) {
                            // clear textfield
                            taskAdd.text = ""
                            // helper array to check task's uniqueness before adding them
                            var tasksArray = []

                            // check if the tasks are unique
                            for (var i = 0; i < textSplit.length; i++)
                                if (parseInt(DB.checkTask(listid, textSplit[i])) === 0)
                                    if (tasksArray.indexOf(textSplit[i]) === -1)
                                        tasksArray.push(textSplit[i])

                            if (tasksArray.length > 0) {
                                //: remorse action when multiple tasks are added simultaneously
                                tasklistRemorse.execute(qsTr("Adding multiple tasks") + " (" + tasksArray.length + ")", function() {
                                    var addedTasks = []
                                    // add all of them to the DB and the list
                                    for (var i = 0; i < tasksArray.length; i++) {
                                        addTask(tasksArray[i])
                                        addedTasks.push(tasksArray[i])
                                    }
                                    // notification for added tasks
                                    //: notifying the user that new tasks have been added and which were added exactly (Details)
                                    taskListWindow.pushNotification("OK",
                                                                    //: notification if multiple tasks were successfully added
                                                                    tasksArray.length + " " + qsTr("new tasks have been added."),
                                                                    //: detailed list which tasks have been added simultaneously
                                                                    qsTr("Details") + ": " + addedTasks.join(', '))
                                } , taskListWindow.remorseOnMultiAdd * 1000)
                            }
                            else {
                                // display notification if no task has been added, because all of them already existed on the list
                                //: notify the user that all new tasks already existed on the list and weren't added again
                                taskListWindow.pushNotification("WARNING", qsTr("All tasks already exist!"), qsTr("No new tasks have been added to the list."))
                            }
                        }
                    }
                }

                IconButton {
                    id: nextList
                    height: taskAdd.height * 0.8
                    width: height

                    icon {
                        source: "image://theme/icon-cover-next"
                        height: parent.height * 0.8
                        width: height
                        fillMode: Image.PreserveAspectFit
                    }
                    anchors {
                        verticalCenter: taskAdd.verticalCenter
                    }

                    // function to switch to the next list, final switch is done by onListIdChanged
                    function switchList() {
                        var listArray = taskListWindow.listOfLists.split(",")

                        for (var i = 0; i < listArray.length; i++) {
                            if (listArray[i] == listid) {
                                if (i == listArray.length - 1)
                                    listid = listArray[0]
                                else
                                    listid = listArray[i + 1]
                                break
                            }
                        }
                    }

                    onClicked: switchList()
                }

            }
        }

        // show placeholder if there are no tasks available
        ViewPlaceholder {
            enabled: (taskList.count === 0) || taskListWindow.lockTaskOrientation
            //: hint to inform the user if the orientation is locked or there are no tasks on this list
            text: taskListWindow.lockTaskOrientation ? qsTr("Orientation locked") : qsTr("no tasks available")
        }

        // PullDownMenu and PushUpMenu
        PullDownMenu {
            MenuItem {
                //: menu item to switch to settings page
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            // Item to lock the screen orientation, which has been an user requested feature
            MenuItem {
                //: menu item to lock or unlock the device orientation
                text: taskListWindow.lockTaskOrientation === false ? qsTr("Lock orientation") : qsTr("Unlock orientation")
                onClicked: {
                    if (taskListWindow.lockTaskOrientation === false) {
                        taskPage.allowedOrientations = taskPage.orientation
                        taskListWindow.lockTaskOrientation = true
                    }
                    else {
                        taskPage.allowedOrientations = Orientation.All
                        taskListWindow.lockTaskOrientation = false
                    }

                }
            }
            MenuItem {
                enabled: doneTasksAvailable
                //: menu item to delete all done tasks
                text: qsTr("Delete all done tasks")
                onClicked: taskPage.deleteDoneTasks()
            }
            MenuItem {
                enabled: doneTasksAvailable
                //: menu item to reset all done tasks to the open status
                text: qsTr("Reset all done tasks")
                onClicked: taskPage.resetDoneTasks()
            }
        }
        PushUpMenu {
            MenuItem {
                //: menu item to switch to export/import page
                text: qsTr("Export/Import data")
                onClicked: pageStack.push(Qt.resolvedUrl("ExportPage.qml"))
            }
            MenuItem {
                text: qsTr("Sync with Dropbox")
                onClicked: pageStack.push("sync/DropboxSync.qml")
            }
            MenuItem {
                //: menu item to jump to the application information page
                text: qsTr("About") + " TaskList"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
        }

        delegate: ListItem {
            id: taskListItem
            width: ListView.view.width
            height: menuOpen ? taskContextMenu.height + taskLabel.height : taskLabel.height

            property Item taskContextMenu
            property bool menuOpen: taskContextMenu != null && taskContextMenu.parent === taskListItem

            // helper function to remove current item
            function remove() {
                // run remove via a silica remorse item
                //: deleting a task via displaying a remorse element (a Sailfish specific interaction element to stop a former started process)
                taskRemorse.execute(taskListItem, qsTr("Deleting") + " '" + task + "'", function() {
                    DB.removeTask(taskListModel.get(index).taskid)
                    taskListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            // helper function to mark current item as done
            function changeStatus(checkStatus) {
                var curTask = taskListModel.get(index)
                var taskID = curTask.taskid
                if (curTask.taskstatus === checkStatus)
                    return
                var newTask = {
                    taskid: curTask.taskid,
                    task: curTask.task,
                    taskstatus: checkStatus,
                    listid: curTask.listid,
                    dueDate: curTask.dueDate,
                    priority: curTask.priority
                }
                //: mark a task as open or done via displaying a remorse element (a Sailfish specific interaction element to stop a former started process)
                var changeStatusString = checkStatus ? qsTr("mark as open") : qsTr("mark as done")
                // copy status into string because results from sqlite are also strings
                var intStatus = (checkStatus === true) ? 1 : 0
                taskRemorse.execute(taskListItem, changeStatusString, function() {
                    // update DB
                    if (!DB.setTaskStatus(taskID, intStatus))
                        return
                    // delete current entry to simplify list sorting
                    taskListModel.remove(index)
                    // insert Item to correct position
                    if (checkStatus) {
                        taskListModel.insert(0, newTask)
                    } else {
                        var i;
                        for (i = 0; i < taskListModel.count; i++)
                            if (!taskListModel.get(i).taskstatus)
                                break;
                        // i points to the first done task or equal to the list length if done tasks are missing
                        taskListModel.insert(i, newTask)
                    }
                    updateOptions()
                }, taskListWindow.remorseOnMark * 1000)
            }

            // remorse item for all remorse actions
            RemorseItem {
                id: taskRemorse
            }

            TaskListItem {
                id: taskLabel
                x: Theme.paddingSmall
                text: task
                // hack (listname + "") to prevent an error (Unable to assign [undefined] to QString) when switching to a smartlist where the description should be shown
                description: composeTaskLabel(taskListModel.get(index))
                priorityValue: priority
                automaticCheck: false
                checked: taskListWindow.statusOpen(taskstatus)

                // show context menu
                onPressAndHold: {
                    if (!taskContextMenu) {
                        taskContextMenu = contextMenuComponent.createObject(taskList)
                    }
                    taskContextMenu.show(taskListItem)
                }

                onClicked: {
                    // because of the smart list concept, the status change is deactivated for them
                    if (smartListType === -1)
                        changeStatus(!taskstatus)
                }
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: taskMenu

                    MenuItem {
                        //: menu item to switch to the page where the selected task can be modified
                        text: qsTr("Edit")
                        onClicked: {
                            // close contextmenu
                            taskContextMenu.hide()
                            pageStack.push(Qt.resolvedUrl("EditPage.qml"), {"taskid": taskListModel.get(index).taskid, "taskname": taskListModel.get(index).task, "listindex": index})
                        }
                    }

                    MenuItem {
                        //: menu item to delete the selected task
                        text: qsTr("Delete")
                        onClicked: {
                            // close contextmenu
                            taskContextMenu.hide()
                            // trigger item removal
                            remove()
                        }
                    }
                }
            }
        }
    }
}
