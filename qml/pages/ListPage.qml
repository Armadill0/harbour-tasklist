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

    // helper function to add lists to the list
    function appendList(id, listname) {
        listListModel.append({"listid": id, "listname": listname})
    }

    // helper function to wipe the list element
    function wipeListList() {
        listListModel.clear()
    }

    function reloadListList() {
        wipeListList()
        DB.readLists();
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
                validator: RegExpValidator { regExp: /^([^(\'|\;|\")]){,30}$/ }

                function addList(listNew) {
                    if (listNew.length > 0) {
                        // add list to db
                        var newid = DB.writeList(listNew)
                        // catch sql errors
                        if (newid !== "ERROR_DUPLICATE_ENTRY") {
                            listPage.appendList(newid, listNew)
                            // reset textfield
                            listAdd.text = ""
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
            height: menuOpen ? listContextMenu.height + listLabel.height : listLabel.height

            property Item listContextMenu
            property bool menuOpen: listContextMenu != null && listContextMenu.parent === listListItem

            // helper function to remove current item
            function remove() {
                // run remove via a silica remorse item
                listRemorse.execute(listListItem, qsTr("Deleting") + " '" + listListModel.get(index).listname + "'", function() {
                    // if current list is deleted, change trigger variables to reload list and list name
                    if (taskListWindow.listid === listListModel.get(index).listid) {
                        taskListWindow.listid = taskListWindow.defaultlist
                        taskListWindow.listchanged = true
                        taskListWindow.listname = DB.getListProperty(taskListWindow.defaultlist, "ListName")
                    }
                    // remove deleted list from database and list page
                    DB.removeList(listListModel.get(index).listid)
                    listListModel.remove(index)
                }, 5000)
            }

            // remorse item for all remorse actions
            RemorseItem {
                id: listRemorse
            }

            Label {
                id: listLabel
                text: (taskListWindow.defaultlist === listid) ? listname + " (" + qsTr("default") + ")" : listname
                width: parent.width - 25
                x: 25
                height: 80
                verticalAlignment: Text.AlignVCenter
            }

            TextField {
                id: editListLabel
                width: parent.width
                text: listname
                visible: false
                anchors.top: parent.top
                // enable enter key if minimum list length has been reached
                EnterKey.enabled: editListLabel.text.length > 0

                // set allowed chars and list length
                validator: RegExpValidator { regExp: /^([^(\'|\;|\")]){,30}$/ }

                function changeList(listNew) {
                    // update list in db
                    DB.updateList(listid, listNew)
                    // update global listname property if the changed list is the current one
                    if (taskListWindow.listid === listListModel.get(index).listid) {
                        taskListWindow.listname = listNew
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
                    }
                }
            }

            onPressAndHold: {
                if (!listContextMenu) {
                    listContextMenu = contextMenuComponent.createObject(listList)
                }
                listContextMenu.show(listListItem)
            }

            onClicked: {
                // set current global list and jump to taskPage
                taskListWindow.listid = listListModel.get(index).listid
                taskListWindow.listname = listListModel.get(index).listname
                taskListWindow.listchanged = true
                pageStack.navigateBack()
            }

            // defines the context menu used at each list item
            Component {
                id: contextMenuComponent
                ContextMenu {
                    id: listMenu

                    MenuItem {
                        height: 65
                        text: qsTr("Edit")
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            editListLabel.text = listListModel.get(index).listname
                            listLabel.visible = false
                            editListLabel.visible = true
                            editListLabel.forceActiveFocus()
                        }
                    }

                    MenuItem {
                        height: 65
                        text: qsTr("Set as default list")
                        visible: (taskListWindow.defaultlist !== listid) ? true : false
                        onClicked: {
                            // close contextmenu
                            listContextMenu.hide()
                            DB.updateSetting("defaultList", listListModel.get(index).listid);
                            // update global defaultlist property
                            taskListWindow.defaultlist = listListModel.get(index).listid
                            // reload lists
                            reloadListList()
                        }
                    }

                    MenuItem {
                        height: 65
                        text: qsTr("Delete")
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
