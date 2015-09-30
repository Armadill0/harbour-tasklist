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

    function composeTaskLabel(task) {
        if (typeof task === "undefined")
            return ""

        var result = []

        if (taskListWindow.smartListType >= 0)
            //: title for the list property in the task description (keep as short as possible)
            //% "List"
            result.push(qsTrId("list-label") + ": " + task.listname)

        if (typeof task.dueDate === "number" && task.dueDate > 0)
            //: title for the due date in the task description (keep as short as possible)
            //% "Due"
            result.push(qsTrId("due-date-label") + ": " + taskListWindow.humanReadableDueDate(task.dueDate))

        var tags = DB.readTaskTags(task.taskid)
        if (tags.length > 0)
            //: title for the tags in the task description (keep as short as possible)
            //% "Tags"
            result.push(qsTrId("tags-label") + ": " + tags.join(", "))

        if (typeof task.notes !== "undefined" && task.notes.length > 0)
            //: title for the notes in the task description (keep as short as possible)
            //% "Notes"
            result.push(qsTrId("notes-label") + ": " + task.notes)

        return result.join(" - ")
    }

    // helper function to add tasks to the list
    // @status - boolean
    // @dueDate - number, in milliseconds
    function appendTask(id, task, status, listid, creation, dueDate, priority, notes, repeat) {
        taskListModel.append({ taskid: id, task: task, taskstatus: status,
                                 listid: listid, listname: DB.getListName(listid),
                                 creation: creation, dueDate: dueDate, priority: priority,
                                 notes: notes, repeat: repeat, fresh: false })
    }

    function insertNewTask(index, id, task, listid, creation) {
        taskListModel.insert(index, { taskid: id, task: task, taskstatus: true,
                                 listid: listid, listname: DB.getListName(listid),
                                 creation: creation, dueDate: 0, priority: DB.PRIORITY_DEFAULT,
                                 notes: "", repeat: "", fresh: true })
    }

    function copyTaskModel(item) {
        return { taskid: item.taskid, task: item.task, taskstatus: item.taskstatus,
                 listid: item.listid, listname: item.listname,
                 creation: item.creation, dueDate: item.dueDate, priority: item.priority,
                 notes: item.notes, repeat: item.repeat }
    }

    // helper function to wipe the tasklist element
    function wipeTaskList() {
        taskListModel.clear()
    }

    function reloadTaskList() {
        wipeTaskList()
        if (taskListWindow.smartListType === 5) {
            var tagId = taskListWindow.tagId
            listname = "#" + DB.getTagName(tagId)
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
        //% "Deleting all done tasks"
        tasklistRemorse.execute(qsTrId("deleting-done-tasks-label"),function(){
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
        //% "Reseting all done tasks"
        tasklistRemorse.execute(qsTrId("reseting-done-tasks-label"),function(){
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

    function focusTaskAddField(releaseFocus) {
        var taskField = taskList.headerItem.children[1].children[0]
        if (releaseFocus && taskField.focus)
            taskField.focus = false
        else
            taskField.forceActiveFocus()
    }

    // function to switch to the next list, final switch is done by onListIdChanged
    function switchList(backwards) {
        var index = listOfLists.indexOf(listid)
        if (backwards)
            index = (index + listOfLists.length - 1) % listOfLists.length
        else
            index = (index + 1) % listOfLists.length
        listid = listOfLists[index]
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
        onTriggered: focusTaskAddField()
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
            if (taskListWindow.justStarted === true) {
                taskListWindow.initializeApplication()

                taskListWindow.listchanged = true
            }

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
            taskListWindow.initializeApplication()
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
        focus: true

        Keys.onLeftPressed: switchList(true)
        Keys.onRightPressed: switchList()
        Keys.onTabPressed: focusTaskAddField(true)

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
                    //% "Enter unique task name"
                    placeholderText: qsTrId("new-task-label")
                    //: a label to inform the user how to confirm the new task
                    //% "Press Enter/Return to add the new task"
                    label: qsTrId("new-task-confirmation-description")
                    // enable enter key if minimum task length has been reached
                    EnterKey.enabled: text.length > 0
                    // set allowed chars and task length
                    //validator: RegExpValidator { regExp: /^.{,60}$/ }

                    function addTask(newTask) {
                        var taskNew = newTask !== undefined ? newTask : taskAdd.text
                        if (taskNew.length > 0) {
                            // add task to db and tasklist
                            var result = DB.writeTask(listid, taskNew, 1, 0, 0, DB.PRIORITY_DEFAULT, "")
                            // catch sql errors
                            if (result.id >= 0) {
                                insertNewTask(0, result.id, taskNew, listid, result.creation)
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
                                    //% "Task has been reopened!"
                                    taskListWindow.pushNotification("OK", qsTrId("task-reopened-success"),
                                                                    //% "The task already existed and was marked as done."
                                                                    qsTrId("task-reopened-success-details"))
                                }
                                else {
                                    // display notification if task already exists
                                    //: notifying the user why the task couldn't be added
                                    //% "Task could not be added!"
                                    taskListWindow.pushNotification("WARNING", qsTrId("task-not-added-warning"),
                                                                    //% "It already exists on this list."
                                                                    qsTrId("task-not-added-warning-details"))
                                }
                            }
                        }
                        if (taskListWindow.backFocusAddTask === 1)
                            timerAddTask.start()
                    }

                    visible: smartListType === -1 ? true : false
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
                                //% "Adding multiple tasks"
                                tasklistRemorse.execute(qsTrId("task-multiadd-label") + " (" + tasksArray.length + ")", function() {
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
                                                                    //% "new tasks have been added."
                                                                    tasksArray.length + " " + qsTrId("tasks-added-success"),
                                                                    //: detailed list which tasks have been added simultaneously
                                                                    //% "Details"
                                                                    qsTrId("details-label") + ": " + addedTasks.join(', '))
                                } , taskListWindow.remorseOnMultiAdd * 1000)
                            }
                            else {
                                // display notification if no task has been added, because all of them already existed on the list
                                //: notify the user that all new tasks already existed on the list and weren't added again
                                //% "All tasks already exist!"
                                taskListWindow.pushNotification("WARNING", qsTrId("tasks-exist-warning"),
                                                                //% "No new tasks have been added to the list."
                                                                qsTrId("tasks-exist-warning-details"))
                            }
                        }
                    }
                }

                IconButton {
                    id: nextList
                    height: taskAdd.height * 0.8
                    width: height
                    enabled: taskListWindow.coverActionMultiple

                    icon {
                        source: "image://theme/icon-cover-next"
                        height: parent.height * 0.8
                        width: height
                        fillMode: Image.PreserveAspectFit
                    }
                    anchors {
                        verticalCenter: taskAdd.verticalCenter
                    }

                    onClicked: switchList()
                }

            }
        }

        // show placeholder if there are no tasks available
        ViewPlaceholder {
            enabled: (taskList.count === 0) || taskListWindow.lockTaskOrientation
            //: hint to inform the user if the orientation is locked or there are no tasks on this list
            //% "Orientation locked"
            text: taskListWindow.lockTaskOrientation ? qsTrId("orientation-lock-label") :
                                                       //% "no tasks available"
                                                       qsTrId("no-tasks-label")
        }

        // PullDownMenu and PushUpMenu
        PullDownMenu {
            MenuItem {
                //: menu item to switch to settings page
                //% "Settings"
                text: qsTrId("settings-label")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            // Item to lock the screen orientation, which has been an user requested feature
            MenuItem {
                //: menu item to lock or unlock the device orientation
                //% "Lock orientation"
                text: taskListWindow.lockTaskOrientation === false ? qsTrId("lock-orientation-label") :
                                                                     //% "Unlock orientation"
                                                                     qsTrId("unlock-orientation-label")
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
                //% "Delete all done tasks"
                text: qsTrId("delete-done-tasks-label")
                onClicked: taskPage.deleteDoneTasks()
            }
            MenuItem {
                enabled: doneTasksAvailable
                //: menu item to reset all done tasks to the open status
                //% "Reset all done tasks"
                text: qsTrId("reset-done-tasks-label")
                onClicked: taskPage.resetDoneTasks()
            }
        }
        PushUpMenu {
            MenuItem {
                //: menu item to switch to export/import page
                //% "Export/Import data"
                text: qsTrId("export-import-label")
                onClicked: pageStack.push(Qt.resolvedUrl("ExportPage.qml"))
            }
            MenuItem {
                //% "Sync with Dropbox"
                text: qsTrId("dropbox-sync-label")
                onClicked: pageStack.push("sync/DropboxSync.qml", { attemptedAuth: false })
            }
            MenuItem {
                //: menu item to jump to the application information page
                //% "About"
                text: qsTrId("about-label") + " TaskList"
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
                //% "Deleting"
                taskRemorse.execute(taskListItem, qsTrId("deleting-label") + " '" + task + "'", function() {
                    DB.removeTask(taskListModel.get(index).taskid)
                    taskListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            // helper function to toggle current item between open/done
            function changeStatus(status) {
                var curTask = taskListModel.get(index)
                if (curTask.taskstatus === status)
                    return
                // check if task is recurring and it's possible to process it
                var recurring = typeof curTask.repeat === "string" && curTask.repeat.length > 0
                if (recurring) {
                    if (status) {
                        console.log("ERROR: a recurring task could only be closed")
                        return
                    }
                    if (typeof curTask.dueDate !== 'number' || curTask.dueDate <= 0) {
                        console.log("ERROR: a recurring task without due date could not be closed")
                        return
                    }
                }
                // create a new copy of the task and modify it
                var newTask = copyTaskModel(curTask)
                if (recurring) {
                    // a recurring task due date is to be moved forward
                    for (var i in DB.REPETITION_VARIANTS) {
                        var rep = DB.REPETITION_VARIANTS[i]
                        if (curTask.repeat === rep.key) {
                            newTask.dueDate = rep.func(curTask.dueDate)
                            break
                        }
                    }
                } else {
                    // ordinary task only changes status
                    newTask.taskstatus = status
                }
                //: mark a task as open or done via displaying a remorse element (a Sailfish specific interaction element to stop a former started process)
                //% "mark as open"
                var changeStatusString = status ? qsTrId("mark-open-label") :
                                                       //% "mark as done"
                                                       qsTrId("mark-done-label")
                taskRemorse.execute(taskListItem, changeStatusString, function() {
                    // update DB
                    if (recurring && !DB.setTaskDueDate(newTask.taskid, newTask.dueDate))
                        return
                    else if (!recurring && !DB.setTaskStatus(newTask.taskid, Number(newTask.taskstatus)))
                        return
                    // delete current entry to simplify list sorting
                    taskListModel.remove(index)
                    // insert Item to correct position
                    if (status && !recurring) {
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

            ListView.onAdd: {
                if (typeof fresh !== 'undefined' && fresh) {
                    taskLabel.startBlink(taskListWindow.remorseOnMark * 2000, 5)
                    fresh = false
                }
            }

            // remorse item for all remorse actions
            RemorseItem {
                id: taskRemorse
            }

            TaskListItem {
                id: taskLabel
                x: Theme.paddingSmall
                text: task
                // hack (listname + "") to prevent an error (Unable to assign [undefined] to qsTrIding) when switching to a smartlist where the description should be shown
                description: composeTaskLabel(taskListModel.get(index))
                priorityValue: priority
                automaticCheck: false
                checked: taskListWindow.statusOpen(taskstatus)

                // show context menu
                onPressAndHold: {
                    if (blinking)
                        stopBlink()
                    if (!taskContextMenu) {
                        taskContextMenu = contextMenuComponent.createObject(taskList)
                    }
                    taskContextMenu.show(taskListItem)
                }

                onClicked: {
                    if (blinking) {
                        stopBlink()
                        pageStack.push(Qt.resolvedUrl("EditPage.qml"), {params: copyTaskModel(model)})
                        return
                    }
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
                        //% "Edit"
                        text: qsTrId("edit-label")
                        onClicked: {
                            // close contextmenu
                            taskContextMenu.hide()
                            pageStack.push(Qt.resolvedUrl("EditPage.qml"), {params: copyTaskModel(model)})
                        }
                    }

                    MenuItem {
                        //: menu item to delete the selected task
                        //% "Delete"
                        text: qsTrId("delete-label")
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
