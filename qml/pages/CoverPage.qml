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
import "../pages"

CoverBackground {
    id: taskPage

    property int currentList
    property string listorder

    // helper function to add tasks to the list,
    //  two last arguments are to match the callback signature
    function appendTask(id, task, status, listid, due, prio) {
        taskListModel.append({ taskid: id, task: task, taskstatus: status })
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
        DB.readTasks(currentList, appendTask, 1, listorder)
        // also change list in application
        taskListWindow.listid = currentList
    }

    // read all tasks after start
    Component.onCompleted: {
        reloadTaskList()
    }

    onStatusChanged: {
        switch(status) {
        case Cover.Activating:
            taskListWindow.fillListOfLists()

            if (taskListWindow.smartListType !== -1) {
                taskListWindow.smartListType = -1
                taskListWindow.needListModelReload = true
            }

            // reload tasklist if navigateBack was used from list page
            reloadTaskList()

            break
        }
    }

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

    ListModel {
        id: taskListModel
    }

    Rectangle {
        anchors.fill: parent
        anchors.margins: Theme.paddingSmall * 2
        color: "transparent"

        Label {
            id: coverHeader
            text: DB.getListName(currentList) + "(" + taskListModel.count + ")"
            width: parent.width
            horizontalAlignment: Text.AlignLeft
            color: Theme.highlightColor
            truncationMode: TruncationMode.Fade
        }

        ListView {
            id: taskList
            anchors.top: coverHeader.bottom
            height: 7 * (Theme.fontSizeSmall + Theme.paddingSmall) + (Theme.paddingSmall / 3)
            width: parent.width
            model: taskListModel
            clip: true

            delegate: Item {
                id: taskListItem
                width: parent.width
                height: taskLabel.height

                Label {
                    id: taskLabel
                    text: task
                    width: parent.width
                    height: font.pixelSize + Theme.paddingSmall
                    font.pixelSize: Theme.fontSizeSmall
                    truncationMode: TruncationMode.Fade
                }
            }
        }

        CoverActionList {
            id: coverActionMultiple
            // disabled by default, because first installation comes with only one list
            enabled: taskListWindow.coverActionMultiple

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
                    var index = (listOfLists.indexOf(currentList) + 1) % listOfLists.length
                    currentList = listOfLists[index]
                    // wipe list and read new tasks
                    wipeTaskList()
                    DB.readTasks(currentList, appendTask, 1, listorder)
                    currentCoverList = currentList
                    // also change list in application
                    taskListWindow.listid = currentList
                }
            }
        }

        CoverActionList {
            id: coverActionSingle
            enabled: taskListWindow.coverActionSingle

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


