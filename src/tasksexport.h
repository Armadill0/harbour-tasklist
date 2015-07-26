#ifndef TASKSEXPORT_H
#define TASKSEXPORT_H

#include <QObject>
#include <QStringList>

#include <qtdropbox.h>

class TasksExport : public QObject
{
    Q_OBJECT
public:
    explicit TasksExport(QObject *parent = 0);
    ~TasksExport();

    Q_PROPERTY(QString fileName READ fileName WRITE setFileName NOTIFY fileNameChanged)

    Q_INVOKABLE bool save(const QString &tasks) const;
    Q_INVOKABLE bool remove(const QString &path) const;
    Q_INVOKABLE QStringList getFilesList(const QString &directory) const;
    Q_INVOKABLE QString load(const QString &path) const;

    Q_INVOKABLE QString dropboxAuthorizeLink();
    /* returns 3 elements: Dropbox username, OAuth token secret and OAuth token */
    Q_INVOKABLE QStringList getDropboxCredentials();
    Q_INVOKABLE void setDropboxCredentials(const QString &token, const QString &tokenSecret);
    /* returns revision hash of the uploaded file or empty string if fails */
    Q_INVOKABLE QString uploadToDropbox(const QString &tasks);
    /* { revision hash, JSON data } */
    Q_INVOKABLE QStringList downloadFromDropbox();
    Q_INVOKABLE QString getRevision();

    QString fileName() const {
        return mFileName;
    }

    // proxy to Qt QSettings, because QtQuick module "Qt.labs.settings" is not available
    Q_PROPERTY(QString language READ language WRITE setLanguage)
    QString language();
    void setLanguage(const QString &lang);

signals:
    void fileNameChanged(const QString &fileName);

public slots:
    void setFileName(const QString &fileName) {
        mFileName = fileName;
    }

private:
    void initDropbox();
    void exitDropbox();

    QString mFileName;
    QDropbox *dropbox;
    QString dropboxPath;
};

#endif // TASKSEXPORT_H
