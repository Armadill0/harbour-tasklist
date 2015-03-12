/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Murat Khairulin

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
import "../localdb.js" as DB
import "."

Page {
    id: tagPage
    allowedOrientations: Orientation.All

    function appendTag(id, name) {
        tagListModel.append({tagId: id, tagName: name})
    }

    function reloadTagList() {
        tagListModel.clear()
        DB.allTags(appendTag)
    }

    Component.onCompleted: {
        reloadTagList()
    }

    SilicaListView {
        id: tagList
        anchors.fill: parent
        model: ListModel {
            id: tagListModel
        }

        header: Column {
            width: parent.width

            PageHeader {
                width: parent.width
                title: qsTr("Tags")
            }

            TextField {
                id: tagAdd
                width: parent.width
                placeholderText: qsTr("Enter a unique tag")
                label: qsTr("Press Enter/Return to add the new tag")
                EnterKey.enabled: text.length > 2
                // no whitespaces are allowed, 2 to 64 chars are allowed
                validator: RegExpValidator { regExp: /^\S{2,64}$/ }

                EnterKey.onClicked: {
                    if (!DB.writeTag(tagAdd.text))
                        return
                    tagAdd.text = ""
                    reloadTagList()
                }
            }
        }

        ViewPlaceholder {
            enabled: tagList.count === 0
            text: qsTr("no tags to display")
        }

        delegate: ListItem {
            id: tagListItem
            width: ListView.view.width
            height: menuOpen ? tagContextMenu.height + tagLabel.height : tagLabel.height

            property Item tagContextMenu
            property bool menuOpen: tagContextMenu !== null && tagContextMenu.parent === tagListItem

            function remove() {
                tagRemorse.execute(tagListItem, qsTr("Deleting") + " '" + tagListModel.get(index).tagName + "'", function() {
                    DB.removeTag(tagListModel.get(index).tagId)
                    tagListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            RemorseItem {
                id: tagRemorse
            }

            TextField {
                id: tagLabel
                readOnly: true
                x: Theme.paddingSmall
                text: tagName
                EnterKey.enabled: text.length > 2
                // no whitespaces are allowed, 2 to 64 chars are allowed
                validator: RegExpValidator { regExp: /^\S{2,64}$/ }

                EnterKey.onClicked: {
                    readOnly = true
                    // FIXME reset w/o reloading if update failed
                    DB.updateTag(tagId, text)
                    reloadTagList()
                }

                onActiveFocusChanged: {
                    // reset textfield when user leaves textfield before confirming changes
                    if (activeFocus === false) {
                        text = tagName
                        readOnly = true
                    }
                }
            }

            onClicked: {
                // at first set tagId, then change smart list type,
                //  because smart list type change is being monitored
                taskListWindow.tagId = tagId
                taskListWindow.smartListType = 5
                taskListWindow.listchanged = true
                // 2 steps back to get to TaskPage
                var prev = pageStack.previousPage()
                var to = pageStack.previousPage(prev)
                pageStack.pop(to)
            }

            onPressAndHold: {
                if (!tagContextMenu) {
                    tagContextMenu = contextMenuComponent.createObject(tagList)
                }
                tagContextMenu.show(tagListItem)
            }

            Component {
                id: contextMenuComponent
                ContextMenu {
                    MenuItem {
                        text: qsTr("Edit")
                        onClicked: {
                            tagContextMenu.hide()
                            tagLabel.readOnly = false
                            tagLabel.forceActiveFocus()
                        }
                    }
                    MenuItem {
                        text: qsTr("Delete")
                        onClicked: {
                            tagContextMenu.hide()
                            remove()
                        }
                    }
                }
            }
        }
    }
}
