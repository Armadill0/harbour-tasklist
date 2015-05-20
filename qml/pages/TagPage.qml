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

import QtQuick 2.1
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
                //: headline for the tags page
                title: qsTr("Manage tags") + " - TaskList"
            }

            SectionHeader {
                //: headline to create new tags
                text: qsTr("Add new tag")
            }

            TextField {
                id: tagAdd
                width: parent.width
                //: fallback text if no name for a new tag is specified
                placeholderText: qsTr("Enter unique tag name")
                //: hint how to confirm the new tag
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

            SectionHeader {
                //: headline for the user created tags
                text: qsTr("Your tags")
            }
        }

        ViewPlaceholder {
            enabled: tagList.count === 0
            //: fallback text if no tags are defined
            text: qsTr("no tags available")
        }

        delegate: ListItem {
            id: tagListItem
            width: ListView.view.width
            contentHeight: menuOpen ? tagContextMenu.height + editTagLabel.height : editTagLabel.height

            property Item tagContextMenu
            property bool menuOpen: tagContextMenu !== null && tagContextMenu.parent === tagListItem

            function remove() {
                //: remorse item when a tag is being deleted
                tagRemorse.execute(tagListItem, qsTr("Deleting") + " '" + tagListModel.get(index).tagName + "'", function() {
                    DB.removeTag(tagListModel.get(index).tagId)
                    tagListModel.remove(index)
                }, taskListWindow.remorseOnDelete * 1000)
            }

            RemorseItem {
                id: tagRemorse
            }

            // additional label to fix the problem that textfield catchs pressandhold context menu events
            Label {
                id: tagLabel
                text: tagName
                width: parent.width
                x: Theme.paddingLarge
                height: editTagLabel.height * 0.55
                anchors.top: parent.top
                verticalAlignment: Text.AlignVCenter
                truncationMode: TruncationMode.Fade
            }

            TextField {
                id: editTagLabel
                x: Theme.paddingSmall
                text: tagName
                visible: false
                EnterKey.enabled: text.length > 2
                // no whitespaces are allowed, 2 to 64 chars are allowed
                validator: RegExpValidator { regExp: /^\S{2,64}$/ }

                function changeTag(newName) {
                    // FIXME reset w/o reloading if update failed
                    DB.updateTag(tagId, newName)
                    reloadTagList()
                }

                // if enter or return is pressed add the new tag
                Keys.onEnterPressed: {
                    changeTag(editTagLabel.text)
                }
                Keys.onReturnPressed: {
                    changeTag(editTagLabel.text)
                }

                onActiveFocusChanged: {
                    // reset textfield when user leaves textfield before confirming changes
                    if (activeFocus === false) {
                        text = tagName
                        readOnly = true
                    }
                }

                onClicked: onClick()
            }

            onClicked: onClick()

            function onClick() {
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
                        //: context menu item to edit a tag
                        text: qsTr("Edit")
                        onClicked: {
                            // close contextmenu
                            tagContextMenu.hide()
                            editTagLabel.text = tagListModel.get(index).tagName
                            tagLabel.visible = false
                            editTagLabel.visible = true
                            editTagLabel.forceActiveFocus()
                        }
                    }
                    MenuItem {
                        //: context menu item to delete a tag
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
