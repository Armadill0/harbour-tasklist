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

#ifdef QT_QML_DEBUG
#include <QtQuick>
#endif

#include <sailfishapp.h>
#include <QTranslator>
#include <QLocale>
#include <QGuiApplication>
#include <QtGui>
#include <QtQml>

// third party code
#include <notification.h>


int main(int argc, char *argv[])
{
    /*  Internationalization Support
        thanks to Antoine Reversat who mentioned this here:
        https://www.mail-archive.com/devel@lists.sailfishos.org/msg02602.html */
    QGuiApplication* app = SailfishApp::application(argc, argv);
    QString locale = QLocale::system().name();
    QTranslator translator;

    translator.load(locale,SailfishApp::pathTo(QString("localization")).toLocalFile());
    app->installTranslator(&translator);

    qmlRegisterType<Notification>("harbour.tasklist.notifications", 1, 0, "Notification");

    return SailfishApp::main(argc, argv);
}
