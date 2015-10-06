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
import "../localdb.js" as DB
import "."

Page {
    id: listPage
    allowedOrientations: Orientation.All
    property int totalPending
    property int totalTasks
    property int totalNew
    property int totalToday
    property int totalTomorrow

    // helper function to add lists to the list
    function appendList(ID, name, total, pending, recent, today, tomorrow) {
        listListModel.append({ listid: ID, listname: name, total: total,
                               pending: pending, recent: recent,
                               today: today, tomorrow: tomorrow });
    }

    // helper function to wipe the list element
    function wipeListList() {
        listListModel.clear()
    }

    function reloadListList() {
        // calculate the offset for the new tasks number
        // *1000 eliminates the unix microseconds
        var currentUnixTime = DB.getUnixTime();
        var recently = currentUnixTime - (taskListWindow.recentlyAddedPeriods[taskListWindow.recentlyAddedOffset] * 1000)

        wipeListList()
        DB.readLists(recently, appendList)
    }

    function addSmartList(listType, tasks, buttonActive) {
        if (typeof(buttonActive) === "undefined")
            buttonActive = tasks > 0
        smartListModel.append({ listName: taskListWindow.smartListNames[listType], taskCount: tasks,
                                buttonActive: buttonActive, listType: listType })
    }

    // simplified: distinguishes only cases '1' and '> 1', which is right in English,
    //   but not in Russian, for instance
    function pluralizeItems(count, listType) {
        if (count < 0)
            //: default string for task count of smart lists, when value is not available (n/a)
            //% "n/a"
            return qsTrId("not-available")
        var countStr = count > 999 ? "999+" : count.toString()
        // items can be tags
        if (listType === 5) {
            if (count === 1)
                //: use %1 as a placeholder for the number of the existing tag, which should always be 1
                //% "%1 tag"
                return qsTrId("single-tag-count-label").arg(countStr)
            //: use %1 as a placeholder for the number of existing tags
            //% "%1 tags"
            return qsTrId("tag-count-label").arg(countStr)
        }
        // or items can be tasks
        if (count === 1)
            //: use %1 as a placeholder for the number of tasks of the smart lists
            //% "%1 task"
            return qsTrId("single-task-count-label").arg(countStr)
        //: use %1 as a placeholder for the number of tasks of the smart lists
        //% "%1 tasks"
        return qsTrId("task-count-label").arg(countStr)
    }

    function focusListAddField(releaseFocus) {
        var listField = listList.headerItem.children[4]
        if (releaseFocus && listField.focus)
            listField.focus = false
        else
            listField.forceActiveFocus()
    }

    onStatusChanged: {
        switch(status) {
        case PageStatus.Active:
            reloadListList()

            // iterate over the list to get numbers for different task types
            totalTasks = 0
            totalPending = 0
            totalNew = 0
            totalToday = 0
            totalTomorrow = 0
            for (var i = 0; i < listListModel.count; ++i) {
                var item = listListModel.get(i)
                totalTasks      += item.total
                totalPending    += item.pending
                totalNew        += item.recent
                totalToday      += item.today
                totalTomorrow   += item.tomorrow
            }
            var totalDone = totalTasks - totalPending
            var totalTags = DB.allTags()

            // flush default values from Gridview before appending real ones
            smartListModel.clear()
            addSmartList(0, totalDone)
            addSmartList(1, totalPending)
            addSmartList(2, totalNew)
            addSmartList(3, totalToday)
            addSmartList(4, totalTomorrow)
            addSmartList(5, totalTags, true)
            break
        }
    }

    Component.onCompleted: {
        // flush dummy element and replace with default smart list elements
        smartListModel.clear()
        for (var i in taskListWindow.smartListNames) {
            // push default values to task number of smart lists
            //: default string for task count of smart lists, when value is not available (n/a)
            addSmartList(parseInt(i), -1)
        }

        //reloadListList()
    }

    ListModel {
        id: smartListModel

        // dummy element to prevent ListView from flicking on appending smart lists
        ListElement {
            listName: "dummy"
            taskCount: -1
            buttonActive: false
            listType: -1
        }
    }

    SilicaListView {
        id: listList
        anchors.fill: parent
        model: ListModel {
            id: listListModel
        }
        focus: true

        Keys.onTabPressed: focusListAddField(true)

        VerticalScrollDecorator { flickable: listList }

        header: Column {
            width: parent.width

            PageHeader {
                width: parent.width
                //: headline for overview of all lists
                //% "Manage lists"
                title: qsTrId("listpage-header") + " - " + appname
            }

            SectionHeader {
                //: headline for all automatic smart lists
                //% "Smart lists"
                text: qsTrId("smartlist-header")
                visible: taskListWindow.smartListVisibility
            }

            Grid {
                id: smartListContainer
                width: parent.width
                visible: taskListWindow.smartListVisibility
                columns: 3

                Repeater {
                    model: smartListModel

                    delegate: ValueButton {
                        label: listName
                        width: smartListContainer.width / 3
                        height: Theme.itemSizeMedium
                        value: pluralizeItems(taskCount, listType)
                        valueColor: Theme.secondaryColor
                        // disabled for default values to prevent errors if not all data is available yet
                        enabled: buttonActive

                        onClicked: {
                            // tags list is different
                            if (listType === 5) {
                                pageStack.push("TagPage.qml")
                                return
                            }
                            // set smart list type, mark flag that list changed, navigate back to task page
                            taskListWindow.smartListType = listType
                            taskListWindow.listchanged = true
                            pageStack.navigateBack()
                        }
                    }
                }
            }

            SectionHeader {
                //: headline above the text field where the user can add new lists
                //% "Add new list"
                text: qsTrId("new-list-header")
            }

            TextField {
                id: listAdd
                width: parent.width
                //: the placeholder where the user can enter the name of a new list
                //% "Enter unique list name"
                placeholderText: qsTrId("list-name-placeholder")
                //: a label to inform the user how to add the new list
                //% "Press Enter/Return to add the new list"
                label: qsTrId("new-list-confirmation-description")
                // enable enter key if minimum list length has been reached
                EnterKey.enabled: listAdd.text.length > 0
                // set allowed chars and list length
                validator: RegExpValidator { regExp: /^.{,60}$/ }

                function addList(listNew) {
                    if (listNew.length > 0) {
                        var newId = DB.writeList(listNew)
                        if (newId >= 0) {
                            appendList(newId, listNew, 0, 0, 0, 0, 0)
                            // reset textfield
                            listAdd.text = ""
                        } else {
                            // display notification if list already exists
                            //% "List could not be added!"
                            taskListWindow.pushNotification("ERROR", qsTrId("list-add-error"),
                                                            //% "It already exists."
                                                            qsTrId("list-add-error-detail"))
                        }
                    }
                }

                // if enter or return is pressed add the new list
                Keys.onEnterPressed: {
                    addList(listAdd.text)
                }
                Keys.onReturnPressed: {
                    addList(listAdd.text)
                }
            }

            SectionHeader {
                //: headline for the user created lists
                //% "Your lists"
                text: qsTrId("lists-header")
            }
        }

        delegate: ListItem {
            id: listListItem
            contentHeight: (menuOpen ? (listContextMenu.height + editListLabel.height) : editListLabel.height)

            property Item listContextMenu
            property bool menuOpen: listContextMenu != null && listContextMenu.parent === listListItem

            // helper function to remove current item
            function remove() {
                // run remove via a silica remorse item
                //% "Deleting"
                listRemorse.execute(listListItem, qsTrId("deleting-label") + " '" + listListModel.get(index).listname + "'", function() {
                    // if current list is deleted, change trigger variables to reload list and list name
                    if (taskListWindow.listid === listListModel.get(index).listid) {
                        taskListWindow.listid = taskListWindow.defaultlist
                    }

                    // if deleted list is chosen as cover list it needs to be set to the default list
                    if (taskListWindow.coverListChoose === listListModel.get(index).listid)
                        taskListWindow.coverListChoose = taskListWindow.defaultlist

                    // remove deleted list from database and list page
                    DB.removeList(listListModel.get(index).listid)
                    listListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            // function to render string of list properties
            function renderListProperties() {
                var listPropertiesArray = [];
                var listPropertiesString = "";

                //% "default"
                if (taskListWindow.defaultlist === listid) { listPropertiesArray.push(qsTrId("default-label")) }

                //% "Cover"
                if (taskListWindow.coverListSelection === 2 && taskListWindow.coverListChoose === listListModel.get(index).listid) { listPropertiesArray.push(qsTrId("cover-label")) }

                for (var i = 0; i < listPropertiesArray.length; i++) {
                    if (i > 0)
                        listPropertiesString += ", "

                    listPropertiesString += listPropertiesArray[i];
                }

                return listPropertiesString;
            }

            Component.onCompleted: {
                listProperties.text = renderListProperties()
            }

            // remorse item for all remorse actions
            RemorseItem {
                id: listRemorse
            }

            Label {
                id: listLabel
                text: listname
                // FIXME don't use fixed pixel sizes
                width: parent.width - 105
                x: Theme.paddingLarge
                height: editListLabel.height * 0.55
                anchors.top: parent.top
                verticalAlignment: Text.AlignVCenter
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: listTaskNumber
                text: pending + "/" + (total > 999 ? "999+" : total)
                // FIXME don't use fixed pixel sizes
                width: 70
                height: editListLabel.height * 0.55
                anchors.top: parent.top
                anchors.left: listLabel.right
                verticalAlignment: Text.AlignVCenter
                horizontalAlignment: Text.AlignRight
            }

            Label {
                id: listProperties
                width: parent.width
                x: Theme.paddingLarge
                height: editListLabel.height * 0.45
                font.pixelSize: Theme.fontSizeSmall
                font.italic: true
                color: Theme.secondaryColor
                truncationMode: TruncationMode.Fade
                verticalAlignment: Text.AlignTop
                anchors.top: listLabel.bottom
            }

            TextField {
                id: editListLabel
                // FIXME don't use fixed pixel sizes
                width: parent.width - 70
                text: listname
                //: a label to inform the user how the changes on a list can be saved
                //% "Press Enter/Return to save changes"
                label: qsTrId("save-changes-description")
                visible: false
                anchors.top: parent.top
                // enable enter key if minimum list length has been reached
                EnterKey.enabled: text.length > 0

                // set allowed chars and list length
                validator: RegExpValidator { regExp: /^.{,60}$/ }

                function changeList(newName) {
                    // update list in db
                    if (DB.updateList(listid, newName)) {
                        // small hack to automatically reload the current selected list which name has been changed
                        if (taskListWindow.listid === listid)
                            taskListWindow.listchanged = true
                    }
                    // finally reload list overview to update the items
                    reloadListList()
                }

                // if enter or return is pressed add the new list
                Keys.onEnterPressed: {
                    changeList(editListLabel.text)
                }
                Keys.onReturnPressed: {
                    changeList(editListLabel.text)
                }

                onActiveFocusChanged: {
                    // reset label and textfield when user leaves textfield before confirming changes
                    if (activeFocus === false && editListLabel.visible === true) {
                        editListLabel.visible = false
                        listLabel.visible = true
                        listProperties.visible = true
                    }
                }
            }

            // show context menu
            onPressAndHold: {
                if (!listContextMenu) {
                    listContextMenu = contextMenuComponent.createObject(listList)
                }
                listContextMenu.show(listListItem)
            }

            onClicked: {
                // set current global list and jump to taskPage
                taskListWindow.listid = listid
                taskListWindow.smartListType = -1
                taskListWindow.listchanged = true
                pageStack.navigateBack()
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: listMenu

                    MenuItem {
                        //: context menu item to edit a list
                        //% "Edit"
                        text: qsTrId("edit-label")
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            editListLabel.text = listListModel.get(index).listname
                            listLabel.visible = false
                            listProperties.visible = false
                            editListLabel.visible = true
                            editListLabel.forceActiveFocus()
                        }
                    }

                    MenuItem {
                        //: context menu item to set a list as the default list, which is shown at application start
                        //% "Set as Default list"
                        text: qsTrId("set-default-list-label")
                        visible: (taskListWindow.defaultlist !== listid) ? true : false
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            DB.updateSetting("defaultList", listid)
                            // update global defaultlist property
                            taskListWindow.defaultlist = listid
                            // reload lists
                            reloadListList()
                        }
                    }

                    MenuItem {
                        //: context menu item to set a list as the default cover list
                        //% "Set as Cover list"
                        text: qsTrId("set-cover-list-label")
                        // only show if choose cover list is active and list is not the current chosen one
                        visible: (taskListWindow.coverListSelection === 2 && taskListWindow.coverListChoose !== listid) ? true : false
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            DB.updateSetting("coverListChoose", listid)
                            // update global defaultlist property
                            taskListWindow.coverListChoose = listid
                            // reload lists
                            reloadListList()
                        }
                    }

                    MenuItem {
		    	//% "Copy to clipboard"
                        text: qsTrId("to-clipboard-label")
                        visible: pending > 0
                        onClicked: {
                            var data = DB.getSimpleList(listid)
                            if (data.length > 0)
                                Clipboard.text = data
                            else
		    		//% "List not copied"
                                taskListWindow.pushNotification("WARNING", qsTrId("list-not-copied-warning"),
		    							   //% "List is empty."
									   qsTrId("list-empty-description"))
                        }
                    }

                    MenuItem {
                        //% "Delete"
                        text: qsTrId("delete-label")
                        // default list must not be deleted
                        visible: (taskListWindow.defaultlist !== listid) ? true : false
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            // trigger item removal
                            remove()
                        }
                    }
                }
            }
        }
    }
}
