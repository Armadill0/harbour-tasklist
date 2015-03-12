import QtQuick 2.0
import Sailfish.Silica 1.0
import "../localdb.js" as DB

Dialog {
    id: tagDialog
    allowedOrientations: Orientation.All
    canAccept: true

    // string: list of tags, separated by ', '
    property string selected
    // tags as array
    property variant selectedTags
    // pointer to the next not checked ID in @selectedTags
    property int _selectedPos: 0

    function checkIfSelected(id) {
        while (_selectedPos < selectedTags.length && selectedTags[_selectedPos] < id)
            _selectedPos = _selectedPos + 1
        return _selectedPos < selectedTags.length && selectedTags[_selectedPos] === id
    }

    function appendTag(id, name) {
        tagListModel.append({tagId: id, tagName: name, tagState: checkIfSelected(name)})
    }

    function reloadTagList() {
        tagListModel.clear()
        _selectedPos = 0
        DB.allTags(appendTag)
    }

    Component.onCompleted: {
        selectedTags = selected.split(", ")
        reloadTagList()
    }

    SilicaListView {
        id: tagList
        anchors.fill: parent

        VerticalScrollDecorator { flickable: tagList }

        model: ListModel {
            id: tagListModel
        }

        header: DialogHeader {
            title: qsTr("Select tags")
            acceptText: qsTr("Confirm")
        }

        delegate: ListItem {
            id: tagListItem
            width: ListView.view.width

            TextSwitch {
                id: tagSwitch
                text: tagName
                checked: tagState

                onCheckedChanged: {
                    tagListModel.get(index).tagState = checked
                }
            }
        }
    }

    onDone: {
        var tags = []
        for (var i = 0; i < tagListModel.count; ++i) {
            var item = tagListModel.get(i)
            if (item.tagState)
                tags.push(item.tagName)
        }
        selected = tags.join(", ")
    }
}
