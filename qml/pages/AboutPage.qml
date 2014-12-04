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

        ListModel {
            id: contributorsList

            ListElement { name: "Manuel Soriano (manu007)" }
            ListElement { name: "Ilja Balonov" }
            ListElement { name: "Léonard Meyer" }
            ListElement { name: "Anatoly Shipitsin" }
            ListElement { name: "fri" }
            ListElement { name: "Jiri Grönroos" }
            ListElement { name: "İsmail Adnan Sarıer" }
            ListElement { name: "Åke Engelbrektson" }
            ListElement { name: "Heimen Stoffels" }
            ListElement { name: "Agustí Clara" }
            ListElement { name: "lorenzo facca" }
            ListElement { name: "TylerTemp" }
            ListElement { name: "Peter Jespersen" }
        }

        Column {
            id: aboutRectangle
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            spacing: Theme.paddingSmall

            DialogHeader {
                //: headline of application information page
                title: qsTr("About") + " - TaskList"
                //: switch from About back to application
                acceptText: qsTr("Back")
            }

            Image {
                source: "../images/harbour-tasklist.png"
                width: parent.width
                fillMode: Image.PreserveAspectFit
                horizontalAlignment: Image.AlignHCenter
            }

            Label {
                text: "TaskList " + version
                horizontalAlignment: Text.Center
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
            }

            SectionHeader {
                //: headline for application description
                text: qsTr("Description")
            }

            Label {
                //: TaskList description
                text: qsTr("A small but mighty program to manage your daily tasks.")
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                wrapMode: Text.WordWrap
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                //: headline for application licensing information
                text: qsTr("Licensing")
            }

            Label {
                //: Copyright and license information
                text: qsTr("Copyright © by") + " Thomas Amler\n" + qsTr("License") + ": GPL v3"
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeSmall
            }

            SectionHeader {
                //: headline for application project information
                text: qsTr("Project information")
                font.pixelSize: Theme.fontSizeSmall
            }

            Label {
                textFormat: Text.RichText;
                text: "<style>a:link { color: " + Theme.highlightColor + "; }</style><a href=\"https://github.com/Armadill0/harbour-tasklist\">https://github.com/Armadill0/harbour-tasklist</a>"
                width: parent.width - Theme.paddingLarge * 2
                anchors.horizontalCenter: parent.horizontalCenter
                font.pixelSize: Theme.fontSizeTiny

                onLinkActivated: {
                    Qt.openUrlExternally(link)
                }
            }

            SectionHeader {
                //: headline for application contributors
                text: qsTr("Contributors")
            }

            Repeater {
                model: contributorsList

                delegate: Label {
                    text: "- " + name
                    width: parent.width - Theme.paddingLarge * 2
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.pixelSize: Theme.fontSizeSmall
                }
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingLarge
                color: "transparent"
            }
        }
    }
}
