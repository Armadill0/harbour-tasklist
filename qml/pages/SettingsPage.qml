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
            //% "deactivated"
            result = qsTrId("deactivated-label")
            break
        case 1:
            //: '%1' will be replaced by the amount of seconds of the slider, which is always 1 in this case
            //% "%1 second"
            result = qsTrId("single-second-count-label").arg(time)
            break
        default:
            //: '%1' will be replaced by the amount of seconds of the slider
            //% "%1 seconds"
            result = qsTrId("second-count-label").arg(time)
            break
        }

        return result
    }

    ListModel {
        id: languages
    }

    Component.onCompleted: {
        //: label for a settings "system default" option
        //% "System default"
        languages.append({ lang: "system_default",  name: qsTrId("system-default-label") })
        languages.append({ lang: "ca",              name: "Català" })
        languages.append({ lang: "cs_CZ",           name: "Čeština" })
        languages.append({ lang: "da_DK",           name: "Dansk" })
        languages.append({ lang: "de_DE",           name: "Deutsch" })
        languages.append({ lang: "en_US",           name: "English" })
        languages.append({ lang: "es_ES",           name: "Español" })
        languages.append({ lang: "fi_FI",           name: "Suomi" })
        languages.append({ lang: "fr_FR",           name: "Français" })
        languages.append({ lang: "hu",              name: "Magyar" })
        languages.append({ lang: "it_IT",           name: "Italiano" })
        languages.append({ lang: "ku_IQ",           name: "Kurdî" })
        languages.append({ lang: "lt",              name: "Lietuvių" })
        languages.append({ lang: "nl_NL",           name: "Nederlands" })
        languages.append({ lang: "ru_RU",           name: "Русский" })
        languages.append({ lang: "sv_SE",           name: "Svenska" })
        languages.append({ lang: "tr_TR",           name: "Türkçe"})
        languages.append({ lang: "zh_CN",           name: "中文"})


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
            //% "Other"
            languages.append({ lang: language, name: qsTrId("other-label") })
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
                //% "Settings"
                title: qsTrId("settings-label") + " - TaskList"
                //: saves the current made changes to user options
                //% "Save"
                acceptText: qsTrId("save-button")
            }

            SectionHeader {
                //: headline for cover (application state when app is in background mode) options
                //% "Cover options"
                text: qsTrId("cover-options-header")
            }

            ComboBox {
                id: coverListSelection
                width: parent.width
                //: user option to choose which list should be shown on the cover
                //% "Cover list"
                label: qsTrId("cover-list-label") + ":"
                currentIndex: taskListWindow.coverListSelection

                menu: ContextMenu {
                    //% "Default list"
                    MenuItem { text: qsTrId("default-list-label") }
                    //% "Selected list"
                    MenuItem { text: qsTrId("selected-list-label") }
                    //% "Choose in list management"
                    MenuItem { text: qsTrId("choose-cover-label") }
                }
            }

            ComboBox {
                id: coverListOrder
                width: parent.width
                //: user option to choose how the tasks should be ordered on the cover
                //% "Cover task order"
                label: qsTrId("cover-order-label") + ":"
                currentIndex: taskListWindow.coverListOrder

                menu: ContextMenu {
                    //% "Last updated first"
                    MenuItem { text: qsTrId("last-updated-label") }
                    //% "Sort by name ascending"
                    MenuItem { text: qsTrId("name-asc-label") }
                    //% "Sort by name descending"
                    MenuItem { text: qsTrId("name-desc-label") }
                }
            }

            SectionHeader {
                //: headline for general options
                //% "General options"
                text: qsTrId("general-options-label")
            }

            ComboBox {
                id: languageBox
                width: parent.width
                //% "Language"
                label: qsTrId("language-label") + ":"

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
                x: Theme.paddingLarge
                //% "Language will be changed after app restart."
                text: qsTrId("languagechange-needs-restart-description")
                wrapMode: Text.WordWrap
                visible: false
                font.pixelSize: Theme.fontSizeExtraSmall
                color: Theme.highlightColor
            }

            ComboBox {
                id: startPage
                width: parent.width
                //: user option to choose what should be shown at application start
                //% "Start page"
                label: qsTrId("startpage-label") + ":"
                currentIndex: taskListWindow.startPage

                menu: ContextMenu {
                    //% "Default list"
                    MenuItem { text: qsTrId("default-list-label") }
                    //% "List overview"
                    MenuItem { text: qsTrId("list-overview-label") }
                    //% "Minimize to cover"
                    MenuItem { text: qsTrId("minimize-label") }
                }
            }

            SectionHeader {
                //: headline for task options
                //% "Task options"
                text: qsTrId("task-options-label")
            }

            TextSwitch {
                id: taskOpenAppearance
                width: parent.width
                //: user option to choose whether pending tasks should be marked with a checked or not checked bullet
                //% "open task appearance"
                text: qsTrId("open-task-appearance-label")
                checked: taskListWindow.taskOpenAppearance
            }

            TextSwitch {
                id: backFocusAddTask
                width: parent.width
                //: user option to directly jump back to the input field after a new task has been added by the user
                //% "refocus task add field"
                text: qsTrId("refocus-label")
                checked: taskListWindow.backFocusAddTask
            }


            TextSwitch {
                id: doneTasksStrikedThrough
                width: parent.width
                //: user option to strike through done tasks for better task overview
                //% "strike through done tasks"
                text: qsTrId("strike-through-label")
                checked: taskListWindow.doneTasksStrikedThrough
            }

            SectionHeader {
                //: headline for list options
                //% "List options"
                text: qsTrId("list-options-label")
            }

            TextSwitch {
                id: smartListVisibility
                width: parent.width
                //: user option to decide whether the smart lists (lists which contain tasks with specific attributes, for example new, done and pending tasks)
                //% "show smart lists"
                text: qsTrId("show-smartlists-label")
                checked: taskListWindow.smartListVisibility
            }

            // time periods in seconds are defined in harbour-takslist.qml
            ComboBox {
                id: recentlyAddedOffset
                width: parent.width
                //: user option to select the time period how long tasks are recognized as new
                //% "New task period"
                label: qsTrId("new-task-period-label") + ":"
                currentIndex: taskListWindow.recentlyAddedOffset

                menu: ContextMenu {
                    //: use %1 as a placeholder for the number of hours
                    //% "%1 hours"
                    MenuItem { text: qsTrId("hours-count-label").arg(3) }
                    //% "%1 hours"
                    MenuItem { text: qsTrId("hours-count-label").arg(6) }
                    //% "%1 hours"
                    MenuItem { text: qsTrId("hours-count-label").arg(12) }
                    //: use %1 as a placeholder for the number of the day, which is currently static "1"
                    //% "%1 day"
                    MenuItem { text: qsTrId("single-day-count-label").arg(1) }
                    //: use %1 as a placeholder for the number of days
                    //% "%1 days"
                    MenuItem { text: qsTrId("day-count-label").arg(2) }
                    //: use %1 as a placeholder for the number of the week, which is currently static "1"
                    //% "%1 week"
                    MenuItem { text: qsTrId("single-week-count-label").arg(1) }
                }
            }

            SectionHeader {
                //: headline for remorse (a Sailfish specific interaction element to stop a former started process) options
                //% "Remorse options"
                text: qsTrId("remorse-options-label")
            }

            Slider {
                id: remorseOnDelete
                width: parent.width
                //% "on Delete"
                label: qsTrId("remorse-delete-label")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnDelete
                valueText: composeRemorseSliderText(value)
            }

            Slider {
                id: remorseOnMark
                width: parent.width
                //% "on Mark task"
                label: qsTrId("remorse-mark-label")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMark
                valueText: composeRemorseSliderText(value)
            }

            Slider {
                id: remorseOnMultiAdd
                width: parent.width
                //% "on Adding multiple tasks"
                label: qsTrId("remorse-addmultiple-label")
                minimumValue: 0
                maximumValue: 10
                stepSize: 1
                value: taskListWindow.remorseOnMultiAdd
                valueText: composeRemorseSliderText(value)
            }

            SectionHeader {
                //: headline for Dropbox options
                //% "Dropbox options"
                text: qsTrId("dropbox-options-label")
            }

            Button {
                id: signOutDropbox
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: taskListWindow.checkDropboxCredentials()
                //: Button to log out from the dropbox account
                //% "Dropbox log out"
                text: qsTrId("dropbox-logout-label")
                onClicked: {
                    taskListWindow.removeDropboxCredentials()
                    signOutDropbox.enabled = false
                }
            }
        }
    }
}
