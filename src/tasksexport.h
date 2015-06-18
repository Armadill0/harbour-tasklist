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

    Q_INVOKABLE bool authorizeInDropbox();
    /* returns 3 elements: OAuth token, OAuth token secret and Dropbox username */
    Q_INVOKABLE QStringList getDropboxCredentials();
    Q_INVOKABLE void setDropboxCredentials(const QString &token, const QString &tokenSecret);
    Q_INVOKABLE QString downloadFromDropbox();
    Q_INVOKABLE bool uploadToDropbox(const QString &tasks);

    QString fileName() const {
        return mFileName;
    }
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
