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
            return qsTr("none (tap to select)")
        return DB.humanReadableDueDate(params.dueDate)
    }

    function humanTags() {
        if (tags.length === 0)
            return qsTr("none (tap to select)")
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
            taskListWindow.pushNotification("WARNING", qsTr("Task could not be saved!"),
                                            /*: detailed information why the task modifications haven't been saved */
                                            qsTr("It already exists on the selected list."))
        } else {
            task.errorHighlight = false
        }

        // if repetition is set, then due date is required too
        if (repeat.currentIndex > 0 && !dueDateIsPresent()) {
            dueDate.highlighted = true
            ok = false
            taskListWindow.pushNotification("WARNING", qsTr("Task could not be saved!"),
                                            /*: detailed information why the task modifications can't be saved */
                                            qsTr("A due date is required for the repetition."))
        } else {
            dueDate.highlighted = false
        }

        canAccept = ok
    }

    Component.onCompleted: {
        // populate list combobox
        DB.allLists(appendList)

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
                               params.dueDate, 0, priority.value, notes.text,
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
                title: qsTr("Edit '%1'").arg(params.task)
                //: save the currently made changes to the task
                acceptText: qsTr("Save")
            }

            SectionHeader {
                //: headline for the section with the task attributes
                text: qsTr("Task properties")
            }

            TextField {
                id: task
                width: parent.width
                text: params.task
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
                id: status
                anchors.horizontalCenter: parent.Center
                //: choose if this task is pending or done
                checked: taskListWindow.statusOpen(params.taskstatus)
                text: taskListWindow.statusOpen(checked) ? qsTr("task is open") : qsTr("task is done")
            }

            ComboBox {
                id: list
                anchors.left: parent.left
                //: option to change the list where the task should be located
                label: qsTr("List:")

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

            Slider {
                id: priority
                width: parent.width
                //: select the tasks priority
                label: qsTr("Priority")
                minimumValue: DB.PRIORITY_MIN
                maximumValue: DB.PRIORITY_MAX
                stepSize: DB.PRIORITY_STEP
                value: parseInt(params.priority)
                valueText: value.toString()
            }

            SectionHeader {
                //: headline for the date and time properties of the task
                text: qsTr("Dates")
            }

            Row {
                width: parent.width - 2 * Theme.paddingLarge

                ValueButton {
                    id: dueDate
                    width: parent.width - clearButton.width
                    anchors.verticalCenter: clearButton.verticalCenter
                    //: select the due date for a task
                    label: qsTr("Due:")
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
                label: qsTr("Repeat:")

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
                text: qsTr("Created: %1").arg(Qt.formatDateTime(new Date(params.creation)).toLocaleString(Qt.locale()))
            }

            SectionHeader {
                //: headline for the tags section
                text: qsTr("Tags")
            }

            ValueButton {
                id: editTags
                //: label for the tags field
                label: qsTr("Tags:")
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
                text: qsTr("Notes")
            }

            TextArea {
                id: notes
                width: parent.width
                //: textfield to enter notes
                placeholderText: qsTr("Enter your notes or description here")
                focus: false
                text: params.notes || ""
            }
        }
    }
}
