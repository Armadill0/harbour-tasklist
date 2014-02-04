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

Page {
    id: settingsPage
    allowedOrientations: Orientation.All

    SilicaListView {
        id: settingsContent
        anchors.fill: parent

        VerticalScrollDecorator { flickable: settingsContent }

        PageHeader {
            id: settingsPageHeader
            width: parent.width
            title: qsTr("Settings") + " - TaskList"
        }

        // PullDownMenu
        PullDownMenu {
            MenuItem {
                text: qsTr("Save")
                onClicked: {
                    // update settings in database
                    DB.updateSetting("coverListSelection", coverListSelection.currentIndex)
                    DB.updateSetting("coverListOrder", coverListOrder.currentIndex)
                    DB.updateSetting("taskOpenAppearance", taskOpenAppearance.checked === true ? 1 : 0)
                    /*DB.updateSetting("dateFormat", dateFormat.value)
                    DB.updateSetting("timeFormat", timeFormat.value)*/
                    DB.updateSetting("remorseOnDelete", remorseOnDelete.value)
                    DB.updateSetting("remorseOnMark", remorseOnMark.value)

                    // push new settings to runtime variables
                    taskListWindow.coverListSelection = coverListSelection.currentIndex
                    taskListWindow.coverListOrder = coverListOrder.currentIndex
                    taskListWindow.taskOpenAppearance = taskOpenAppearance.checked === true ? 1 : 0
                    /*taskListWindow.dateFormat = dateFormat.value
                    taskListWindow.timeFormat = timeFormat.value*/
                    taskListWindow.remorseOnDelete = remorseOnDelete.value
                    taskListWindow.remorseOnMark = remorseOnMark.value

                    // change trigger variables to reload list
                    taskListWindow.listchanged = true
                    pageStack.navigateBack()
                }
            }
        }

        Column {
            anchors.top: settingsPageHeader.bottom
            width: parent.width

            SectionHeader {
                text: qsTr("Cover options")
            }

            ComboBox {
                id: coverListSelection
                width: parent.width
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
                label: qsTr("Cover task order") + ":"
                currentIndex: taskListWindow.coverListOrder

                menu: ContextMenu {
                    MenuItem { text: qsTr("Last updated first") }
                    MenuItem { text: qsTr("Sort by name ascending") }
                    MenuItem { text: qsTr("Sort by name descending") }
                }
            }

            SectionHeader {
                text: qsTr("Task options")
            }

            TextSwitch {
                id: taskOpenAppearance
                width: parent.width
                text: qsTr("open task appearance")
                checked: taskListWindow.taskOpenAppearance
            }

            SectionHeader {
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

            /*SectionHeader {
                text: qsTr("Time and Date options")
            }

            ComboBox {
                id: dateFormat
                width: parent.width
                label: qsTr("Date format") + ":"
                currentIndex: taskListWindow.dateFormat

                menu: ContextMenu {
                    MenuItem { text: "default"}
                    MenuItem { text: "dd-MM-yyyy"}
                    MenuItem { text: "dd/MM/yyyy"}
                    MenuItem { text: "yyyy-MM-dd"}
                    MenuItem { text: "yyyy/MM/dd"}
                    MenuItem { text: "MM/dd/yyyy"}
                    MenuItem { text: "MM-dd-yyyy"}
                }
            }

            ComboBox {
                id: timeFormat
                width: parent.width
                label: qsTr("Time format") + ":"
                currentIndex: taskListWindow.timeFormat

                menu: ContextMenu {
                    MenuItem { text: "default" }
                    MenuItem { text: "hh:mm" }
                }
            }*/
        }
    }
}
