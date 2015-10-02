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

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: helpContent.height

        header: PageHeader {
            //: headline for the help page
            //% "Help"
            title: qsTrId("helppage-header") + " - " + appname
        }

        Column {
            id: helpContent

            SectionHeader {
                //% "Task page"
                text: qsTrId("taskpage-header")
            }

            HelpItem {
                //% "New task flashing"
                label: qsTrId("edit-after-add-label")
                //% "Tap on a newly added task while it's still flashing. This leads you directly to the Edit page where you can set more options to your task."
                description: qsTrId("edit-after-add-description")
            }
        }
    }
}
