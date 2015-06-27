/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Murat Khairulin

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
import ".."

Page {
    id: dropboxSync
    allowedOrientations: Orientation.All

    property bool attemptedAuth

    Column {
        id: column
        spacing: Theme.itemSizeSmall
        width: parent.width

        PageHeader { title: qsTr("Sync with Dropbox") }

        BusyIndicator {
            id: indicator
            running: true
            size: BusyIndicatorSize.Large
            anchors.horizontalCenter: parent.horizontalCenter
        }

        Label {
            id: label
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
            }
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
            visible: false
            text: qsTr("Remote copy cannot be updated. Please choose action:")
        }

        Button {
            id: replaceRemote
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Replace remote copy")
            visible: false
            onClicked: upload()
        }

        Button {
            id: replaceLocal
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Replace local copy")
            visible: false
            onClicked: download()
        }
    }

    function toggleElements(busy) {
        indicator.running = busy
        label.visible = !busy
        replaceRemote.visible = !busy
        replaceLocal.visible = !busy
    }

    function upload() {
        toggleElements(true)
        taskListWindow.uploadData()
        pageStack.pop()
    }

    function download() {
        toggleElements(true)
        taskListWindow.downloadData()
        pageStack.pop()
    }

    function startSync() {
        var lastSync = taskListWindow.lastSyncRevision()
        var remote = taskListWindow.getRemoteRevision()
        if (typeof lastSync === "undefined" && typeof remote === "undefined") /* no prev sync */
            upload()
        else if (lastSync === remote) /* prev sync was done from this DB */
            upload()
        else /* prev sync was done from another DB, let user decide */
            toggleElements(false)
    }

    onStatusChanged: {
        if (status === PageStatus.Active) {
            // try to load credentials from database, and authorize if they're missing
            if (!taskListWindow.setDropboxCredentials()) {
                // may be user has already declined access
                if (attemptedAuth) {
                    pageStack.pop()
                    return
                }
                attemptedAuth = true
                var authLink = taskListWindow.dropboxAuthorizeLink()
                var authPage = pageStack.push("DropboxAuth.qml", { url: authLink })
                authPage.accepted.connect(function() {
                    taskListWindow.getDropboxCredentials()
                })
                // when DropboxAuth page is closed, this page becomes active
                // and this routine is executed again
            } else {
                startSync()
            }
        }
    }
}
