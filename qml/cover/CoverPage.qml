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
import "../pages"

CoverBackground {
    id: taskPage

    property int currentList
    property string listorder

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
        switch(taskListWindow.coverListOrder) {
        case 0:
            listorder = ", LastUpdate DESC"
            break
        case 1:
            listorder = ", Task ASC"
            break
        case 2:
            listorder = ", Task DESC"
            break
        }

        wipeTaskList()
        switch(taskListWindow.coverListSelection) {
        case 0:
            currentList = taskListWindow.defaultlist
            break
        case 1:
            currentList = taskListWindow.listid
            break
        case 2:
            currentList = taskListWindow.coverListChoose
            break
        }
        if (taskListWindow.currentCoverList !== -1) {
            currentList = taskListWindow.currentCoverList
        }
        DB.readTasks(currentList, 1, listorder)
    }

    // read all tasks after start
    Component.onCompleted: {
        reloadTaskList()
    }

    onStatusChanged: {
        switch(status) {
        case Cover.Activating:
            // load lists into variable for coveraction "switch"
            taskListWindow.listOfLists = DB.readLists("string")
            var listArray = taskListWindow.listOfLists.split(",")

            // activate ListSwitch Button if more than one list is available or vice versa
            if (listArray.length > 1) {
                coverActionMultiple.enabled = true
                coverActionSingle.enabled = false
            }
            else {
                coverActionMultiple.enabled = false
                coverActionSingle.enabled = true
            }

            // reload tasklist if navigateBack was used from list page
            reloadTaskList()

            break
        }
    }

    ListModel {
        id: taskListModel
    }

    ListView {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall

        Label {
            id: coverHeader
            text: DB.getListProperty(currentList, "ListName")
            width: parent.width - Theme.paddingLarge
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            horizontalAlignment: Text.Center
            color: Theme.highlightColor
        }

        ListView {
            id: taskList
            anchors.top: coverHeader.bottom
            height: 7 * (Theme.fontSizeSmall + Theme.paddingSmall) + 2
            width: parent.width - Theme.paddingSmall
            anchors.horizontalCenter: parent.horizontalCenter
            model: taskListModel

            delegate: Item {
                id: taskListItem
                width: parent.width
                height: taskLabel.height

                Label {
                    id: taskLabel
                    x: Theme.paddingSmall
                    text: task
                    height: font.pixelSize + Theme.paddingSmall
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.fontSizeSmall
                }
            }
        }

        OpacityRampEffect {
            slope: 1
            offset: 0.5
            sourceItem: taskList
        }

        CoverActionList {
            id: coverActionMultiple
            // disabled by default, because first installation comes with only one list
            enabled: false

            CoverAction {
                iconSource: "image://theme/icon-cover-new"
                onTriggered: {
                    taskListWindow.coverAddTask = true
                    // set current global list and jump to taskPage
                    taskListWindow.listid = currentList
                    pageStack.replace("../pages/TaskPage.qml", {}, PageStackAction.Immediate)

                    taskListWindow.activate()
                }
            }

            CoverAction {
                iconSource: "image://theme/icon-cover-next"
                onTriggered: {
                    var listArray = taskListWindow.listOfLists.split(",")

                    for (var i = 0; i < listArray.length; i++) {
                        if (listArray[i] == currentList) {
                            if (i == listArray.length - 1)
                                currentList = listArray[0]
                            else
                                currentList = listArray[i + 1]

                            // wipe list and read new tasks
                            wipeTaskList()
                            DB.readTasks(currentList, 1, listorder)
                            taskListWindow.currentCoverList = currentList

                            break
                        }
                    }
                }
            }
        }

        CoverActionList {
            id: coverActionSingle

            CoverAction {
                iconSource: "image://theme/icon-cover-new"
                onTriggered: {
                    taskListWindow.coverAddTask = true
                    // set current global list and jump to taskPage
                    taskListWindow.listid = currentList
                    pageStack.replace("../pages/TaskPage.qml", {}, PageStackAction.Immediate)

                    taskListWindow.activate()
                }
            }
        }
    }
}


