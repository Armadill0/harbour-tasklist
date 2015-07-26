# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-tasklist

CONFIG += sailfishapp c++11
QT += dbus

SOURCES += src/harbour-tasklist.cpp \
    src/tasksexport.cpp

OTHER_FILES += qml/harbour-tasklist.qml \
    qml/pages/CoverPage.qml \
    rpm/harbour-tasklist.yaml \
    harbour-tasklist.desktop \
    qml/localdb.js \
    qml/pages/AboutPage.qml \
    qml/pages/EditPage.qml \
    qml/pages/TaskPage.qml \
    qml/pages/ListPage.qml \
    qml/pages/SettingsPage.qml \
    qml/pages/TaskListItem.qml \
    qml/pages/ExportPage.qml \
    qml/pages/TagPage.qml \
    qml/pages/TagDialog.qml \
    qml/pages/sync/DropboxAuth.qml \
    qml/pages/sync/DropboxSync.qml

include(third_party/notifications.pri)
include(third_party/QtDropbox/qtdropbox.pri)

!defined(TASKLIST_DROPBOX_APPKEY, var) {
    error("Please provide Dropbox appkey as argument of qmake, e.g. 'qmake TASKLIST_DROPBOX_APPKEY=<your appkey here>'")
}
!defined(TASKLIST_DROPBOX_SHAREDSECRET, var) {
    error("Please provide Dropbox shared secret as argument of qmake, e.g. 'qmake TASKLIST_DROPBOX_SHAREDSECRET=<your secret here>'")
}

DEFINES += TASKLIST_DROPBOX_APPKEY=$$TASKLIST_DROPBOX_APPKEY TASKLIST_DROPBOX_SHAREDSECRET=$$TASKLIST_DROPBOX_SHAREDSECRET

localization.files = localization
localization.path = /usr/share/$${TARGET}

INSTALLS += localization

CONFIG += sailfishapp_i18n_idbased

lupdate_only {
    SOURCES = qml/*.qml \
              qml/*.js \
              qml/pages/*.qml \
              qml/pages/sync/*.qml
    TRANSLATIONS = localization-sources/*.ts
}

HEADERS += \
    src/tasksexport.h
