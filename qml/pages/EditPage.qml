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
    property string listindex

    // helper function to add lists to the listLocation field
    function appendList(id, listname) {
        listLocationModel.append({"listid": id, "listname": listname})
        if (id === listid) {
            listLocatedIn.currentIndex = listLocationModel.count - 1
        }
    }

    // reload tasklist on activating first page
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            editTaskPage.taskstatus = parseInt(DB.getTaskProperty(listid, taskid, "Status")) === 1 ? true : false
            editTaskPage.taskcreationdate = new Date(DB.getTaskProperty(listid, taskid, "CreationDate"))
        }
    }

    onAccepted: {
        console.log(listLocationModel.get(listLocatedIn.currentIndex).listid)
        var result = DB.updateTask(listid, listLocationModel.get(listLocatedIn.currentIndex).listid, editTaskPage.taskid, taskName.text, taskStatus.checked === true ? 1 : 0, 0, 0)
        // catch sql errors
        if (result !== "ERROR") {
            taskListWindow.listchanged = true
            pageStack.navigateBack()
        }
    }

    Component.onCompleted: {
        DB.readLists()
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
                title: qsTr("Settings") + " - TaskList"
                acceptText: qsTr("Save")
            }

            SectionHeader {
                text: qsTr("Task properties")
            }

            TextField {
                id: taskName
                width: parent.width
                text: editTaskPage.taskname
                focus: true
                label: qsTr("Save changes in the upper right corner")
                // set allowed chars and task length
                validator: RegExpValidator { regExp: /^([^\'|\;|\"]){,30}$/ }
            }

            TextSwitch {
                id: taskStatus
                text: qsTr("task is done")
                checked: taskListWindow.statusOpen(editTaskPage.taskstatus)
            }

            ComboBox {
                id: listLocatedIn
                anchors.left: parent.left
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
                    var changeListID = listLocationModel.get(listLocatedIn.currentIndex).listid
                    if (parseInt(DB.checkTask(changeListID, editTaskPage.taskname)) >= 1) {
                        for (var i = 0; i < listLocationModel.count; i++) {
                            console.log(listLocationModel.get(i).listid)
                            console.log(listid)
                            if (listLocationModel.get(i).listid === listid) {
                                listLocatedIn.currentIndex = 0
                                break
                            }
                        }
                    }
                }
            }

            SectionHeader {
                text: qsTr("Information")
            }

            Label {
                id: taskCreationDate
                anchors.topMargin: 100
                anchors.left: parent.left
                anchors.leftMargin: 25
                text: qsTr("Created at") + ": " + Qt.formatDate(editTaskPage.taskcreationdate, "dd.MM.yyyy") + " - " + Qt.formatDateTime(editTaskPage.taskcreationdate, "HH:mm:ss")
            }
        }
    }
}
