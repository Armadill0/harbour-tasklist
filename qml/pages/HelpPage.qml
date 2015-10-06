/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Thomas Amler
    Contact: Thomas Amler <takslist@penguinfriends.org>

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
    id: helpPage
    allowedOrientations: Orientation.All

    ListModel {
        id: helpModel
    }

    Component.onCompleted: {
        //% "Task page"
        helpModel.append({"page": "taskpage-header",
                             "label": "new task flashing",
                             "description": "Tap on a newly added task while it's still flashing." +
                             " This leads you directly to the Edit page where you can set more options to your task."})
    }

    ListView {
        anchors.fill: parent

        model: helpModel

        header: PageHeader {
                //: headline for the help page
                //% "Help"
                title: qsTrId("helppage-header") + " - " + appname
        }

        section {
            property: "page"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: page
            }
        }

        delegate: Item {
            width: parent.width - 2 * Theme.horizontalPageMargin
            anchors.horizontalCenter: parent.horizontalCenter
            height: childrenRect.height

            Label {
                id: itemLabel
                width: parent.width
                anchors {
                    left: parent.left
                    top: taskPageHeader.bottom
                }

                //% "New task flashing"
                text: label
            }

            Label {
                id: itemDescription
                width: parent.width
                anchors {
                    left: parent.left
                    top: itemLabel.bottom
                }
                font.pixelSize: Theme.fontSizeSmall
                //% "Tap on a newly added task while it's still flashing. This leads you directly to the Edit page where you can set more options to your task."
                text: description
                wrapMode: Text.WordWrap
            }
        }
    }
}
