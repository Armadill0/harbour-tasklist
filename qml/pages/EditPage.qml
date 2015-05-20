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

Dialog {
    id: editTaskPage
    allowedOrientations: Orientation.All
    canAccept: true

    property string taskname
    property string taskid
    property bool taskstatus
    // format - ISO 8601, empty if not set
    property string taskduedate
    property string taskcreationdate
    property int taskpriority
    property string tasknote
    property int listid
    property int listindex
    // list of tag IDs
    property string tasktags

    function getDueDate(isoDate) {
        if (isoDate.length === 0)
            return qsTr("none (tap to select)")
        var dueDate = new Date(isoDate)
        var dueDateString = new Date(isoDate).toDateString()
        var today = new Date()
        if (dueDateString === today.toDateString())
            return qsTr("today")
        var tomorrow = new Date(today.getTime() + 24 * 3600 * 1000)
        if (dueDateString === tomorrow.toDateString())
            return qsTr("tomorrow")
        var result = dueDate.toLocaleDateString(Qt.locale(), Locale.ShortFormat)
        return result;
    }

    // helper function to add lists to the listLocation field
    function appendList(id, name) {
        listLocationModel.append({ listid: id, listname: name })
        if (id === listid)
            listindex = listLocationModel.count - 1
    }

    function checkContent () {
        var changedListID = listLocationModel.get(listLocatedIn.currentIndex).listid
        var changedTaskName = taskName.text
        var count = DB.checkTask(changedListID, changedTaskName)
        // if task already exists in target list, display warning
        if (count > 0 && (changedTaskName !== taskname || changedListID !== listid)) {
            taskName.errorHighlight = true
            canAccept = false
            // display notification if task already exists on the selected list
            //: informing the user that a new task already exists on the selected list
            taskListWindow.pushNotification("WARNING", qsTr("Task could not be saved!"),
                                            /*: detailed information why the task modifications haven't been saved */
                                            qsTr("It already exists on the selected list."))
        } else {
            taskName.errorHighlight = false
            canAccept = true
        }
    }

    // reload tasklist on activating first page
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            var details = DB.getTaskDetails(taskid)
            taskstatus = parseInt(details.Status) === 1
            taskduedate = details.DueDate ? (new Date(details.DueDate).toISOString()) : ""
            taskcreationdate = new Date(details.CreationDate)
            taskpriority = parseInt(details.Priority)
            tasknote = details.Note || ""
            tasktags = DB.readTaskTags(taskid).join(", ")
        }
    }

    onAccepted: {
        var dueDate = 0
        if (taskDueDate.value.length > 0)
            dueDate = new Date(taskDueDate.value).getTime()
        var result = DB.updateTask(taskid, listLocationModel.get(listLocatedIn.currentIndex).listid,
                                   taskName.text, taskListWindow.statusOpen(taskStatus.checked) ? 1 : 0,
                                   dueDate, 0,
                                   taskPriority.value, taskNote.text)
        if (result)
            taskListWindow.listchanged = true
        if (tasktags !== editTags.selected) {
            var newTags = []
            if (editTags.selected)
                newTags = editTags.selected.split(", ")
            DB.updateTaskTags(taskid, newTags)
            taskListWindow.listchanged = true
        }
    }

    Component.onCompleted: {
        var details = DB.getTaskDetails(taskid)
        listid = parseInt(details.ListID)
        DB.allLists(appendList)
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
                title: qsTr("Edit") + " '" + taskname + "'"
                //: save the currently made changes to the task
                acceptText: qsTr("Save")
            }

            SectionHeader {
                text: qsTr("Task properties")
            }

            TextField {
                id: taskName
                width: parent.width
                text: taskname
                //: information how the currently made changes can be saved
                label: errorHighlight ? qsTr("Task already exists on this list!") : qsTr("Task name")
                // set allowed chars and task length
                validator: RegExpValidator { regExp: /^([^\'|\;|\"]){,60}$/ }
                onTextChanged: {
                    // check Content only if page is active because of the dynamic loading of listLocatedIn
                    if (editTaskPage.status === PageStatus.Active)
                        checkContent()
                }
            }

            TextSwitch {
                id: taskStatus
                anchors.horizontalCenter: parent.Center
                //: choose if this task is pending or done
                text: taskListWindow.statusOpen(checked) ? qsTr("task is open") : qsTr("task is done")
                checked: taskListWindow.statusOpen(editTaskPage.taskstatus)
            }

            ComboBox {
                id: listLocatedIn
                anchors.left: parent.left
                //: option to change the list where the task should be located
                label: qsTr("List") + ":"

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
                label: qsTr("Priority")
                minimumValue: taskListWindow.minimumPriority
                maximumValue: taskListWindow.maximumPriority
                stepSize: 1
                value: editTaskPage.taskpriority
                valueText: value.toString()
            }

            SectionHeader {
                text: qsTr("Dates")
            }

            Row {
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge

                Label {
                    anchors.verticalCenter: clearButton.verticalCenter
                    text: qsTr("Due") + ":"
                }

                TextField {
                    id: taskDueDate
                    anchors {
                        verticalCenter: clearButton.verticalCenter
                        verticalCenterOffset: Theme.paddingLarge
                    }
                    // save due date value in component, because page's value would be lost after page re-activation
                    property string value: taskduedate
                    text: getDueDate(value)
                    readOnly: true

                    onValueChanged: text = getDueDate(value)

                    onClicked: {
                        var hint = new Date()
                        if (value.length > 0)
                            hint = new Date(value)
                        var dialog = pageStack.push(pickerComponent, { date: hint })
                        dialog.accepted.connect(function() {
                            taskDueDate.value = dialog.date.toISOString()
                        })
                    }

                    Component {
                        id: pickerComponent
                        DatePickerDialog {}
                    }
                }

                IconButton {
                    id: clearButton
                    icon.source: "image://theme/icon-m-clear"
                    enabled: taskDueDate.value.length > 0
                    onClicked: taskDueDate.value = ""
                }
            }

            Label {
                id: taskCreationDate
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge
                //: displays the date when the task has been created by the user
                text: qsTr("Created") + ": " + Qt.formatDateTime(editTaskPage.taskcreationdate).toLocaleString(Qt.locale())
            }

            SectionHeader {
                text: qsTr("Tags")
            }

            ValueButton {
                id: editTags
                value: selected || qsTr("none (tap to select)")
                label: qsTr("Tags") + ":"
                property string selected: tasktags

                onClicked: {
                    var dialog = pageStack.push("TagDialog.qml", { selected: selected })
                    dialog.accepted.connect(function() {
                        selected = dialog.selected
                    })
                }
            }

            SectionHeader {
                text: qsTr("Notes")
            }

            TextArea {
                id: taskNote
                width: parent.width
                placeholderText: qsTr("Enter your notes or description here")
                focus: false
                text: tasknote
            }
        }
    }
}
