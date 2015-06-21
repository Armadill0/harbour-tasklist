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

    property bool attemptedAuth

    Column {
        id: column
        spacing: Theme.paddingLarge
        width: parent.width

        PageHeader { title: qsTr("Sync in progress") }

        BusyIndicator {
            running: true
            size: BusyIndicatorSize.Large
            anchors.horizontalCenter: parent.horizontalCenter
        }
    }

    function startSync() {
        taskListWindow.doDropboxSync()
        pageStack.pop()
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
