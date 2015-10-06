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
        //: task page header of help page
        //% "Task page"
        helpModel.append({"sectionid": qsTrId("taskpage-header"),
                             //% "New task is flashing"
                             "label": qsTrId("new-task-flashing-label"),
                             //% "Tap on a newly added task while it's still flashing. This leads you directly to the Edit page where you can change the details of your task."
                             "description": qsTrId("new-task-flashing-description")})
        helpModel.append({"sectionid": qsTrId("taskpage-header"),
                             //% "Add multiple tasks"
                             "label": qsTrId("add-multiple-tasks-label"),
                             //% "By Copying multiple lines e.g. from an e-mail and pasting those lines to the text field, you can add multiple tasks at once. Each line defines an own task."
                             "description": qsTrId("add-multiple-tasks-description")})
        //: tag page header of help page
        //% "Tag Page"
        helpModel.append({"sectionid": qsTrId("tagpage-header"),
                             //% "Manage Tags"
                             "label": qsTrId("tag-management-label"),
                             //% "Managing tags is currently only possible if you press on the Tag smartlist on the List page. We are examining to rearrange this in the future."
                             "description": qsTrId("tag-management-description")})
        //: keyboard header of help page
        //% "Keyboard Support"
        helpModel.append({"sectionid": qsTrId("keyboard-header"),
                             //% "Jump to text field"
                             "label": qsTrId("keyboard-tab-label"),
                             //% "By pressing Tab on an attached keyboard you can jump into or out of the text fields."
                             "description": qsTrId("keyboard-tab-description")})
        helpModel.append({"sectionid": qsTrId("keyboard-header"),
                             //% "Jump to next/previous list"
                             "label": qsTrId("keyboard-arrows-lr-label"),
                             //% "If the text field on the Task page is NOT focused you can switch between lists by pressing the right (next list) or left (previous list) arrows."
                             "description": qsTrId("keyboard-arrows-lr-description")})
    }

    SilicaListView {
        id: helpPageList
        anchors.fill: parent

        model: helpModel

        VerticalScrollDecorator { flickable: helpPageList }

        header: Column {
            width: parent.width

            PageHeader {
                //: headline for the help page
                //% "Help"
                title: qsTrId("helppage-header") + " - " + appname
            }

            Label {
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                //% "This page describes all hidden and unapparent features."
                text: qsTrId("helppage-description")
                wrapMode: Text.WordWrap
            }
        }

        section {
            property: "sectionid"
            criteria: ViewSection.FullString
            delegate: SectionHeader {
                text: section
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
                    top: parent.top
                }

                text: label
            }

            Label {
                id: itemDescription
                width: parent.width
                anchors {
                    left: parent.left
                    top: itemLabel.bottom
                }
                font.pixelSize: Theme.fontSizeExtraSmall
                text: description
                wrapMode: Text.WordWrap
            }

            Rectangle {
                width: parent.width
                height: Theme.paddingLarge
                anchors.top: itemDescription.bottom
                color: "transparent"
            }
        }
    }
}
