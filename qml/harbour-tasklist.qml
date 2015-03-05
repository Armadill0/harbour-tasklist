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

import QtQuick 2.0
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
    // define names of smart lists
    //: names of the auotomatic smart lists (lists which contain tasks with specific attributes, for example new, done and pending tasks)
    property variant smartListNames: [qsTr("Done"), qsTr("Pending"), qsTr("New")]

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

    initialPage: Component { TaskPage {} }
    cover: Component { CoverPage {} }

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
