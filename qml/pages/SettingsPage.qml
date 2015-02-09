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
    id: settingsPage
    allowedOrientations: Orientation.All
    canAccept: true

    onAccepted: {
        // update settings in database
        DB.updateSetting("coverListSelection", coverListSelection.currentIndex)
        DB.updateSetting("coverListOrder", coverListOrder.currentIndex)
        DB.updateSetting("taskOpenAppearance", taskOpenAppearance.checked === true ? 1 : 0)
        DB.updateSetting("backFocusAddTask", backFocusAddTask.checked === true ? 1 : 0)
        DB.updateSetting("remorseOnDelete", remorseOnDelete.value)
        DB.updateSetting("remorseOnMark", remorseOnMark.value)
        DB.updateSetting("remorseOnMultiAdd", remorseOnMultiAdd.value)
        DB.updateSetting("startPage", startPage.currentIndex)
        DB.updateSetting("smartListVisibility", smartListVisibility.checked === true ? 1 : 0)
        DB.updateSetting("recentlyAddedOffset", recentlyAddedOffset.currentIndex)
        DB.updateSetting("doneTasksStrikedThrough", doneTasksStrikedThrough.checked === true ? 1 : 0)


        // push new settings to runtime variables
        taskListWindow.coverListSelection = coverListSelection.currentIndex
        taskListWindow.coverListOrder = coverListOrder.currentIndex
        taskListWindow.taskOpenAppearance = taskOpenAppearance.checked === true ? 1 : 0
        taskListWindow.backFocusAddTask = backFocusAddTask.checked === true? 1 : 0
        taskListWindow.remorseOnDelete = remorseOnDelete.value
        taskListWindow.remorseOnMark = remorseOnMark.value
        taskListWindow.remorseOnMultiAdd = remorseOnMultiAdd.value
        taskListWindow.smartListVisibility = smartListVisibility.checked === true ? 1 : 0
        taskListWindow.recentlyAddedOffset = recentlyAddedOffset.currentIndex
        taskListWindow.doneTasksStrikedThrough = doneTasksStrikedThrough.checked === true ? 1 : 0
    }

    SilicaFlickable {
        id: settingsList
        anchors.fill: parent
        contentHeight: settingsColumn.height

        VerticalScrollDecorator { flickable: settingsList }

        Column {
            id: settingsColumn
            width: parent.width

            DialogHeader {
                //: headline for all user options
                title: qsTr("Settings") + " - TaskList"
                //: saves the current made changes to user options
                acceptText: qsTr("Save")
            }

            SectionHeader {
                //: headline for cover (application state when app is in background mode) options
                text: qsTr("Cover options")
            }

            ComboBox {
                id: coverListSelection
                width: parent.width
                //: user option to choose which list should be shown on the cover
                label: qsTr("Cover list") + ":"
                currentIndex: taskListWindow.coverListSelection

                menu: ContextMenu {
                    MenuItem { text: qsTr("Default list") }
                    MenuItem { text: qsTr("Selected list") }
                    MenuItem { text: qsTr("Choose in list management") }
                }
            }

            ComboBox {
                id: coverListOrder
                width: parent.width
                //: user option to choose how the tasks should be ordered on the cover
                label: qsTr("Cover task order") + ":"
                currentIndex: taskListWindow.coverListOrder

                menu: ContextMenu {
                    MenuItem { text: qsTr("Last updated first") }
                    MenuItem { text: qsTr("Sort by name ascending") }
                    MenuItem { text: qsTr("Sort by name descending") }
                }
            }

            SectionHeader {
                //: headline for general options
                text: qsTr("General options")
            }

            ComboBox {
                id: startPage
                width: parent.width
                //: user option to choose what should be shown at application start
                label: qsTr("Start page") + ":"
                currentIndex: taskListWindow.startPage

                menu: ContextMenu {
                    MenuItem { text: qsTr("Default list") }
                    MenuItem { text: qsTr("List overview") }
                    MenuItem { text: qsTr("Minimize to cover") }
                }
            }

            SectionHeader {
                //: headline for task options
                text: qsTr("Task options")
            }

            TextSwitch {
                id: taskOpenAppearance
                width: parent.width
                //: user option to choose whether pending tasks should be marked with a checked or not checked bullet
                text: qsTr("open task appearance")
                checked: taskListWindow.taskOpenAppearance
            }

            TextSwitch {
                id: backFocusAddTask
                width: parent.width
                //: user option to directly jump back to the input field after a new task has been added by the user
                text: qsTr("refocus task add field")
                checked: taskListWindow.backFocusAddTask
            }


            TextSwitch {
                id: doneTasksStrikedThrough
                width: parent.width
                //: user option to strike through done tasks for better task overview
                text: qsTr("strike through done tasks")
                checked: taskListWindow.doneTasksStrikedThrough
            }

            SectionHeader {
                //: headline for list options
                text: qsTr("List options")
            }

            TextSwitch {
                id: smartListVisibility
                width: parent.width
                //: user option to decide whether the smart lists (lists which contain tasks with specific attributes, for example new, done and pending tasks)
                text: qsTr("show smart lists")
                checked: taskListWindow.smartListVisibility
            }

            // time periods in seconds are defined in harbour-takslist.qml
            ComboBox {
                id: recentlyAddedOffset
                width: parent.width
                //: user option to select the time period how long tasks are recognized as new
                label: qsTr("New task period") + ":"
                currentIndex: taskListWindow.recentlyAddedOffset

                menu: ContextMenu {
                    //: use %1 as a placeholder for the number of hours
                    MenuItem { text: qsTr("%1 hours").arg(3) }
                    MenuItem { text: qsTr("%1 hours").arg(6) }
                    MenuItem { text: qsTr("%1 hours").arg(12) }
                    //: use %1 as a placeholder for the number of the day, which is currently static "1"
                    MenuItem { text: qsTr("%1 day").arg(1) }
                    //: use %1 as a placeholder for the number of days
                    MenuItem { text: qsTr("%1 days").arg(2) }
                    //: use %1 as a placeholder for the number of the week, which is currently static "1"
                    MenuItem { text: qsTr("%1 week").arg(1) }
                }
            }

            SectionHeader {
                //: headline for remorse (a Sailfish specific interaction element to stop a former started process) options
                text: qsTr("Remorse options")
            }

            Slider {
                id: remorseOnDelete
                width: parent.width
                label: qsTr("on Delete")
                minimumValue: 1
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnDelete
                valueText: value + " " + ((value > 1) ? qsTr("seconds") : qsTr("second"))
            }

            Slider {
                id: remorseOnMark
                width: parent.width
                label: qsTr("on Mark task")
                minimumValue: 1
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMark
                valueText: value + " " + ((value > 1) ? qsTr("seconds") : qsTr("second"))
            }

            Slider {
                id: remorseOnMultiAdd
                width: parent.width
                label: qsTr("on Adding multiple tasks")
                minimumValue: 1
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMultiAdd
                valueText: value + " " + ((value > 1) ? qsTr("seconds") : qsTr("second"))
            }
        }
    }
}
