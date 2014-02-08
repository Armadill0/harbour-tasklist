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

import QtQuick 2.0
import Sailfish.Silica 1.0
import "pages"
import "cover"
import "localdb.js" as DB

ApplicationWindow {
    id: taskListWindow
    initialPage: Component { TaskPage {} }
    cover: Component { CoverPage {} }

    // set current list
    property int listid
    // save defaultlist in a global context
    property int defaultlist
    // save list name in a global context
    property string listname
    // helper varable if list has been changed
    property bool listchanged: false
    // helper varable for adding directly through coveraction
    property bool coverAddTask: false
    // helper varable to lock task Page Orientation
    property bool lockTaskOrientation: false
    // indicator variable when app just started
    property bool justStarted: true
    // variable to save the list of lists as a string
    property string listOfLists

    // initilize default settings properties
    property int coverListSelection
    property int coverListChoose
    property int coverListOrder
    property bool taskOpenAppearance
    property string dateFormat
    property string timeFormat
    property int remorseOnDelete
    property int remorseOnMark

    // a function to check which appearance should be used by open tasks
    function statusOpen(a) { return a === taskListWindow.taskOpenAppearance ? true : false }
}
