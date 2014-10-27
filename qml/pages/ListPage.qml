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
import "../localdb.js" as DB

Page {
    id: listPage
    allowedOrientations: Orientation.All

    // helper function to add lists to the list
    function appendList(id, listname, tNumber) {
        listListModel.append({"listid": id, "listname": listname, "tNumber": tNumber})
    }

    // helper function to wipe the list element
    function wipeListList() {
        listListModel.clear()
    }

    function reloadListList() {
        wipeListList()
        DB.readLists()
    }

    onStatusChanged: {
        switch(status) {
        case PageStatus.Active :
                reloadListList()

            break
        }
    }

    Component.onCompleted: {
        reloadListList()
    }

    SilicaListView {
        id: listList
        anchors.fill: parent
        model: ListModel {
            id: listListModel
        }

        VerticalScrollDecorator { flickable: listList }

        header: Column {
            width: parent.width

            PageHeader {
                width: parent.width
                title: qsTr("Manage lists") + " - TaskList"
            }

            TextField {
                id: listAdd
                width: parent.width
                placeholderText: qsTr("Enter unique list name")
                label: qsTr("Press Enter/Return to add the new list")
                // enable enter key if minimum list length has been reached
                EnterKey.enabled: listAdd.text.length > 0
                // set allowed chars and list length
                validator: RegExpValidator { regExp: /^.{,60}$/ }

                function addList(listNew) {
                    if (listNew.length > 0) {
                        // add list to db
                        var newid = DB.writeList(listNew)
                        // catch sql errors
                        if (newid !== "ERROR") {
                            listPage.appendList(newid, listNew)
                            // reset textfield
                            listAdd.text = ""
                        }
                        else {
                            // display notification if list already exists
                            taskListWindow.pushNotification("WARNING", qsTr("List could not be added!"), qsTr("It already exists."))
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
        }

        delegate: ListItem {
            id: listListItem
            contentHeight: (menuOpen ? (listContextMenu.height + editListLabel.height) : editListLabel.height)

            property Item listContextMenu
            property bool menuOpen: listContextMenu != null && listContextMenu.parent === listListItem

            // helper function to remove current item
            function remove() {
                // run remove via a silica remorse item
                listRemorse.execute(listListItem, qsTr("Deleting") + " '" + listListModel.get(index).listname + "'", function() {
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

                if (taskListWindow.defaultlist === listid) { listPropertiesArray.push(qsTr("default")) }

                if (taskListWindow.coverListSelection === 2 && taskListWindow.coverListChoose === listListModel.get(index).listid) { listPropertiesArray.push(qsTr("Cover")) }

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
                width: parent.width - 105
                x: 25
                height: editListLabel.height * 0.55
                anchors.top: parent.top
                verticalAlignment: Text.AlignVCenter
                truncationMode: TruncationMode.Fade
            }

            Label {
                id: listTaskNumber
                text: tNumber > 999 ? "999+" : tNumber
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
                x: 25
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
                width: parent.width - 70
                text: listname
                label: qsTr("Press Enter/Return to save changes")
                visible: false
                anchors.top: parent.top
                // enable enter key if minimum list length has been reached
                EnterKey.enabled: editListLabel.text.length > 0

                // set allowed chars and list length
                validator: RegExpValidator { regExp: /^.{,60}$/ }

                function changeList(listNew) {
                    // update list in db
                    DB.updateList(listid, listNew)
                    // small hack to automatically reload the current selected list which name has been changed
                    if (taskListWindow.listid === listid) {
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
                pageStack.navigateBack()
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: listMenu

                    MenuItem {
                        text: qsTr("Edit")
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
                        text: qsTr("Set as Default list")
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
                        text: qsTr("Set as Cover list")
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
                        text: qsTr("Delete")
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
