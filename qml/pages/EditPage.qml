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
    property int listid
    property int listindex

    // helper function to add lists to the listLocation field
    function appendList(id, listname) {
        listLocationModel.append({"listid": id, "listname": listname})
        if (id === listid) {
            listindex = listLocationModel.count - 1
        }
    }

    function checkTaskUnique (newListID) {
        return parseInt(DB.checkTask(newListID, taskName.text))
    }

    function checkContent () {
        var changeListID = listLocationModel.get(listLocatedIn.currentIndex).listid
        // if task already exists in target list, display warning
        if (checkTaskUnique(changeListID) >= 1 && changeListID != listid) {
            taskName.errorHighlight = true
            editTaskPage.canAccept = false
            // display notification if task already exists on the selected list
            //: informing the user that a new task already exists on the selected list
            taskListWindow.pushNotification("WARNING", qsTr("Task could not be saved!"), /*: detailed information why the task modifications haven't been saved */ qsTr("It already exists on the selected list."))
        }
        else {
            taskName.errorHighlight = false
            editTaskPage.canAccept = true
        }
    }

    // reload tasklist on activating first page
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            editTaskPage.taskstatus = parseInt(DB.getTaskProperty(taskid, "Status")) === 1 ? true : false
            editTaskPage.taskcreationdate = new Date(DB.getTaskProperty(taskid, "CreationDate"))
        }
    }

    onAccepted: {
        var result = DB.updateTask(editTaskPage.taskid, listLocationModel.get(listLocatedIn.currentIndex).listid,
                                   taskName.text, taskListWindow.statusOpen(taskStatus.checked) ? 1 : 0, 0, 0, 0, "")
        // catch sql errors
        if (result !== "ERROR") {
            taskListWindow.listchanged = true
        }
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
                title: qsTr("Edit") + " '" + editTaskPage.taskname + "'"
                //: save the currently made changes to the task
                acceptText: qsTr("Save")
            }

            SectionHeader {
                //: headline for the section with the task attributes
                text: qsTr("Task properties")
            }

            TextField {
                id: taskName
                width: parent.width
                text: editTaskPage.taskname
                //: information how the currently made changes can be saved
                label: errorHighlight === false ? qsTr("Save changes in the upper right corner") : qsTr("task already exists on this list!")
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
                //: choose if this task is pending or done
                text: qsTr("task is done")
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

            SectionHeader {
                //: headline for the section with information which can not be changed by the user directly
                text: qsTr("Information")
            }

            Label {
                id: taskCreationDate
                anchors.topMargin: 100
                anchors.left: parent.left
                anchors.leftMargin: 25
                //: displays the date when the task has been created by the user
                text: qsTr("Created at") + ": " + Qt.formatDateTime(editTaskPage.taskcreationdate).toLocaleString(Qt.locale())
            }
        }
    }
}
