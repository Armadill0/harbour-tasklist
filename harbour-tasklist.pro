# The name of your app.
# NOTICE: name defined in TARGET has a corresponding QML filename.
#         If name defined in TARGET is changed, following needs to be
#         done to match new name:
#         - corresponding QML filename must be changed
#         - desktop icon filename must be changed
#         - desktop filename must be changed
#         - icon definition filename in desktop file must be changed
TARGET = harbour-tasklist

CONFIG += sailfishapp

SOURCES += src/harbour-tasklist.cpp

OTHER_FILES += qml/harbour-tasklist.qml \
    qml/cover/CoverPage.qml \
    rpm/harbour-tasklist.yaml \
    harbour-tasklist.desktop \
    qml/localdb.js \
    qml/pages/AboutPage.qml \
    qml/pages/EditPage.qml \
    qml/pages/TaskPage.qml \
    qml/pages/ListPage.qml \
    qml/pages/SettingsPage.qml

localization.files = localization
localization.path = /usr/share/$${TARGET}

INSTALLS += localization

lupdate_only {
    SOURCES = qml/*.qml \
                qml/pages/*.qml
    TRANSLATIONS = localization/fr.ts \
                    localization/en.ts
}

