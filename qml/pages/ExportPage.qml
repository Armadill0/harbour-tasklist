/*
    TaskList - A small but mighty program to manage your daily tasks.
    Copyright (C) 2015 Murat Khayrulin

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
import harbour.tasklist.tasks_export 1.0

Page {
    id: exportPage
    allowedOrientations: Orientation.All

    property int selectedElementId: -1
    property string selectedFileName : ""

    function composeFullPath(baseName) {
        return StandardPaths.documents + "/" + baseName + ".json";
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        Column {
            id: column
            width: parent.width
            spacing: 20

            PageHeader {
                title: qsTr("Export/import task lists")
            }

            TextField {
                id: exportName
                width: parent.width
                placeholderText: qsTr("Enter a file name for export")
                onTextChanged: {
                    var path = composeFullPath(text)
                    label = path
                    exporter.fileName = path
                }
            }

            TasksExport {
                id: exporter
            }

            Button {
                id: exportButton
                width: parent.width
                text: qsTr("Export task lists")

                onClicked: {
                    var json = DB.dumpTasks()
                    var ret = exporter.save(json)
                    if (ret)
                        pageStack.navigateBack()
                }
            }

            Label {
                id: importLabel
                width: parent.width
                horizontalAlignment: Text.AlignHCenter
                text: qsTr("Select a file to import")
                font.family: Theme.fontFamilyHeading
            }

            ListModel {
                id: importFilesModel
                ListElement {
                    fileName: "dummy"
                    width: "0"
                    elementId: 0
                }
            }

            Grid {
                id: importList
                width: parent.width
                columns: 1

                Repeater {
                    model: importFilesModel

                    delegate: ValueButton {
                        label: fileName
                        width: column.width
                        height: Theme.itemSizeSmall
                        highlighted: elementId === selectedElementId
                        onClicked: {
                            /* element with id 0 is non-selectable placeholder if there are no files */
                            if (elementId === 0)
                                return
                            selectedElementId = elementId
                            selectedFileName = fileName
                        }
                    }
                }
            }

            Component.onCompleted: {
                var list = exporter.getFilesList(StandardPaths.documents);
                importFilesModel.clear()
                if (list.length < 1) {
                    importFilesModel.append({fileName: qsTr("Import files not found"), elementId: 0});
                } else {
                    for (var i = 0; i < list.length; ++i)
                        importFilesModel.append({fileName: list[i], elementId: i + 1});
                }
            }

            Button {
                id: importButton
                width: parent.width
                text: qsTr("Import task lists")

                onClicked: {
                    if (selectedFileName.length === 0)
                        return
                    var json = exporter.loadTasks(composeFullPath(selectedFileName));
                    if (DB.importTasks(json))
                        pageStack.navigateBack()
                }
            }
        }
    }
}
