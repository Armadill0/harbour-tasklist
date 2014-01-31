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

Page {
    id: aboutPage
    allowedOrientations: Orientation.All

    SilicaFlickable {
        anchors.fill: parent
        anchors.left: parent.left
        PageHeader {
            id: aboutHeader
            title: qsTr("About") + " - TaskList"
            height: 60
        }

        SilicaListView {
            id: aboutTaskList
            anchors.top: aboutHeader.bottom
            anchors.bottom: parent.bottom
            width: parent.width

            Image {
                id: taskListLogo
                source: "../images/harbour-tasklist.png"
                width: parent.width
                fillMode: Image.PreserveAspectFit
                anchors.top: parent.top
                anchors.topMargin: 100
                horizontalAlignment: Image.AlignHCenter
            }

            Label {
                id: appName
                text: "TaskList"
                horizontalAlignment: Text.Center
                width: parent.width
                anchors.top: taskListLogo.bottom
            }

            Label {
                id: appDescription
                text: qsTr("A small but mighty program to manage your daily tasks.")
                width: parent.width - 40
                anchors.top: appName.bottom
                anchors.topMargin: 20
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
                anchors.horizontalCenter: parent.horizontalCenter
            }

            Label {
                id: copyrightText
                text: qsTr("Copyright by") + " Thomas Amler\n" + qsTr("License") + ": GPL v3"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                anchors.top: appDescription.bottom
                anchors.topMargin: 50
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
            }

            Label {
                id: sourcecodeText
                text: qsTr("Source code") + ": <a href='https://github.com/Armadill0/harbour-tasklist'>www.github.com</a>"
                anchors.horizontalCenter: parent.horizontalCenter
                width: parent.width - 40
                anchors.top: copyrightText.bottom
                anchors.topMargin: 50
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.primaryColor
            }
        }
    }
}
