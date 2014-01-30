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

CoverBackground {
    id: taskPage

    BackgroundItem {
        anchors.fill: parent

        Image {
            id: coverBgImage
            anchors.fill: parent
            fillMode: Image.PreserveAspectFit
            source: "../images/coverbg.png"
            opacity: 0.2
            horizontalAlignment: Image.AlignHCenter
            verticalAlignment: Image.AlignVCenter
        }
    }

    // helper function to add tasks to the list
    function appendTask(id, task, status) {
        taskListModel.append({"taskid": id, "task": task, "taskstatus": status})
    }

    // helper function to wipe the tasklist element
    function wipeTaskList() {
        taskListModel.clear()
    }

    function reloadTaskList() {
        wipeTaskList()
        DB.readTasks(listid, 1);
    }

    // read all tasks after start
    Component.onCompleted: {
        reloadTaskList()
    }

    onStatusChanged: {
        reloadTaskList()
    }

    ListModel {
        id: taskListModel
    }

    ListView {
        anchors.fill: parent
        Label {
            id: coverHeader
            text: listname
            width: parent.width
            anchors.top: parent.top
            horizontalAlignment: Text.Center
            //color: Theme.secondaryColor
        }

        ListView {
            id: taskList
            anchors.top: coverHeader.bottom
            anchors.bottom: parent.bottom
            width: parent.width
            model: taskListModel

            // show playholder if there are no tasks available
            ViewPlaceholder {
                enabled: taskList.count === 0
                text: "no tasks available"
            }

            delegate: Row {
                id: taskListItem
                width: parent.width

                BackgroundItem {
                    id: taskContainerItem
                    width: parent.width
                    height: 32

                    Label {
                        id: taskLabel
                        x: Theme.paddingSmall
                        text: task
                        height: parent.height
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeSmall
                    }
                }
            }
        }

        OpacityRampEffect {
            slope: 1.5
            offset: 0.35
            sourceItem: taskList
        }

        CoverActionList {
            id: coverAction

            CoverAction {
                iconSource: "image://theme/icon-cover-new"
                onTriggered: {
                    taskListWindow.coverAddTask = true
                    taskListWindow.activate()
                    pageStack.replace(Qt.resolvedUrl("../pages/TaskPage.qml"), {}, PageStackAction.Immediate)
                }
            }

            // not needed atm
            /*CoverAction {
            iconSource: "image://theme/icon-cover-sync"
            onTriggered: {
                taskListWindow.activate()
            }*/
        }
    }
}


