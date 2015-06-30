#ifndef TASKSEXPORT_H
#define TASKSEXPORT_H

#include <QObject>
#include <QStringList>

class TasksExport : public QObject
{
    Q_OBJECT
public:
    explicit TasksExport(QObject *parent = 0);

    Q_PROPERTY(QString fileName READ fileName WRITE setFileName NOTIFY fileNameChanged)

    Q_INVOKABLE bool save(const QString &tasks) const;
    Q_INVOKABLE bool remove(const QString &path) const;
    Q_INVOKABLE QStringList getFilesList(const QString &directory) const;
    Q_INVOKABLE QString load(const QString &path) const;

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
    QString mFileName;
};

#endif // TASKSEXPORT_H
