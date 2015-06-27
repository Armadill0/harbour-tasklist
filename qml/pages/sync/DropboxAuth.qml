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
import ".."

Page {
    id: dropboxAuth
    allowedOrientations: Orientation.All

    property alias url: webView.url

    signal accepted
    signal declined

    SilicaWebView {
        id: webView
        anchors.fill: parent

        onLoadingChanged: {
            // wait until request is executed: value "2" was determined from experiment
            if (loadRequest.status !== 2)
                return
            var curUrl = loadRequest.url.toString()
            console.log("loaded " + curUrl)
            if (curUrl === "https://www.dropbox.com/1/oauth/authorize_submit") {
                accepted()
                pageStack.pop()
            } else if (curUrl === "https://www.dropbox.com/home") {
                declined()
                pageStack.pop()
            }
        }
    }

    BusyIndicator {
        running: webView.loading
        anchors.centerIn: parent
        size: BusyIndicatorSize.Large
    }
}
