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

    function focusTagAddField(releaseFocus) {
        var tagField = tagList.headerItem.children[2]
        if (releaseFocus && tagField.focus)
            tagField.focus = false
        else
            tagField.forceActiveFocus()
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
        focus: true

        Keys.onTabPressed: focusTagAddField(true)

        header: Column {
            width: parent.width

            PageHeader {
                width: parent.width
                //: headline for the tags page
                //% "Manage tags"
                title: qsTrId("tagspage-header") + " - TaskList"
            }

            SectionHeader {
                //: headline to create new tags
                //% "Add new tag"
                text: qsTrId("new-tag-label")
            }

            TextField {
                id: tagAdd
                width: parent.width
                //: fallback text if no name for a new tag is specified
                //% "Enter unique tag name"
                placeholderText: qsTrId("tagname-placeholder")
                //: hint how to confirm the new tag
                //% "Press Enter/Return to add the new tag"
                label: qsTrId("new-tag-confirmation-description")
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
                //% "Your tags"
                text: qsTrId("tags-header")
            }
        }

        ViewPlaceholder {
            enabled: tagList.count === 0
            //: fallback text if no tags are defined
            //% "no tags available"
            text: qsTrId("no-tags-label")
        }

        delegate: ListItem {
            id: tagListItem
            width: ListView.view.width
            contentHeight: menuOpen ? tagContextMenu.height + editTagLabel.height : editTagLabel.height

            property Item tagContextMenu
            property bool menuOpen: tagContextMenu !== null && tagContextMenu.parent === tagListItem

            function remove() {
                //: remorse item when a tag is being deleted
                //% "Deleting"
                tagRemorse.execute(tagListItem, qsTrId("deleting-label") + " '" + tagListModel.get(index).tagName + "'", function() {
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
                width: parent.width - 2 * Theme.horizontalPageMargin
                anchors.horizontalCenter: parent.horizontalCenter
                height: editTagLabel.height * 0.55
                anchors.top: parent.top
                verticalAlignment: Text.AlignVCenter
                truncationMode: TruncationMode.Fade
            }

            TextField {
                id: editTagLabel
                width: parent.width
                anchors.horizontalCenter: parent.horizontalCenter
                text: tagName
                //: a label to inform the user how the changes on a tag can be saved
                //% "Press Enter/Return to save changes"
                label: qsTrId("save-changes-description")
                visible: false
                EnterKey.enabled: text.length > 0
                // no whitespaces are allowed, up to 64 chars are allowed
                validator: RegExpValidator { regExp: /^\S{,64}$/ }

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
                    // reset label and textfield when user leaves textfield before confirming changes
                    if (activeFocus === false && editTagLabel.visible === true) {
                        editTagLabel.visible = false
                        tagLabel.visible = true
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
                taskListWindow.needListModelReload = true
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
                        //% "Edit"
                        text: qsTrId("edit-label")
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
                        //% "Delete"
                        text: qsTrId("delete-label")
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
