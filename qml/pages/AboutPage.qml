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

Dialog {
    id: aboutPage
    allowedOrientations: Orientation.All
    canAccept: true

    SilicaFlickable {
        id: aboutTaskList
        anchors.fill: parent
        contentHeight: aboutRectangle.height

        VerticalScrollDecorator { flickable: aboutTaskList }

        Rectangle {
            id: aboutRectangle
            width: parent.width

            DialogHeader {
                id: aboutHeader
                title: qsTr("About") + " - TaskList"
                acceptText: qsTr("Back")
            }

            Image {
                id: logoTaskList
                source: "../images/harbour-tasklist.png"
                width: parent.width
                anchors.top: aboutHeader.bottom
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
            }

            Label {
                id: labelTaskList
                text: "TaskList"
                horizontalAlignment: Text.Center
                width: parent.width
                anchors.top: logoTaskList.bottom
            }

            Label {
                id: descTaskList
                text: qsTr("A small but mighty program to manage your daily tasks.")
                width: parent.width - Theme.paddingLarge * 2
                anchors.top: labelTaskList.bottom
                anchors.topMargin: Theme.paddingLarge * 2
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: copyTaskList
                text: qsTr("Copyright © by") + " Thomas Amler\n" + qsTr("License") + ": GPL v3"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                anchors.top: descTaskList.bottom
                anchors.topMargin: Theme.paddingLarge * 2
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
            }

            Label {
                id: sourceTaskList
                textFormat: Text.RichText;
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style>" + qsTr("Source code") + ": <a href=\"https://github.com/Armadill0/harbour-tasklist\">https://github.com/Armadill0/harbour-tasklist</a>"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - Theme.paddingLarge * 2
                anchors.top: copyTaskList.bottom
                anchors.topMargin: Theme.paddingLarge * 2
                font.pixelSize: Theme.fontSizeTiny
                color: Theme.primaryColor

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }
        }
    }
}
