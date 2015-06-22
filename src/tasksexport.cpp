#include "tasksexport.h"
#include <QDesktopServices>
#include <QDirIterator>
#include <QFile>
#include <QTextStream>

// FIXME
#include <QDebug>

TasksExport::TasksExport(QObject *parent) :
    QObject(parent), dropbox(NULL), dropboxPath("/sandbox/harbour-tasklist.json")
{
}

TasksExport::~TasksExport()
{
    exitDropbox();
}

QString TasksExport::load(const QString &path) const
{
    QString result;
    if (path.isEmpty())
        return result;
    QFile file(path);
    if (!file.open(QFile::ReadOnly | QFile::Text))
        return result;

    QTextStream in(&file);
    in.setCodec("UTF-8");
    result = in.readAll();

    file.close();
    return result;
}

QStringList TasksExport::getFilesList(const QString &directory) const
{
    QStringList result;
    QDirIterator iter(directory);
    while (iter.hasNext()) {
        iter.next();
        QFileInfo info(iter.filePath());
        if (info.isFile() && info.suffix() == "json")
            result.append(info.completeBaseName());
    }
    return result;
}

bool TasksExport::save(const QString &tasks) const
{
    if (mFileName.isEmpty())
        return false;
    QFile file(mFileName);
    if (!file.open(QFile::WriteOnly | QFile::Truncate))
        return false;

    QTextStream out(&file);
    out.setCodec("UTF-8");
    out << tasks;

    file.close();
    return true;
}

bool TasksExport::remove(const QString &path) const
{
    if (path.isEmpty())
        return false;

    QFile file(path);
    file.remove(path);
    return true;
}

QString TasksExport::dropboxAuthorizeLink()
{
    initDropbox();
    if (!dropbox->requestTokenAndWait()) {
        qDebug() << "Dropbox auth error:" << dropbox->errorString();
        dropbox->clearError();
        exitDropbox();
        return "";
    }
    return dropbox->authorizeLink().toString();
}

QStringList TasksExport::getDropboxCredentials()
{
    QStringList result;
    if(dropbox->requestAccessTokenAndWait()) {
        QDropboxAccount acc = dropbox->requestAccountInfoAndWait();
        result.append(acc.displayName());

        result.append(dropbox->tokenSecret());
        result.append(dropbox->token());
    }
    return result;
}

void TasksExport::setDropboxCredentials(const QString &token, const QString &tokenSecret)
{
    if (!dropbox)
        initDropbox();
    dropbox->setToken(token);
    dropbox->setTokenSecret(tokenSecret);
}

QString TasksExport::downloadFromDropbox()
{
    // TODO impl.
    return "";
}

bool TasksExport::uploadToDropbox(const QString &tasks)
{
    QDropboxFile file(dropbox);
    file.setFilename(dropboxPath);
    if (!file.open(QIODevice::WriteOnly)) {
        qDebug() << "couldn't open file at Dropbox:" << dropboxPath;
        return false;
    }
    QTextStream out(&file);
    out << tasks;
    out.flush();
    if (!file.flush()) {
        qDebug() << "couldn't flush data to Dropbox";
        return false;
    }
    file.close();
    qDebug() << "file is written";
    return true;
}

void TasksExport::initDropbox()
{
    // FIXME there may be a better way to provide Dropbox keys from outside
#define STRINGIFY2(X) #X
#define STRINGIFY(X) STRINGIFY2(X)

    dropbox = new QDropbox;
    dropbox->setKey(STRINGIFY(TASKLIST_DROPBOX_APPKEY));
    dropbox->setSharedSecret(STRINGIFY(TASKLIST_DROPBOX_SHAREDSECRET));

#undef STRINGIFY
#undef STRINGIFY2
}

void TasksExport::exitDropbox()
{
    if (dropbox) {
        delete dropbox;
        dropbox = NULL;
    }
}
