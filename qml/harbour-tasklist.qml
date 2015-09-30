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
import org.nemomobile.notifications 1.0
import "pages"
import "pages/sync"
import "localdb.js" as DB
import harbour.tasklist.tasks_export 1.0

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
    property var listOfLists: []
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
    property variant smartListNames: [
        //% "Done"
        qsTrId("done-label"),
        //% "Pending"
        qsTrId("pending-label"),
        //% "New"
        qsTrId("new-label"),
        //% "Today"
        qsTrId("today-label"),
        //% "Tomorrow"
        qsTrId("tomorrow-label"),
        //% "Tags"
        qsTrId("tags-label")
    ]
    // set default priorities
    property int minimumPriority: 1
    property int defaultPriority: 3
    property int maximumPriority: 5

    property bool coverActionMultiple: listOfLists.length > 1
    property bool coverActionSingle: !coverActionMultiple

    // initialize default settings properties
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
            allowedOrientations: Orientation.All
            //: text of the button to migrate the old to the new database format
            //% "Upgrade"
            property string dbUpgradeText: qsTrId("upgrade-label")
            //: text of the button to delete the old database and start overleo
            //% "Delete"
            property string dbDeleteText: qsTrId("delete-label")

            SilicaFlickable {
                id: migrateFlickable
                anchors.fill: parent
                contentHeight: migrateColumn.height

                VerticalScrollDecorator { flickable: migrateFlickable }

                Column {
                    id: migrateColumn
                    width: parent.width

                    DialogHeader {
                        //: Stop database upgrade dialog
                        //% "Exit"
                        acceptText: qsTrId("exit-label")
                        //: get user's attention before starting database upgrade
                        //% "Action required"
                        title: qsTrId("upgradedialog-header")
                    }

                    SectionHeader {
                        //: headline for the informational upgrade dialog part
                        //% "Information"
                        text: qsTrId("information-label")
                    }

                    Label {
                        width: parent.width - 2 * Theme.paddingLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                        //: first part of the database upgrade description
                        //% "A database from a previous version of TaskList has been found. Old databases are not supported."
                        text: qsTrId("upgrade-description-part1") + "\n" +
                              //: second part of the database upgrade description; %1 and %2 are the placeholders for the 'Upgrade' and 'Delete' options of the upgrade Dialog
                              //% " Press '%1' to migrate the old database into the new format or '%2' to delete the old database and start with a clean new database."
                              qsTrId("upgrade-description-part2").arg(dbUpgradeText).arg(dbDeleteText)
                        wrapMode: Text.WordWrap
                        color: Theme.highlightColor
                        font.bold: true
                    }

                    SectionHeader {
                        //: headline for the option section of the upgrade dialog
                        //% "Choose an option"
                        text: qsTrId("option-header")
                    }

                    Label {
                        width: parent.width - 2 * Theme.paddingLarge
                        anchors.horizontalCenter: parent.horizontalCenter
                        //: user has the possibility to choose the database upgrade or delete the old database
                        //% "Please select an action to proceed."
                        text: qsTrId("choose-option-label")
                        wrapMode: Text.WordWrap
                    }

                    Rectangle {
                        width: parent.width
                        height: Theme.paddingLarge
                        color: "transparent"
                    }

                    Row {
                        width: parent.width

                        Button {
                            width: parent.width
                            //: hint which is the recommended upgrade option
                            //% "recommended"
                            text: dbUpgradeText + " (" + qsTrId("recommended-label") + ")"
                            onClicked: {
                                if (DB.replaceOldDB(true))
                                    pageStack.replace(initialTaskPage)
                                else
                                    Qt.quit()
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width
                        height: Theme.paddingLarge
                        color: "transparent"
                    }

                    Row {
                        anchors.horizontalCenter: parent.horizontalCenter

                        Button {
                            //: delete old database option
                            text: dbDeleteText
                            onClicked: {
                                if (DB.replaceOldDB())
                                    pageStack.replace(initialTaskPage)
                                else
                                    Qt.quit()
                            }
                        }
                    }
                }
            }

            onAccepted: Qt.quit()
        }
    }

    // a function to check which appearance should be used by open tasks
    function statusOpen(a) { return a === taskOpenAppearance }

    // a function to fill litoflists with data
    function fillListOfLists () {
        // load lists into variable for "switch" action on cover and task page
        listOfLists = DB.allLists()
    }

    // short human-readable representation of a due date
    function humanReadableDueDate(unixTime) {
        var date = new Date(unixTime);
        var today = new Date();
        var tomorrow = new Date(today.getTime() + DB.DAY_LENGTH);
        var yesterday = new Date(today.getTime() - DB.DAY_LENGTH);

        var dateString = date.toDateString();
        if (dateString === today.toDateString())
            //: due date string for today
            //% "Today"
            return qsTrId("today-label");
        if (dateString === tomorrow.toDateString())
            //: due date string for tomorrow
            //% "Tomorrow"
            return qsTrId("tomorrow-label");
        if (dateString === yesterday.toDateString())
            //: due date string for yesterday
            //% "Yesterday"
            return qsTrId("yesterday-label");

        return date.toLocaleDateString(Qt.locale(), Locale.ShortFormat);
    }

    TasksExport {
        id: exporter
    }

    // generate URL to grant access for app at Dropbox
    function dropboxAuthorizeLink() {
        return exporter.dropboxAuthorizeLink()
    }

    // after being authorized the app will try to get OAuth credentials and save them in DB
    function getDropboxCredentials() {
        var list = exporter.getDropboxCredentials()
        if (list.length < 3) {
            //% "Cannot access Dropbox"
            pushNotification("ERROR", qsTrId("dropbox-no-access-error"),
                             //% "Unable to fetch credentials from Dropbox."
                             qsTrId("dropbox-no-access-error-details"))
            return false
        }
        var values = { dropboxUsername: list[0], dropboxTokenSecret: list[1], dropboxToken: list[2] }
        if (!DB.upsertDropboxCredentials(values)) {
            //% "DB error"
            pushNotification("ERROR", qsTrId("database-error"),
                             //% "Unable to save credentials in database."
                             qsTrId("credential-save-error"))
            return false
        }
        return true
    }

    // remove Dropbox keys from DB
    function removeDropboxCredentials() {
        DB.removeDropboxCredentials()
    }

    // check presense
    function checkDropboxCredentials() {
        var values = DB.getDropboxCredentials()
        return typeof values.dropboxToken !== "undefined" && typeof values.dropboxTokenSecret !== "undefined"
    }

    // set credentials from DB if app was authorized earlier
    function setDropboxCredentials() {
        var values = DB.getDropboxCredentials()
        if (typeof values.dropboxToken === "undefined" || typeof values.dropboxTokenSecret === "undefined")
            return false
        exporter.setDropboxCredentials(values.dropboxToken, values.dropboxTokenSecret)
        return true
    }

    function getRemoteRevision() {
        var ret = exporter.getRevision()
        if (ret === "")
            ret = undefined
        return ret
    }

    function lastSyncRevision() {
        return DB.getSetting("lastSyncRevisionHash")
    }

    function uploadData() {
        var json = DB.dumpData()
        console.log("Dump is composed")
        var ret = exporter.uploadToDropbox(json)
        console.log("uploaded revision " + ret)
        if (ret === "") {
            //% "Sync failed"
            pushNotification("ERROR", qsTrId("sync-failed-error"),
                             //% "Unable to upload data to Dropbox."
                             qsTrId("upload-failed-error"))
            return false
        }
        DB.upsertSetting("lastSyncRevisionHash", ret)
        //% "Sync finished"
        pushNotification("OK", qsTrId("sync-success"),
                         //% "Data successfully uploaded to Dropbox."
                         qsTrId("data-upload-success"))
        return true
    }

    function downloadData() {
        var list = exporter.downloadFromDropbox()
        var rev = list[0], json = list[1]
        console.log("downloaded revision " + rev)
        if (typeof rev === "undefined" || typeof json === "undefined" || json === "") {
            //% "Sync failed"
            pushNotification("ERROR", qsTrId("sync-failed-error"),
                             //% "Invalid data received."
                             qsTrId("invalid-data-error"))
            return false
        }
        if (!DB.importData(json)) {
            //% "Sync failed"
            pushNotification("ERROR", qsTrId("sync-failed-error"),
                             //% "Data cannot be imported."
                             qsTrId("import-failed-error"))
            return false
        }
        DB.upsertSetting("lastSyncRevisionHash", rev)
        //% "Sync finished"
        pushNotification("OK", qsTrId("sync-success"),
                         //% "Data successfully downloaded from Dropbox."
                         qsTrId("data-download-success"))
        return true
    }

    function getLanguage() {
        return exporter.language
    }

    function setLanguage(lang) {
        exporter.language = lang
    }

    // notification function
    function pushNotification(notificationType, notificationSummary, notificationBody) {
        var notificationIcon
        switch(notificationType) {
        case "OK":
            notificationIcon = "icon-lock-installed"
            break
        case "INFO":
            notificationIcon = "icon-lock-information"
            break
        case "WARNING":
            notificationIcon = "icon-lock-warning"
            break
        case "ERROR":
            notificationIcon = "icon-lock-warning"
            break
        }

        notification.appIcon = notificationIcon
        notification.previewSummary = notificationSummary
        notification.previewBody = notificationBody
        notification.publish()
    }

    function initializeApplication() {
        DB.initializeDB()
        listid = DB.getSettingAsNumber("defaultList")
        defaultlist = listid
        justStarted = false

        // initialize application settings
        coverListSelection = DB.getSettingAsNumber("coverListSelection")
        coverListChoose = DB.getSettingAsNumber("coverListChoose")
        coverListOrder = DB.getSettingAsNumber("coverListOrder")
        taskOpenAppearance = DB.getSettingAsNumber("taskOpenAppearance") === 1
        remorseOnDelete = DB.getSettingAsNumber("remorseOnDelete")
        remorseOnMark = DB.getSettingAsNumber("remorseOnMark")
        remorseOnMultiAdd = DB.getSettingAsNumber("remorseOnMultiAdd")
        startPage = DB.getSettingAsNumber("startPage")
        backFocusAddTask = DB.getSettingAsNumber("backFocusAddTask")
        smartListVisibility = DB.getSettingAsNumber("smartListVisibility") === 1
        recentlyAddedOffset = DB.getSettingAsNumber("recentlyAddedOffset")
        doneTasksStrikedThrough = DB.getSettingAsNumber("doneTasksStrikedThrough") === 1
    }

    Notification {
        id: notification
        appName: appname
        appIcon: "icon-lock-warning"
        itemCount: 1
    }

    onApplicationActiveChanged: {
        if (applicationActive === true) {
            // reset currentCoverList to default (-1)
            currentCoverList = -1
        }
    }
}
