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
    property bool openTasksAvailable

    // helper function to add tasks to the list
    function appendTask(id, task, status, listid) {
        taskListModel.append({"taskid": id, "task": task, "taskstatus": status, "listid": listid, "listname": DB.getListProperty(listid, "ListName")})
    }

    function insertTask(index, id, task, status, listid) {
        taskListModel.insert(index, {"taskid": id, "task": task, "taskstatus": status, "listid": listid, "listname": DB.getListProperty(listid, "ListName")})
    }

    // helper function to wipe the tasklist element
    function wipeTaskList() {
        taskListModel.clear()
    }

    function reloadTaskList() {
        wipeTaskList()
        if (taskListWindow.smartListType !== -1) {
            listname = taskListWindow.smartListNames[taskListWindow.smartListType]
            DB.readSmartListTasks(taskListWindow.smartListType)
        }
        else {
            listname = DB.getListProperty(listid, "ListName")
            DB.readTasks(listid, "", "", "")
        }

        // disable removealldonetasks pulldown menu of no done tasks available
        openTasksAvailable = false
        updateDeleteAllDoneOption("main update function")
    }

    function updateDeleteAllDoneOption (updatetxt) {
        for (var i = 0; i < taskListModel.count; i++) {
            if (taskListModel.get(i).taskstatus === !taskListWindow.taskOpenAppearance)
                openTasksAvailable = true
            console.log(taskListModel.get(i).taskstatus + "#" + i + "(" + updatetxt + ")")
        }
    }

    function deleteDoneTasks() {
        tasklistRemorse.execute(qsTr("Deleting all done tasks"),function(){
            // start deleting from the end of the list to not get a problem with already deleted items
            for(var i = taskListModel.count - 1; i >= 0; i--) {
                if (taskListModel.get(i).taskstatus === false) {
                    DB.removeTask(taskListModel.get(i).listid, taskListModel.get(i).taskid)
                    taskListModel.remove(i)
                }
                // stop if last open task has been reached to save battery power
                else if (taskListModel.get(i).taskstatus === true) {
                    break
                }
            }
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

    // workaround timer to force focus back top textfield after adding new task
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
            taskListWindow.listid = parseInt(DB.getSetting("defaultList"))
            taskListWindow.defaultlist = taskListWindow.listid
            taskListWindow.justStarted = false

            // initialize application settings
            taskListWindow.coverListSelection = parseInt(DB.getSetting("coverListSelection"))
            taskListWindow.coverListChoose = parseInt(DB.getSetting("coverListChoose"))
            taskListWindow.coverListOrder = parseInt(DB.getSetting("coverListOrder"))
            taskListWindow.taskOpenAppearance = parseInt(DB.getSetting("taskOpenAppearance")) === 1 ? true : false
            taskListWindow.remorseOnDelete = parseInt(DB.getSetting("remorseOnDelete"))
            taskListWindow.remorseOnMark = parseInt(DB.getSetting("remorseOnMark"))
            taskListWindow.remorseOnMultiAdd = parseInt(DB.getSetting("remorseOnMultiAdd"))
            taskListWindow.startPage = parseInt(DB.getSetting("startPage"))
            taskListWindow.backFocusAddTask = parseInt(DB.getSetting("backFocusAddTask"))
            taskListWindow.smartListVisibility = parseInt(DB.getSetting("smartListVisibility")) === 1 ? true : false
            taskListWindow.recentlyAddedOffset = parseInt(DB.getSetting("recentlyAddedOffset"))
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

            TextField {
                id: taskAdd
                width: parent.width
                visible: smartListType === -1 ? true : false
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
                        var newid = DB.writeTask(listid, taskNew, 1, 0, 0)
                        // catch sql errors
                        if (newid !== "ERROR") {
                            taskPage.insertTask(0, newid, taskNew, true, listid)
                            taskListWindow.coverAddTask = true
                            // reset textfield
                            taskAdd.text = ""
                        }
                        else {
                            // display notification if task already exists
                            //: notifying the user why the task couldn't be added
                            taskListWindow.pushNotification("WARNING", qsTr("Task could not be added!"), qsTr("It already exists on this list."))
                        }
                    }
                    if (taskListWindow.backFocusAddTask === 1)
                        timerAddTask.start()
                }

                EnterKey.onClicked: addTask()

                onTextChanged: {
                    // devide text by new line characters
                    var textSplit = taskAdd.text.split(/\r\n|\r|\n/)
                    // if there are new lines
                    if (textSplit.length > 1) {
                        // clear textfield
                        taskAdd.text = ""
                        // helper array to check task's uniqueness before adding them
                        var tasksArray = []

                        // check if the tasks are unique
                        for (var i = 0; i < textSplit.length; i++) {
                            var taskDouble = 0
                            if (parseInt(DB.checkTask(listid, textSplit[i])) === 0) {
                                // if task is duplicated in the list of multiple tasks change helper variable
                                for (var j = 0; j < tasksArray.length; j++) {
                                    if (tasksArray[j] === textSplit[i])
                                        taskDouble = 1
                                }

                                // if helper variable has been changed, tasks already is on the multiple tasks list and won't be added a second time
                                if (taskDouble === 0)
                                    tasksArray.push(textSplit[i])
                            }
                        }
                        if (tasksArray.length > 0) {
                            tasklistRemorse.execute(qsTr("Adding multiple tasks") + " (" + tasksArray.length + ")",function() {
                                var addedTasks = ""
                                // add all of them to the DB and the list
                                for (var i = 0; i < tasksArray.length; i++) {
                                    addTask(tasksArray[i])
                                    if (addedTasks === "")
                                        addedTasks = tasksArray[i]
                                    else
                                        addedTasks = addedTasks + ", " + tasksArray[i]
                                }
                                // notification for added tasks
                                //: notifying the user that new tasks have been added and which were added exactly (Details)
                                taskListWindow.pushNotification("INFO", tasksArray.length + " " + qsTr("new tasks have been added."), qsTr("Details") + ": " + addedTasks)
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
                //: menu item to delete all done tasks
                enabled: openTasksAvailable
                text: qsTr("Delete all done tasks")
                onClicked: taskPage.deleteDoneTasks()
            }
        }
        PushUpMenu {
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
                    DB.removeTask(listid, taskListModel.get(index).taskid)
                    taskListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            // helper function to mark current item as done
            function changeStatus(checkStatus) {
                var curListID = taskListModel.get(index).listid
                var curTask = taskListModel.get(index).task
                var curTaskID = taskListModel.get(index).taskid
                var curTaskStatus = taskListModel.get(index).taskstatus
                //: mark a task as open or done via displaying a remorse element (a Sailfish specific interaction element to stop a former started process)
                var changeStatusString = (checkStatus === true) ? qsTr("mark as open") : qsTr("mark as done")
                // copy status into string because results from sqlite are also strings
                var movestatus = (checkStatus === true) ? 1 : 0
                taskRemorse.execute(taskListItem, changeStatusString, function() {
                    // update DB
                    DB.updateTask(curListID, curListID, curTaskID, curTask, movestatus, 0, 0)
                    // copy item properties before deletion
                    var moveindex = index
                    var moveid = curTaskID
                    var movetask = curTask
                    // delete current entry to simplify list sorting
                    taskListModel.remove(index)
                    // catch if task count is zero, so for won't start
                    if (taskListModel.count === 0) {
                        taskPage.appendTask(moveid, movetask, checkStatus, curListID)
                    }
                    else {
                        // insert Item to correct position
                        for(var i = 0; i < taskListModel.count; i++) {
                            // undone tasks are moved to the beginning of the undone tasks
                            // done tasks are moved to the beginning of the done tasks
                            if ((checkStatus === true) || (checkStatus === false && curTaskStatus === false)) {
                                taskPage.insertTask(i, moveid, movetask, checkStatus, curListID)
                                break
                            }
                            // if the item should be added to the end of the list it has to be appended, because the insert target of count + 1 doesn't exist at this moment
                            else if (i >= taskListModel.count - 1) {
                                taskPage.appendTask(moveid, movetask, checkStatus, curListID)
                                break
                            }
                        }
                    }
                }, taskListWindow.remorseOnMark * 1000)
            }

            // remorse item for all remorse actions
            RemorseItem {
                id: taskRemorse
            }

            TextSwitch {
                id: taskLabel
                x: Theme.paddingSmall
                text: task
                // hack (listname + "") to prevent an error (Unable to assign [undefined] to QString) when switching to a smartlist where the description should be shown
                description: smartListType !== -1 ? listname + "" : ""
                anchors.fill: parent
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

                //
                onCheckedChanged: updateDeleteAllDoneOption("statuschange for " + taskLabel.text)
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: taskMenu

                    MenuItem {
                        height: 65
                        //: menu item to switch to the page where the selected task can be modified
                        text: qsTr("Edit")
                        onClicked: {
                            // close contextmenu
                            taskContextMenu.hide()
                            pageStack.push(Qt.resolvedUrl("EditPage.qml"), {"taskid": taskListModel.get(index).taskid, "taskname": taskListModel.get(index).task, "listindex": index})
                        }
                    }

                    MenuItem {
                        height: 65
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
