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

    function getFiles() {
        var list = exporter.getFilesList(StandardPaths.documents);
        importFilesModel.clear()
        if (list.length < 1) {
            //: informing user that no former exports are available
            importFilesModel.append({fileName: qsTr("No files for import available."), elementId: 0});
        } else {
            for (var i = 0; i < list.length; ++i)
                importFilesModel.append({fileName: list[i], elementId: i + 1});
        }
    }

    SilicaFlickable {
        anchors.fill: parent
        contentHeight: column.height

        VerticalScrollDecorator { }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: export/import page headline
                title: qsTr("Export/Import") + " - TaskList"
            }

            SectionHeader {
                //: headline for exports
                text: qsTr("Export target")
            }

            TextField {
                id: exportName
                width: parent.width
                //: placeholder message to remind the user that he has to enter a name for the data export
                placeholderText: qsTr("Enter a file name for export")
                onTextChanged: {
                    var path = composeFullPath(text)
                    label = path
                    exporter.fileName = path
                }
                validator: RegExpValidator { regExp: /^.{1,60}$/ }
                inputMethodHints: Qt.ImhNoPredictiveText
            }

            TasksExport {
                id: exporter
            }

            Button {
                id: exportButton
                //: headline for the data export section
                text: qsTr("Export data")
                anchors.horizontalCenter: parent.horizontalCenter
                enabled: exportName.acceptableInput

                onClicked: {
                    var json = DB.dumpData()
                    var ret = exporter.save(json)
                    if (ret) {
                        //: informational notification about the successful eported data
                        taskListWindow.pushNotification("INFO", qsTr("Successfully exported all data."), qsTr("File path") + ": " + composeFullPath(exportName.text))
                        exportName.text = ""
                        getFiles()
                    }
                }
            }

            SectionHeader {
                //: headline for imports
                text: qsTr("Select a file to import")
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
                        description: elementId !== 0 ? composeFullPath(fileName) : ""
                        width: column.width
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
                getFiles()
            }

            Row {
                width: parent.width

                Button {
                    id: deleteButton
                    width: parent.width / 2
                    //: Button to delete the selected data file
                    text: qsTr("Delete file")
                    enabled: selectedElementId !== -1

                    onClicked: {
                        if (selectedFileName.length === 0)
                            return
                        var result = exporter.remove(composeFullPath(selectedFileName))

                        if (result) {
                            selectedElementId = -1
                            getFiles()
                        }
                    }
                }

                Button {
                    id: importButton
                    width: parent.width / 2
                    //: Button to import data form the selected file
                    text: qsTr("Import data")
                    enabled: selectedElementId !== -1

                    onClicked: {
                        if (selectedFileName.length === 0)
                            return
                        var json = exporter.load(composeFullPath(selectedFileName));
                        if (DB.importData(json)) {
                            //: informational notification about the successful eported data
                            taskListWindow.pushNotification("INFO", qsTr("Successfully imported all data."), qsTr("Source file path") + ": " + composeFullPath(selectedFileName))
                        }
                    }
                }
            }

            SectionHeader {
                //: headline for information about import/export mechanism
                text: qsTr("Information")
            }

            Label {
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge
                wrapMode: Text.WordWrap
                //: Explanation of how importing and exporting data works and where the files are/have to be located.
                text: qsTr("You can export your data to a json formatted file and import it from a json formatted file. Please keep in mind that ALL YOUR DATA containing tasks and lists is stored in a single file!")
            }
        }
    }
}
