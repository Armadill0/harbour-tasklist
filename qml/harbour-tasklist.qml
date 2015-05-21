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
import "pages"
import "cover"
import "localdb.js" as DB
import harbour.tasklist.notifications 1.0

ApplicationWindow {
    id: taskListWindow

    // set current list
    property int listid
    // save defaultlist in a global context
    property int defaultlist
    // helper variable to reload list on list name or task name changes
    property bool listchanged: false
    // helper varable for adding directly through coveraction
    property bool coverAddTask: false
    // helper varable to lock task Page Orientation
    property bool lockTaskOrientation: false
    // indicator variable when app just started
    property bool justStarted: true
    // a variable to trigger the switch of tha start page
    property bool switchStartPage: true
    // variable to save the list of lists as a string
    property string listOfLists
    // variable to save the current cover list as a variable which overlives changing from Dovers screen to lock screen and back
    property int currentCoverList: -1
    // list of current time periods in seconds for the "recently added tasks" smart list
    property variant recentlyAddedPeriods: [10800, 21600, 43200, 86400, 172800, 604800]
    // deactivate smart lists at startup
    property int smartListType: -1
    // specify tag if the smart list of tagged tasks is selected
    property int tagId
    // define names of smart lists
    //: names of the automatic smart lists (lists which contain tasks with specific attributes, for example new, done and pending tasks)
    property variant smartListNames: [qsTr("Done"), qsTr("Pending"), qsTr("New"), qsTr("Today"), qsTr("Tomorrow"), qsTr("Tags")]
    // set default priorities
    property int minimumPriority: 1
    property int defaultPriority: 3
    property int maximumPriority: 5

    // initilize default settings properties
    property int coverListSelection
    property int coverListChoose
    property int coverListOrder
    property bool taskOpenAppearance
    property int remorseOnDelete
    property int remorseOnMark
    property int remorseOnMultiAdd
    property int startPage
    property int backFocusAddTask
    property bool smartListVisibility
    property int recentlyAddedOffset
    property bool doneTasksStrikedThrough

    initialPage: DB.schemaIsUpToDate() ? initialTaskPage : migrateConfirmation
    cover: Component { CoverPage {} }

    Component {
        id: initialTaskPage
        TaskPage { }
    }

    Component {
        id: migrateConfirmation
        Dialog {
            Column {
                width: parent.width
                spacing: Theme.paddingLarge
                DialogHeader {
                    //: Stop database upgrade dialog
                    acceptText: qsTr("Exit")
                }
                Label {
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: get user's attention before starting database upgrade
                    text: qsTr("ATTENTION")
                    font.pixelSize: Theme.fontSizeMedium
                }
                Label {
                    width: parent.width - 2 * Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                    font.italic: true
                    //: upgrade description
                    text: qsTr("A database from a previous version of TaskList has been found. Old databases are not supported. You can delete the database or try to upgrade the data (result is not guaranteed).")
                    wrapMode: Text.WordWrap
                }
                Label {
                    width: parent.width - 2 * Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    //: user has the possibility to choose the database upgrade or delete the old database
                    text: qsTr("Please select an action to proceed.")
                    wrapMode: Text.WordWrap
                }
                Row {
                    spacing: Theme.paddingLarge
                    anchors.horizontalCenter: parent.horizontalCenter
                    Button {
                        //: delete old database option
                        text: qsTr("Delete")
                        onClicked: {
                            if (DB.replaceOldDB())
                                pageStack.replace(initialTaskPage)
                            else
                                Qt.quit()
                        }
                    }
                    Button {
                        //: upgrade database option
                        text: qsTr("Upgrade")
                        onClicked: {
                            if (DB.replaceOldDB(true))
                                pageStack.replace(initialTaskPage)
                            else
                                Qt.quit()
                        }
                    }
                }
            }
            onAccepted: Qt.quit()
        }
    }

    // a function to check which appearance should be used by open tasks
    function statusOpen(a) { return a === taskListWindow.taskOpenAppearance }

    // notification function
    function pushNotification(notificationType, notificationSummary, notificationBody) {
        var notificationCategory
        switch(notificationType) {
        case "INFO":
            notificationCategory = "x-jolla.lipstick.credentials.needUpdate.notification"
            break
        case "WARNING":
            notificationCategory = "x-jolla.store.error"
            break
        case "ERROR":
            notificationCategory = "x-jolla.store.error"
            break
        }

        notification.category = notificationCategory
        notification.previewSummary = notificationSummary
        notification.previewBody = notificationBody
        notification.publish()
    }

    Notification {
        id: notification
        category: "x-nemo.email.error"
        itemCount: 1
    }

    onApplicationActiveChanged: {
        if (applicationActive === true) {
            // reset currentCoverList to default (-1)
            taskListWindow.currentCoverList = -1
        }
    }
}
