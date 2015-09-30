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
#include <QProcess>
#include <QQuickView>
#include <QSettings>
#include "tasksexport.h"

int main(int argc, char *argv[])
{
    QProcess appinfo;
    QString appversion;
    QString pkgname = "harbour-tasklist";
    QString appname = "TaskList";

    QCoreApplication::setOrganizationName(pkgname);
    QCoreApplication::setApplicationName(pkgname);

    // read app version from rpm database on startup
    appinfo.start("/bin/rpm", QStringList() << "-qa" << "--queryformat" << "%{version}" << pkgname);
    appinfo.waitForFinished(-1);
    if (appinfo.bytesAvailable() > 0) {
        appversion = appinfo.readAll();
    }

    /*  Internationalization Support
        thanks to Antoine Reversat who mentioned this here:
        https://www.mail-archive.com/devel@lists.sailfishos.org/msg02602.html */
    QGuiApplication* app = SailfishApp::application(argc, argv);

    // load default translator and system locale's translator afterwards
    QTranslator defaultTranslator;
    defaultTranslator.load("en_US", SailfishApp::pathTo(QString("localization")).toLocalFile());
    app->installTranslator(&defaultTranslator);

    QSettings settings;
    QString locale = settings.value("language", "").toString();
    if (locale.isEmpty() || locale == QString("system_default")) {
        /* use system locale by default */
        if (locale.isEmpty())
            settings.setValue("language", "system_default");
        locale = QLocale::system().name();
    }

    QTranslator translator;
    translator.load(locale, SailfishApp::pathTo(QString("localization")).toLocalFile());
    app->installTranslator(&translator);

    qmlRegisterType<TasksExport>("harbour.tasklist.tasks_export", 1, 0, "TasksExport");

    QQuickView* view = SailfishApp::createView();
    QObject::connect(view->engine(), SIGNAL(quit()), app, SLOT(quit()));
    view->rootContext()->setContextProperty("version", appversion);
    view->rootContext()->setContextProperty("appname", appname);
    view->setSource(SailfishApp::pathTo("qml/harbour-tasklist.qml"));
    view->show();

    return app->exec();
}
