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

    // helper function to add tasks to the list
    function appendTask(id, task, status) {
        taskListModel.append({"taskid": id, "task": task, "taskstatus": status})
    }

    function insertTask(index, id, task, status) {
        taskListModel.insert(index, {"taskid": id, "task": task, "taskstatus": status})
    }

    // helper function to wipe the tasklist element
    function wipeTaskList() {
        taskListModel.clear()
    }

    function reloadTaskList() {
        wipeTaskList()
        DB.readTasks(listid, "", "")
    }

    function deleteDoneTasks() {
        tasklistRemorse.execute(qsTr("Deleting all done tasks"),function(){
            // start deleting from the end of the list to not get a problem with already deleted items
            for(var i = taskListModel.count - 1; i >= 0; i--) {
                if (taskListModel.get(i).taskstatus === false) {
                    DB.removeTask(listid, taskListModel.get(i).taskid)
                    taskListModel.remove(i)
                }
                // stop if last open task has been reached to save battery power
                else if (taskListModel.get(i).taskstatus === true) {
                    break
                }
            }
        } , taskListWindow.remorseOnDelete * 1000)
    }

    // reload tasklist on activating first page
    onStatusChanged: {
        switch(status) {
        case PageStatus.Activating:
            // reload tasklist if navigateBack was used from list page
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
                taskList.headerItem.children[1].forceActiveFocus()
                taskListWindow.coverAddTask = false
            }
            break
        }
    }



    // read all tasks after start
    Component.onCompleted: {
        DB.initializeDB()
        taskListWindow.listid = parseInt(DB.getSetting("defaultList"))
        taskListWindow.defaultlist = listid
        taskListWindow.listname = DB.getListProperty(listid, "ListName")

        // initialize application settings
        taskListWindow.coverListSelection = parseInt(DB.getSetting("coverListSelection"))
        taskListWindow.coverListChoose = parseInt(DB.getSetting("coverListChoose"))
        taskListWindow.coverListOrder = parseInt(DB.getSetting("coverListOrder"))
        taskListWindow.taskOpenAppearance = parseInt(DB.getSetting("taskOpenAppearance")) === 1 ? true : false
        taskListWindow.dateFormat = parseInt(DB.getSetting("dateFormat"))
        taskListWindow.timeFormat = parseInt(DB.getSetting("timeFormat"))
        taskListWindow.remorseOnDelete = parseInt(DB.getSetting("remorseOnDelete"))
        taskListWindow.remorseOnMark = parseInt(DB.getSetting("remorseOnMark"))

        reloadTaskList()
    }

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
                placeholderText: qsTr("Enter unique task name")
                label: qsTr("Press Enter/Return to add the new task")
                // enable enter key if minimum task length has been reached
                EnterKey.enabled: taskAdd.text.length > 0
                // set allowed chars and task length
                validator: RegExpValidator { regExp: /^([^\'|\;|\"]){,30}$/ }

                function addTask() {
                    var taskNew = taskAdd.text
                    if (taskNew.length > 0) {
                        // add task to db and tasklist
                        var newid = DB.writeTask(listid, taskNew, 1, 0, 0)
                        // catch sql errors
                        if (newid !== "ERROR") {
                            taskPage.insertTask(0, newid, taskNew, true)
                            // reset textfield
                            taskAdd.text = ""
                        }
                    }
                }

                // if enter or return is pressed add the new task
                Keys.onEnterPressed: {
                    addTask()
                }
                Keys.onReturnPressed: {
                    addTask()
                }
            }
        }

        // show playholder if there are no tasks available
        ViewPlaceholder {
            enabled: taskList.count === 0
            text: qsTr("no tasks available")
        }

        // PullDownMenu and PushUpMenu
        PullDownMenu {
            MenuItem {
                text: qsTr("About") + " TaskList"
                onClicked: pageStack.push(Qt.resolvedUrl("AboutPage.qml"))
            }
            MenuItem {
                text: qsTr("Settings")
                onClicked: pageStack.push(Qt.resolvedUrl("SettingsPage.qml"))
            }
            MenuItem {
                text: qsTr("Delete all done tasks")
                onClicked: taskPage.deleteDoneTasks()
            }
            MenuItem {
                text: qsTr("Scroll to Bottom")
                onClicked: taskList.scrollToBottom()
            }
        }
        PushUpMenu {
            MenuItem {
                text: qsTr("Scroll to Top")
                onClicked: taskList.scrollToTop()
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
                taskRemorse.execute(taskListItem, qsTr("Deleting") + " '" + task + "'", function() {
                    DB.removeTask(listid, taskListModel.get(index).taskid)
                    taskListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            // helper function to mark current item as done
            function changeStatus(checkStatus) {
                var changeStatusString = (checkStatus === true) ? qsTr("mark as open") : qsTr("mark as done")
                // copy status into string because results from sqlite are also strings
                var movestatus = (checkStatus === true) ? 1 : 0
                taskRemorse.execute(taskListItem, changeStatusString, function() {
                    // update DB
                    DB.updateTask(listid, taskListModel.get(index).taskid, taskListModel.get(index).task, movestatus, 0, 0)
                    // copy item properties before deletion
                    var moveindex = index
                    var moveid = taskListModel.get(index).taskid
                    var movetask = taskListModel.get(index).task
                    // delete current entry to simplify list sorting
                    taskListModel.remove(index)
                    // catch it list count is zero, so for won't start
                    if (taskListModel.count === 0) {
                        taskPage.appendTask(moveid, movetask, checkStatus)
                    }
                    else {
                        // insert Item to correct position
                        for(var i = 0; i < taskListModel.count; i++) {
                            // undone tasks are moved to the beginning of the undone tasks
                            // done tasks are moved to the beginning of the done tasks
                            if ((checkStatus === true) || (checkStatus === false && taskListModel.get(i).taskstatus === false)) {
                                taskPage.insertTask(i, moveid, movetask, checkStatus)
                                break
                            }
                            // if the item should be added to the end of the list it has to be appended, because the insert target of count + 1 doesn't exist at this moment
                            else if (i >= taskListModel.count - 1) {
                                taskPage.appendTask(moveid, movetask, checkStatus)
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
                anchors.fill: parent
                anchors.top: parent.top
                automaticCheck: false
                checked: taskListWindow.statusOpen(taskstatus)
                anchors.verticalCenter: parent.verticalCenter

                // show context menu
                onPressAndHold: {
                    if (!taskContextMenu) {
                        taskContextMenu = contextMenuComponent.createObject(taskList)
                    }
                    taskContextMenu.show(taskListItem)
                }

                onClicked: {
                    changeStatus(!taskstatus)
                }
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: taskMenu

                    MenuItem {
                        height: 65
                        text: qsTr("Edit")
                        onClicked: {
                            // close contextmenu
                            taskContextMenu.hide()
                            pageStack.push(Qt.resolvedUrl("EditPage.qml"), {"taskid": taskListModel.get(index).taskid, "taskname": taskListModel.get(index).task, "listindex": index})
                        }
                    }

                    MenuItem {
                        height: 65
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
