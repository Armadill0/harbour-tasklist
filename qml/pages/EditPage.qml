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

Page {
    id: editTaskPage
    allowedOrientations: Orientation.All

    property string taskname
    property string taskid
    property int taskstatus
    property string taskcreationdate
    property string listindex

    // reload tasklist on activating first page
    onStatusChanged: {
        if (status === PageStatus.Activating) {
            editTaskPage.taskstatus = DB.getTaskProperty(listid, taskid, "Status")
            editTaskPage.taskcreationdate = new Date(DB.getTaskProperty(listid, taskid, "CreationDate"))
        }
    }

    SilicaListView {
        id: editTaskList
        anchors.fill: parent
        anchors.left: parent.left
        PageHeader {
            id: editTaskHeader
            title: "Edit - TaskList"
        }

        VerticalScrollDecorator {}

        // PullDownMenu
        PullDownMenu {
            MenuItem {
                text: "Save"
                onClicked: {
                    var result = DB.updateTask(listid, editTaskPage.taskid, taskName.text, (taskStatus.checked === true) ? 1 : 0, 0, 0)
                    // catch sql errors
                    if (result !== "ERROR_DUPLICATE_ENTRY") {
                        taskListWindow.listchanged = true
                        pageStack.navigateBack()
                    }
                }
            }
        }

        TextField {
            id: taskName
            width: parent.width
            text: editTaskPage.taskname
            focus: true
            anchors.top: editTaskHeader.bottom
            anchors.topMargin: 20

            // set allowed chars and task length
            validator: RegExpValidator { regExp: /^([^(\'|\;|\")]){,30}$/ }
        }

        TextSwitch {
            id: taskStatus
            text: "task is done"
            anchors.top: taskName.bottom
            checked: (editTaskPage.taskstatus === 1) ? true : false
        }

        Label {
            id: taskCreationDate
            anchors.top: taskStatus.bottom
            anchors.topMargin: 100
            anchors.left: parent.left
            anchors.leftMargin: 20
            text: "Created at: " + Qt.formatDate(editTaskPage.taskcreationdate, "dd.MMMM.yyyy") + " " + Qt.formatDateTime(editTaskPage.taskcreationdate, "HH:mm:ss")
        }
    }
}
