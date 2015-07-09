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

    property string language: ""

    // function to compose the remorse action slider's text description
    function composeRemorseSliderText(time) {
        var result = ""
        switch (time) {
        case 0:
            //: text to be shown if the slider is set to
            result = qsTr("deactivated")
            break
        case 1:
            //: '%1' will be replaced by the amount of seconds of the slider, which is always 1 in this case
            result = qsTr("%1 second").arg(time)
            break
        default:
            //: '%1' will be replaced by the amount of seconds of the slider
            result = qsTr("%1 seconds").arg(time)
            break
        }

        return result
    }

    ListModel {
        id: languages
    }

    Component.onCompleted: {
        languages.append({ lang: "ca",    name: "Català" })
        languages.append({ lang: "cs_CZ", name: "Čeština" })
        languages.append({ lang: "da_DK", name: "Dansk" })
        languages.append({ lang: "de_DE", name: "Deutsch" })
        languages.append({ lang: "en_EN", name: "English" })
        languages.append({ lang: "es_ES", name: "Español" })
        languages.append({ lang: "fi_FI", name: "Suomi" })
        languages.append({ lang: "fr_FR", name: "Français" })
        languages.append({ lang: "it_IT", name: "Italiano" })
        languages.append({ lang: "ku_IQ", name: "Kurdî" })
        languages.append({ lang: "lt",    name: "Lietuvių" })
        languages.append({ lang: "nl_NL", name: "Nederlands" })
        languages.append({ lang: "ru_RU", name: "Русский" })
        languages.append({ lang: "sv_SE", name: "Svenska" })
        languages.append({ lang: "tr_TR", name: "Türkçe"})
        // keine Ahnung was das ist :-)
        languages.append({ lang: "zh_CN", name: "中文"})


        language = taskListWindow.getLanguage()
        var found = false
        for (var i = 0; i < languages.count; ++i) {
            var item = languages.get(i)
            if (item.lang === language) {
                languageBox.currentIndex = i
                languageBox.currentItem = languageBox.menu.children[languageBox.currentIndex]
                found = true
                break
            }
        }
        if (!found) {
            languages.append({ lang: language, name: qsTr("Other") })
            languageBox.currentIndex = languages.count - 1
            languageBox.currentItem = languageBox.menu.children[languageBox.currentIndex]
        }
    }

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

        var langId = languageBox.currentIndex
        if (0 <= langId && langId < languages.count) {
            var lang = languages.get(langId).lang
            if (lang !== language)
                taskListWindow.setLanguage(lang)
        }
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

            ComboBox {
                id: languageBox
                width: parent.width
                label: qsTr("Language") + ":"

                menu: ContextMenu {
                    Repeater {
                        model: languages
                        MenuItem {
                            text: model.name
                        }
                    }
                }

                onCurrentIndexChanged: {
                    languageTip.visible = language !== languages.get(currentIndex).lang
                }
            }

            Label {
                id: languageTip
                width: parent.width
                text: qsTr("Language will be changed after app restart")
                visible: false
                font.pixelSize: Theme.fontSizeExtraSmall
                horizontalAlignment: Text.AlignHCenter
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
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnDelete
                valueText: composeRemorseSliderText(value)
            }

            Slider {
                id: remorseOnMark
                width: parent.width
                label: qsTr("on Mark task")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMark
                valueText: composeRemorseSliderText(value)
            }

            Slider {
                id: remorseOnMultiAdd
                width: parent.width
                label: qsTr("on Adding multiple tasks")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMultiAdd
                valueText: composeRemorseSliderText(value)
            }

            SectionHeader {
                //: headline for Dropbox options
                text: qsTr("Dropbox options")
            }

            Button {
                id: signOutDropbox
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: taskListWindow.checkDropboxCredentials()
                //: Button to log out from the dropbox account
                text: qsTr("Dropbox log out")
                onClicked: {
                    taskListWindow.removeDropboxCredentials()
                    signOutDropbox.enabled = false
                }
            }
        }
    }
}
