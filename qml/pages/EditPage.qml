/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Thomas Amler
    Contact: Thomas Amler <takslist@penguinfriends.org>

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

    property var params
    property string tags: ""

    function appendList(id, name) {
        listModel.append({ id: id, name: name })
        if (id === params.listid) {
            list.currentIndex = listModel.count - 1
            list.currentItem = list.menu.children[list.currentIndex]
        }
    }

    function dueDateIsPresent () {
        return typeof params.dueDate === 'number' && params.dueDate > 0
    }

    function composeDueDate() {
        if (!dueDateIsPresent())
	    //% "none (tap to select)"
            return qsTrId("noval-tap-label")
        return taskListWindow.humanReadableDueDate(params.dueDate)
    }

    function humanTags() {
        if (tags.length === 0)
	    //% "none (tap to select)"
            return qsTrId("noval-tap-label")
        return tags
    }

    function checkContent() {
        var ok = true
        var listId = listModel.get(list.currentIndex).id
        var name = task.text
        var count = DB.checkTask(listId, name)

        // if task already exists in target list, display warning
        if (count > 0 && (name !== params.task || listId !== params.listid)) {
            task.errorHighlight = true
            ok = false
            // display notification if task already exists on the selected list
            //: informing the user that a new task already exists on the selected list
            //% "Task could not be saved!"
            taskListWindow.pushNotification("WARNING", qsTrId("task-not-saved-error"),
                                            //: detailed information why the task modifications haven't been saved
                                            //% "It already exists on the selected list."
                                            qsTrId("task-not-saved-detail"))
        } else {
            task.errorHighlight = false
        }

        // if repetition is set, then due date is required too
        if (repeat.currentIndex > 0 && !dueDateIsPresent()) {
            dueDate.highlighted = true
            ok = false
	    //% "Task could not be saved!"
            taskListWindow.pushNotification("WARNING", qsTrId("task-not-saved-error"),
                                            //: detailed information why the task modifications can't be saved
	                                    //% "A due date is required for the repetition."
                                            qsTrId("repitition-resuires-due-decription"))
        } else {
            dueDate.highlighted = false
        }

        canAccept = ok
    }

    Component.onCompleted: {
        // populate list combobox
        DB.allLists(appendList)

        priorityBox.currentIndex = DB.PRIORITY_MAX - parseInt(params.priority)

        // populate repeat combobox
        for (var i in DB.REPETITION_VARIANTS) {
            var item = DB.REPETITION_VARIANTS[i]
            repeatModel.append({ name: item.name })
            if (item.key === params.repeat) {
                repeat.currentIndex = Number(i)
                repeat.currentItem = repeat.menu.children[repeat.currentIndex]
            }
        }

        // load tags list
        tags = DB.readTaskTags(params.taskid).join(", ")
    }

    onAccepted: {
        var ok = DB.updateTask(params.taskid, listModel.get(list.currentIndex).id,
                               task.text, taskListWindow.statusOpen(status.checked) ? 1 : 0,
                               params.dueDate, 0, priorityBox.selectedPriority(), notes.text,
                               DB.REPETITION_VARIANTS[repeat.currentIndex].key)
        if (ok)
            taskListWindow.listchanged = true
        if (editTags.modified) {
            var newTags = tags.length > 0 ? tags.split(", ") : []
            DB.updateTaskTags(params.taskid, newTags)
            taskListWindow.listchanged = true
        }
    }

    ListModel {
        id: listModel
    }

    ListModel {
        id: repeatModel
    }

    SilicaFlickable {
        id: flickable
        anchors.fill: parent
        contentHeight: form.height

        VerticalScrollDecorator { flickable: flickable }

        Column {
            id: form
            width: parent.width

            DialogHeader {
                //: headline of the editing dialog of a task
                //% "Edit task"
                title: qsTrId("edit-task-label")
                //: save the currently made changes to the task
                //% "Save"
                acceptText: qsTrId("save-button")
            }

            SectionHeader {
                //: headline for the section with the task attributes
                //% "Task properties"
                text: qsTrId("task-properties-label")
            }

            TextField {
                id: task
                width: parent.width
                text: params.task
                //: information how the currently made changes can be saved
                //% "Task already exists on this list!"
                label: errorHighlight ? qsTrId("task-exists-on-list-error") :
                                        //% "Task name"
                                        qsTrId("task-name-label")
                // set allowed chars and task length
                validator: RegExpValidator { regExp: /^([^\'|\;|\"]){,60}$/ }
                onTextChanged: {
                    // check Content only if page is active because of the dynamic loading of listLocatedIn
                    if (editTaskPage.status === PageStatus.Active)
                        checkContent()
                }
            }

            TextSwitch {
                id: status
                anchors.horizontalCenter: parent.Center
                //: choose if this task is pending or done
                //% "task is open"
                text: taskListWindow.statusOpen(params.taskstatus) ? qsTrId("task-open-label") :
                                                           //% "task is done"
                                                           qsTrId("task-done-label")
                checked: taskListWindow.statusOpen(params.taskstatus)
            }

            ComboBox {
                id: list
                anchors.left: parent.left
                //: option to change the list where the task should be located
                //% "List"
                label: qsTrId("list-label") + ":"

                menu: ContextMenu {
                    Repeater {
                         model: listModel
                         MenuItem {
                             text: model.name
                         }
                    }
                }

                onCurrentIndexChanged: checkContent()
            }

            ComboBox {
                id: priorityBox
                anchors.left: parent.left
                label: qsTrId("priority-label") + ":"

                menu: ContextMenu {
                    Repeater {
                        model: DB.PRIORITY_MAX - DB.PRIORITY_MIN + 1
                        MenuItem {
                            text: DB.PRIORITY_MAX - index
                        }
                    }
                }

                function selectedPriority() {
                    return DB.PRIORITY_MAX - currentIndex
                }
            }

            SectionHeader {
                //: headline for the date and time properties of the task
                //% "Dates"
                text: qsTrId("dates-label")
            }

            Row {
                width: parent.width - 2 * Theme.paddingLarge

                ValueButton {
                    id: dueDate
                    width: parent.width - clearButton.width
                    anchors.verticalCenter: clearButton.verticalCenter
                    //: select the due date for a task
                    //% "Due"
                    label: qsTrId("due-date-label") + ":"
                    value: composeDueDate()

                    onClicked: {
                        var hint = dueDateIsPresent() ? new Date(params.dueDate) : new Date()
                        var dialog = pageStack.push(pickerComponent, { date: hint })
                        dialog.accepted.connect(function() {
                            params.dueDate = dialog.date.getTime()
                            value = composeDueDate()
                            clearButton.visible = true
                            checkContent()
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
                    visible: dueDateIsPresent()
                    onClicked: {
                        params.dueDate = 0
                        dueDate.value = composeDueDate()
                        visible = false
                        checkContent()
                    }
                }
            }

            ComboBox {
                id: repeat
                width: parent.width
	        //% "Repeat"
                label: qsTrId("repeat-label") + ":"

                menu: ContextMenu {
                    Repeater {
                        model: repeatModel
                        MenuItem {
                            text: model.name
                        }
                    }
                }

                onCurrentIndexChanged: checkContent()
            }

            Label {
                id: creation
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge
                //: displays the date when the task has been created by the user
                //% "Created"
                text: qsTrId("created-date-label") + ": " + Qt.formatDateTime(new Date(params.creation)).toLocaleString(Qt.locale())
            }

            SectionHeader {
                //: headline for the tags section
                //% "Tags"
                text: qsTrId("tags-label")
            }

            ValueButton {
                id: editTags
                //: label for the tags field
                //% "Tags"
                label: qsTrId("tags-label") + ":"
                value: humanTags()
                property bool modified: false

                onClicked: {
                    var dialog = pageStack.push("TagDialog.qml", { selected: tags})
                    dialog.accepted.connect(function() {
                        if (dialog.selected !== tags) {
                            modified = true
                            tags = dialog.selected
                        }
                    })
                }
            }

            SectionHeader {
                //: headline for the section where notes for the task can be saved
                //% "Notes"
                text: qsTrId("notes-label")
            }

            TextArea {
                id: notes
                width: parent.width
                //: textfield to enter notes
                //% "Enter your notes or description here"
                placeholderText: qsTrId("notes-placeholder")
                focus: false
                text: params.notes || ""
            }
        }
    }
}
