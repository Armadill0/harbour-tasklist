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

Dialog {
    id: dropboxAuthDialog

    canAccept: false

    Column {
        width: parent.width
        spacing: Theme.itemSizeMedium

        DialogHeader {
            acceptText: qsTr("Continue")
        }

        Label {
            id: label1
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
            }
            text: qsTr("It looks like you do sync with Dropbox in the first time.")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Label {
            id: label2
            anchors {
                left: parent.left
                right: parent.right
                leftMargin: Theme.paddingLarge
                rightMargin: Theme.paddingLarge
            }
            text: qsTr("Click the button below to go to Dropbox website and allow the app to access your folder.")
            wrapMode: Text.Wrap
            horizontalAlignment: Text.AlignHCenter
        }

        Button {
            id: goToDropbox
            anchors.horizontalCenter: parent.horizontalCenter
            text: qsTr("Allow access to Dropbox")
            onClicked: {
                goToDropbox.visible = false
                // do the actual work here
                taskListWindow.authorizeInDropbox()
                label2.visible = false
                label1.text = qsTr("Hopefully you have allowed access and can now go on with sync.")
                canAccept = true
            }
        }
    }
}
