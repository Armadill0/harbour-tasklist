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

Dialog {
    id: editTaskPage
    allowedOrientations: Orientation.All
    canAccept: true

    property string taskname
    property string taskid
    property bool taskstatus
    property string taskcreationdate
    // format - ISO 8601, empty if not set
    property string taskduedate
    property int taskpriority
    property string tasknote
    property int listid
    property int listindex

    function getDueDate(isoDate) {
        if (isoDate.length === 0)
            return qsTr("no due date")
        var dueDate = new Date(isoDate)
        var dueDateString = new Date(isoDate).toDateString()
        var today = new Date()
        if (dueDateString === today.toDateString())
            return qsTr("until today")
        var tomorrow = new Date(today.getTime() + 24 * 3600 * 1000)
        if (dueDateString === tomorrow.toDateString())
            return qsTr("until tomorrow")
        var result = dueDate.toLocaleDateString()
        // remove year if the date is in the current year
        if (dueDate.getFullYear() === today.getFullYear()) {
            var year = " " + dueDate.getFullYear();
            var begin = result.indexOf(year);
            var end = begin + year.length;
            if (begin >= 0)
                result = result.slice(0, begin) + result.slice(end);
        }
        return qsTr("until ") + result;
    }

    // helper function to add lists to the listLocation field
    function appendList(id, listname) {
        listLocationModel.append({"listid": id, "listname": listname})
        if (id === listid) {
            listindex = listLocationModel.count - 1
        }
    }

    function checkContent () {
        var changedListID = listLocationModel.get(listLocatedIn.currentIndex).listid
        var changedTaskName = taskName.text
        var count = DB.checkTask(changedListID, changedTaskName)
        // if task already exists in target list, display warning
        if (count > 0 && (changedTaskName !== taskname || changedListID !== listid)) {
            taskName.errorHighlight = true
            editTaskPage.canAccept = false
            // display notification if task already exists on the selected list
            //: informing the user that a new task already exists on the selected list
            taskListWindow.pushNotification("WARNING", qsTr("Task could not be saved!"),
                                            /*: detailed information why the task modifications haven't been saved */
                                            qsTr("It already exists on the selected list."))
        } else {
            taskName.errorHighlight = false
            editTaskPage.canAccept = true
        }
    }

    // reload tasklist on activating first page
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            editTaskPage.taskstatus = parseInt(DB.getTaskProperty(taskid, "Status")) === 1
            editTaskPage.taskcreationdate = new Date(DB.getTaskProperty(taskid, "CreationDate"))
            var dueDate = DB.getTaskProperty(taskid, "DueDate")
            editTaskPage.taskduedate = dueDate ? (new Date(dueDate).toISOString()) : ""
            editTaskPage.taskpriority = parseInt(DB.getTaskProperty(taskid, "Priority"))
            var note = DB.getTaskProperty(taskid, "Note")
            editTaskPage.tasknote = note || ""
        }
    }

    onAccepted: {
        var dueDate = 0
        if (taskDueDate.value.length > 0)
            dueDate = new Date(taskDueDate.value).getTime()
        var result = DB.updateTask(editTaskPage.taskid, listLocationModel.get(listLocatedIn.currentIndex).listid,
                                   taskName.text, taskListWindow.statusOpen(taskStatus.checked) ? 1 : 0,
                                   dueDate, 0,
                                   taskPriority.value, taskNote.text)
        if (result)
            taskListWindow.listchanged = true
    }

    Component.onCompleted: {
        listid = parseInt(DB.getTaskProperty(taskid, "ListID"))
        DB.readLists()
        listLocatedIn.currentIndex = listindex
        listLocatedIn.currentItem = listLocatedIn.menu.children[listindex]
    }

    ListModel {
        id: listLocationModel
    }

    SilicaFlickable {
        id: editList
        anchors.fill: parent
        contentHeight: editColumn.height

        VerticalScrollDecorator { flickable: editList }

        Column {
            id: editColumn
            width: parent.width

            DialogHeader {
                //: headline of the editing dialog of a task
                title: qsTr("Edit task")
                //: save the currently made changes to the task
                acceptText: qsTr("Save")
            }

            TextSwitch {
                id: taskStatus
                anchors.horizontalCenter: parent.Center
                //: choose if this task is pending or done
                text: taskStatus.checked ? qsTr("task is opened") : qsTr("task is closed")
                checked: taskListWindow.statusOpen(editTaskPage.taskstatus)
            }

            TextField {
                id: taskName
                width: parent.width
                text: editTaskPage.taskname
                //: information how the currently made changes can be saved
                label: errorHighlight ? qsTr("task already exists on this list!") : qsTr("task name")
                // set allowed chars and task length
                validator: RegExpValidator { regExp: /^([^\'|\;|\"]){,60}$/ }
                onTextChanged: {
                    // check Content only if page is active because of the dynamic loading of listLocatedIn
                    if (editTaskPage.status === PageStatus.Active)
                        checkContent()
                }
            }

            ComboBox {
                id: listLocatedIn
                anchors.left: parent.left
                //: option to change the list where the task should be located
                label: qsTr("list") + ":"

                menu: ContextMenu {
                    Repeater {
                         model: listLocationModel
                         MenuItem {
                             text: model.listname
                         }
                    }
                }

                onCurrentIndexChanged: {
                    checkContent()
                }
            }

            Slider {
                id: taskPriority
                width: parent.width
                label: qsTr("priority")
                minimumValue: 0
                maximumValue: 3
                stepSize: 1
                value: editTaskPage.taskpriority
                valueText: value.toString()
            }

            TextField {
                id: taskDueDate
                anchors.horizontalCenter: parent.horizontalCenter
                // save due date value in component, because page's value would be lost after page re-activation
                property string value: editTaskPage.taskduedate
                text: getDueDate(editTaskPage.taskduedate)
                readOnly: true

                onClicked: {
                    var hint = new Date()
                    if (value.length > 0)
                        hint = new Date(value)
                    var dialog = pageStack.push(pickerComponent, { date: hint })
                    dialog.accepted.connect(function() {
                        taskDueDate.value = dialog.date.toISOString()
                        taskDueDate.text = getDueDate(taskDueDate.value)
                    })
                }

                Component {
                    id: pickerComponent
                    DatePickerDialog {}
                }                
            }

            SectionHeader {
                text: qsTr("Notes")
            }

            TextArea {
                id: taskNote
                width: 480
                height: 180
                anchors.horizontalCenter: parent.horizontalCenter
                placeholderText: qsTr("Enter notes here")
                placeholderColor: "gray"
                background: Rectangle {
                    color: "white"
                    width: parent.width
                    height: parent.height
                }

                focus: false
                color: "black"
                font.pointSize: Theme.fontSizeSmall
                cursorColor: "black"

                text: editTaskPage.tasknote
            }
        }
    }
}
