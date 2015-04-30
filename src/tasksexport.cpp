#include "tasksexport.h"
#include <QDirIterator>
#include <QFile>
#include <QTextStream>

TasksExport::TasksExport(QObject *parent) :
    QObject(parent)
{
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
