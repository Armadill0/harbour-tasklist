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

import QtQuick 2.1
import Sailfish.Silica 1.0
import "../localdb.js" as DB
import harbour.tasklist.tasks_export 1.0

Page {
    id: exportPage
    allowedOrientations: Orientation.All

    property int selectedElementId: -1
    property string selectedFileName : ""
    property string directory: StandardPaths.documents + "/harbour-tasklist"

    function composeFullPath(baseName) {
        var suffix = ".json"
        if (baseName.indexOf(suffix, baseName.length - suffix.length) === -1)
            baseName += ".json"
        return directory + "/" + baseName;
    }

    function truncatePath(path) {
        var pos = 0
        while (path.length - pos > 38) {
            var j = pos + 1
            while (j < path.length && path[j] !== '/')
                ++j
            if (j < path.length)
                pos = j
            else
                break
        }
        if (pos > 0)
            return "..." + path.substring(pos)
        return path
    }

    function getFiles() {
        var list = exporter.getFilesList(directory);
        importFilesModel.clear()
        if (list.length < 1) {
            //: informing user that no former exports are available
            //% "No files for import available."
            importFilesModel.append({fileName: qsTrId("no-importfiles-placeholder"), elementId: 0});
        } else {
            for (var i = 0; i < list.length; ++i)
                importFilesModel.append({fileName: list[i], elementId: i + 1});
        }
    }

    SilicaFlickable {
        anchors {
            fill: parent
            bottomMargin: Theme.paddingLarge
        }
        contentHeight: column.height

        VerticalScrollDecorator { }

        Column {
            id: column
            width: parent.width
            spacing: Theme.paddingLarge

            PageHeader {
                //: export/import page headline
                //% "Export/Import"
                title: qsTrId("export-import-header") + " - TaskList"
            }

            SectionHeader {
                //: headline for exports
                //% "Export target"
                text: qsTrId("export-header")
            }

            TextField {
                id: exportName
                width: parent.width
                //: placeholder message to remind the user that he has to enter a name for the data export
                //% "Enter a file name for export"
                placeholderText: qsTrId("export-file-placeholder")
                onTextChanged: {
                    var path = composeFullPath(text)
                    label = truncatePath(path)
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
                //% "Export data"
                text: qsTrId("export-button")
                width: parent.width * 0.75
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.leftMargin: Theme.paddingLarge
                anchors.rightMargin: Theme.paddingLarge
                enabled: exportName.acceptableInput

                onClicked: {
                    var json = DB.dumpData()
                    var ret = exporter.save(json)
                    if (ret) {
                        //: informational notification about the successful eported data
                        //% "Successfully exported all data."
                        taskListWindow.pushNotification("INFO", qsTrId("data-export-success"),
                                                        //% "File path"
                                                        qsTrId("data-export-path") + ": " + composeFullPath(exportName.text))
                        exportName.text = ""
                        getFiles()
                    }
                }
            }

            SectionHeader {
                //: headline for imports
                //% "Select a file to import"
                text: qsTrId("select-file-header")
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
                        description: elementId !== 0 ? truncatePath(composeFullPath(fileName)) : ""
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
                spacing: 2 * Theme.paddingLarge
                x: Theme.paddingLarge

                Button {
                    id: deleteButton
                    width: parent.width / 2 - 2 * Theme.paddingLarge
                    //: Button to delete the selected data file
                    //% "Delete file"
                    text: qsTrId("delete-file-button")
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
                    width: parent.width / 2 - 2 * Theme.paddingLarge
                    //: Button to import data form the selected file
                    //% "Import data"
                    text: qsTrId("import-button")
                    enabled: selectedElementId !== -1

                    onClicked: {
                        if (selectedFileName.length === 0)
                            return
                        var json = exporter.load(composeFullPath(selectedFileName));
                        if (DB.importData(json)) {
                            //: informational notification about the successful eported data
                            //% "Successfully imported all data."
                            taskListWindow.pushNotification("INFO", qsTrId("data-import-success"),
                                                            //% "Source file path"
                                                            qsTrId("data-import-path") + ": " + composeFullPath(selectedFileName))
                        }
                    }
                }
            }

            SectionHeader {
                //: headline for information about import/export mechanism
                //% "Information"
                text: qsTrId("information-label")
            }

            Label {
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge
                wrapMode: Text.WordWrap
                //: Explanation of how importing and exporting data works and where the files are/have to be located.
                //% "You can export your data to a json formatted file and import it from a json formatted file. Please keep in mind that ALL YOUR DATA containing tasks and lists is stored in a single file!"
                text: qsTrId("export-import-description")
            }

            SectionHeader {
                //: headline for the database purge
                //% "Drop data (very destructive!!!)"
                text: qsTrId("drop-database-header")
            }

            Label {
                width: parent.width - 2 * Theme.paddingLarge
                x: Theme.paddingLarge
                wrapMode: Text.WordWrap
                //: warn user of destructive drop DB function
                //% "CAUTION: This function will drop all your data immediately! So only use this if you know what you're doing!"
                text: qsTrId("drop-database-warning")
                color: "red"
            }

            TextSwitch {
                id: dropDBconfirmation
                width: parent.width
                //: let user confirm the database purge
                //% "Yes, I know what I'm doing."
                text: qsTrId("drop-database-confirmation")
            }

            Button {
                width: parent.width * 0.75
                anchors.horizontalCenter: parent.horizontalCenter
                //: Button to import data form the selected file
                //% "Drop database"
                text: qsTrId("drop-database-button")
                enabled: dropDBconfirmation.checked

                onClicked: {
                    if (DB.dropDB())
                        //: informational notification about the successful dropped data tables
                        //% "Successfully dropped all data."
                        taskListWindow.pushNotification("WARNING", qsTrId("drop-database-success"),
                                                        //% "Please restart TaskList to work with the new database."
                                                        qsTrId("drop-database-detail"))
                }
            }
        }
    }
}
