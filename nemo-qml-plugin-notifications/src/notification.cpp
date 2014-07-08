/*
 * Copyright (C) 2013 Jolla Ltd.
 * Contact: Vesa Halttunen <vesa.halttunen@jollamobile.com>
 *
 * You may use this file under the terms of the BSD license as follows:
 *
 * "Redistribution and use in source and binary forms, with or without
 * modification, are permitted provided that the following conditions are
 * met:
 *   * Redistributions of source code must retain the above copyright
 *     notice, this list of conditions and the following disclaimer.
 *   * Redistributions in binary form must reproduce the above copyright
 *     notice, this list of conditions and the following disclaimer in
 *     the documentation and/or other materials provided with the
 *     distribution.
 *   * Neither the name of Nemo Mobile nor the names of its contributors
 *     may be used to endorse or promote products derived from this
 *     software without specific prior written permission.
 *
 * THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
 * "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
 * LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
 * A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
 * OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 * SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 * LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 * DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
 * THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
 * (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
 * OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE."
 */
#include "notificationmanagerproxy.h"
#include "notification.h"

const char *HINT_CATEGORY = "category";
const char *HINT_ITEM_COUNT = "x-nemo-item-count";
const char *HINT_TIMESTAMP = "x-nemo-timestamp";
const char *HINT_PREVIEW_BODY = "x-nemo-preview-body";
const char *HINT_PREVIEW_SUMMARY = "x-nemo-preview-summary";
const char *HINT_REMOTE_ACTION = "x-nemo-remote-action-default";

//! A proxy for accessing the notification manager
Q_GLOBAL_STATIC_WITH_ARGS(NotificationManagerProxy, notificationManagerProxyInstance, ("org.freedesktop.Notifications", "/org/freedesktop/Notifications", QDBusConnection::sessionBus()))

NotificationManagerProxy *notificationManager()
{
    if (!notificationManagerProxyInstance.exists()) {
        qDBusRegisterMetaType<Notification>();
        qDBusRegisterMetaType<QList<Notification> >();
    }

    return notificationManagerProxyInstance();
}

/*!
    \qmltype Notification
    \brief Allows notifications to be published

    The Notification class is a convenience class for using notifications
    based on the
    \l {http://www.galago-project.org/specs/notification/0.9/} {Desktop
    Notifications Specification} as implemented in Nemo.

    Since the Nemo implementation allows static notification parameters,
    such as icon, urgency, priority and user closability definitions, to
    be defined as part of notification category definitions, this
    convenience class is kept as simple as possible by allowing only the
    dynamic parameters, such as summary and body text, item count and
    timestamp to be defined. Other parameters should be defined in the
    notification category definition. Please refer to Lipstick documentation
    for a complete description of the category definition files.

    An example of the usage of this class from a Qml application:

    \qml
    Button {
        Notification {
            id: notification
            category: "x-nemo.example"
            summary: "Notification summary"
            body: "Notification body"
            previewSummary: "Notification preview summary"
            previewBody: "Notification preview body"
            itemCount: 5
            timestamp: "2013-02-20 18:21:00"
            remoteDBusCallServiceName: "org.nemomobile.example"
            remoteDBusCallObjectPath: "/example"
            remoteDBusCallInterface: "org.nemomobile.example"
            remoteDBusCallMethodName: "doSomething"
            remoteDBusCallArguments: [ "argument", 1 ]
            onClicked: console.log("Clicked")
            onClosed: console.log("Closed, reason: " + reason)
        }
        text: "Application notification, ID " + notification.replacesId
        onClicked: notification.publish()
    }
    \endqml

    An example category definition file
    /usr/share/lipstick/notificationcategories/x-nemo.example.conf:

    \code
    x-nemo-icon=icon-lock-sms
    x-nemo-preview-icon=icon-s-status-sms
    x-nemo-feedback=sms
    x-nemo-priority=70
    x-nemo-user-removable=true
    x-nemo-user-closeable=false
    \endcode

    After publishing the ID of the notification can be found from the
    replacesId property.

    Notification::notifications() can be used to fetch notifications
    created by the calling application.
 */
Notification::Notification(QObject *parent) :
    QObject(parent),
    replacesId_(0)
{
    connect(notificationManager(), SIGNAL(ActionInvoked(uint,QString)), this, SLOT(checkActionInvoked(uint,QString)));
    connect(notificationManager(), SIGNAL(NotificationClosed(uint,uint)), this, SLOT(checkNotificationClosed(uint,uint)));
    connect(this, SIGNAL(remoteDBusCallChanged()), this, SLOT(setRemoteActionHint()));
}

/*!
    \qmlproperty QString Notification::category

    The type of notification this is. Defaults to an empty string.
 */
QString Notification::category() const
{
    return hints_.value(HINT_CATEGORY).toString();
}

void Notification::setCategory(const QString &category)
{
    if (category != this->category()) {
        hints_.insert(HINT_CATEGORY, category);
        emit categoryChanged();
    }
}

/*!
    \qmlproperty uint Notification::replacesId

    The optional notification ID that this notification replaces. The server must atomically (ie with no flicker or other visual cues) replace the given notification with this one. This allows clients to effectively modify the notification while it's active. A value of value of 0 means that this notification won't replace any existing notifications. Defaults to 0.
 */
uint Notification::replacesId() const
{
    return replacesId_;
}

void Notification::setReplacesId(uint id)
{
    if (replacesId_ != id) {
        replacesId_ = id;
        emit replacesIdChanged();
    }
}

/*!
    \qmlproperty QString Notification::summary

    The summary text briefly describing the notification. Defaults to an empty string.
 */
QString Notification::summary() const
{
    return summary_;
}

void Notification::setSummary(const QString &summary)
{
    if (summary_ != summary) {
        summary_ = summary;
        emit summaryChanged();
    }
}

/*!
    \qmlproperty QString Notification::body

    The optional detailed body text. Can be empty. Defaults to an empty string.
 */
QString Notification::body() const
{
    return body_;
}

void Notification::setBody(const QString &body)
{
    if (body_ != body) {
        body_ = body;
        emit bodyChanged();
    }
}

/*!
    \qmlproperty QDateTime Notification::timestamp

    The timestamp for the notification. Should be set to the time when the event the notification is related to has occurred. Defaults to current time.
 */
QDateTime Notification::timestamp() const
{
    return hints_.value(HINT_TIMESTAMP).toDateTime();
}

void Notification::setTimestamp(const QDateTime &timestamp)
{
    if (timestamp != this->timestamp()) {
        hints_.insert(HINT_TIMESTAMP, timestamp.toString(Qt::ISODate));
        emit timestampChanged();
    }
}

/*!
    \qmlproperty QString Notification::previewSummary

    Summary text to be shown in the preview banner for the notification, if any. Defaults to an empty string.
 */
QString Notification::previewSummary() const
{
    return hints_.value(HINT_PREVIEW_SUMMARY).toString();
}

void Notification::setPreviewSummary(const QString &previewSummary)
{
    if (previewSummary != this->previewSummary()) {
        hints_.insert(HINT_PREVIEW_SUMMARY, previewSummary);
        emit previewSummaryChanged();
    }
}

/*!
    \qmlproperty QString Notification::previewBody

    Body text to be shown in the preview banner for the notification, if any. Defaults to an empty string.
 */
QString Notification::previewBody() const
{
    return hints_.value(HINT_PREVIEW_BODY).toString();
}

void Notification::setPreviewBody(const QString &previewBody)
{
    if (previewBody != this->previewBody()) {
        hints_.insert(HINT_PREVIEW_BODY, previewBody);
        emit previewBodyChanged();
    }
}

/*!
    \qmlproperty int Notification::itemCount

    The number of items represented by the notification. For example, a single notification can represent four missed calls by setting the count to 4. Defaults to 1.
 */
int Notification::itemCount() const
{
    return hints_.value(HINT_ITEM_COUNT).toInt();
}

void Notification::setItemCount(int itemCount)
{
    if (itemCount != this->itemCount()) {
        hints_.insert(HINT_ITEM_COUNT, itemCount);
        emit itemCountChanged();
    }
}

/*!
    \qmlmethod void Notification::publish()

    Publishes the notification. If replacesId is 0, it will be a new
    notification. Otherwise the existing notification with the given ID
    is updated with the new details.
*/
void Notification::publish()
{
    setReplacesId(notificationManager()->Notify(appName(), replacesId_, QString(), summary_, body_, (QStringList() << "default" << ""), hints_, -1));
}

/*!
    \qmlmethod void Notification::close()

    Closes the notification if it has been published.
*/
void Notification::close()
{
    if (replacesId_ != 0) {
        notificationManager()->CloseNotification(replacesId_);
        setReplacesId(0);
    }
}

/*!
    \qmlsignal Notification::clicked()

    Sent when the notification is clicked (its default action is invoked).
*/
void Notification::checkActionInvoked(uint id, QString actionKey)
{
    if (id == replacesId_ && actionKey == "default") {
        emit clicked();
    }
}

/*!
    \qmlsignal Notification::closed(uint reason)

    Sent when the notification has been closed.
    \a reason is 1 if the notification expired, 2 if the notification was
    dismissed by the user, 3 if the notification was closed by a call to
    CloseNotification.
*/
void Notification::checkNotificationClosed(uint id, uint reason)
{
    if (id == replacesId_) {
        emit closed(reason);
        setReplacesId(0);
    }
}

/*!
    \qmlproperty QString Notification::remoteDBusCallServiceName

    The service name of the D-Bus call for this notification. Defaults to an empty string.
 */
QString Notification::remoteDBusCallServiceName() const
{
    return remoteDBusCallServiceName_;
}

void Notification::setRemoteDBusCallServiceName(const QString &serviceName)
{
    if (remoteDBusCallServiceName_ != serviceName) {
        remoteDBusCallServiceName_ = serviceName;
        emit remoteDBusCallChanged();
    }
}

/*!
    \qmlproperty QString Notification::remoteDBusCallObjectPath

    The object path of the D-Bus call for this notification. Defaults to an empty string.
 */
QString Notification::remoteDBusCallObjectPath() const
{
    return remoteDBusCallObjectPath_;
}

void Notification::setRemoteDBusCallObjectPath(const QString &objectPath)
{
    if (remoteDBusCallObjectPath_ != objectPath) {
        remoteDBusCallObjectPath_ = objectPath;
        emit remoteDBusCallChanged();
    }
}

/*!
    \qmlproperty QString Notification::remoteDBusCallInterface

    The interface of the D-Bus call for this notification. Defaults to an empty string.
 */
QString Notification::remoteDBusCallInterface() const
{
    return remoteDBusCallInterface_;
}

void Notification::setRemoteDBusCallInterface(const QString &interface)
{
    if (remoteDBusCallInterface_ != interface) {
        remoteDBusCallInterface_ = interface;
        emit remoteDBusCallChanged();
    }
}

/*!
    \qmlproperty QString Notification::remoteDBusCallMethodName

    The method name of the D-Bus call for this notification. Defaults to an empty string.
 */
QString Notification::remoteDBusCallMethodName() const
{
    return remoteDBusCallMethodName_;
}

void Notification::setRemoteDBusCallMethodName(const QString &methodName)
{
    if (remoteDBusCallMethodName_ != methodName) {
        remoteDBusCallMethodName_ = methodName;
        emit remoteDBusCallChanged();
    }
}

/*!
    \qmlproperty QVariantList Notification::remoteDBusCallArguments

    The arguments of the D-Bus call for this notification. Defaults to an empty variant list.
 */
QVariantList Notification::remoteDBusCallArguments() const
{
    return remoteDBusCallArguments_;
}

void Notification::setRemoteDBusCallArguments(const QVariantList &arguments)
{
    if (remoteDBusCallArguments_ != arguments) {
        remoteDBusCallArguments_ = arguments;
        emit remoteDBusCallChanged();
    }
}

void Notification::setRemoteActionHint()
{
    QString s;

    if (!remoteDBusCallServiceName_.isEmpty() && !remoteDBusCallObjectPath_.isEmpty() && !remoteDBusCallInterface_.isEmpty() && !remoteDBusCallMethodName_.isEmpty()) {
        s.append(remoteDBusCallServiceName_).append(' ');
        s.append(remoteDBusCallObjectPath_).append(' ');
        s.append(remoteDBusCallInterface_).append(' ');
        s.append(remoteDBusCallMethodName_);

        foreach(const QVariant &arg, remoteDBusCallArguments_) {
            // Serialize the QVariant into a QBuffer
            QBuffer buffer;
            buffer.open(QIODevice::ReadWrite);
            QDataStream stream(&buffer);
            stream << arg;
            buffer.close();

            // Encode the contents of the QBuffer in Base64
            s.append(' ');
            s.append(buffer.buffer().toBase64().data());
        }
    }

    hints_.insert(HINT_REMOTE_ACTION, s);
}

/*!
    \fn QVariant Notification::hintValue(const QString &hint) const

    Returns the value of the given \a hint .
*/
QVariant Notification::hintValue(const QString &hint) const
{
    return hints_.value(hint);
}

/*!
    \fn void Notification::setHintValue(const QString &hint, const QVariant &value)

    Sets the value of the given \a hint to a given \a value .
*/
void Notification::setHintValue(const QString &hint, const QVariant &value)
{
    hints_.insert(hint, value);
}

/*!
    \qmlmethod void Notification::notifications()

    Returns a list of notifications created by the calling application.
*/
QList<QObject*> Notification::notifications()
{
    QList<Notification> notifications = notificationManager()->GetNotifications(appName());
    QList<QObject*> objects;
    foreach (const Notification &notification, notifications) {
        objects.append(new Notification(notification));
    }
    return objects;
}

QString Notification::appName()
{
    return QFileInfo(QCoreApplication::arguments()[0]).fileName();
}

Notification::Notification(const Notification &notification) :
    QObject(notification.parent()),
    replacesId_(notification.replacesId_),
    summary_(notification.summary_),
    body_(notification.body_),
    hints_(notification.hints_),
    remoteDBusCallServiceName_(notification.remoteDBusCallServiceName_),
    remoteDBusCallObjectPath_(notification.remoteDBusCallObjectPath_),
    remoteDBusCallInterface_(notification.remoteDBusCallInterface_),
    remoteDBusCallMethodName_(notification.remoteDBusCallMethodName_),
    remoteDBusCallArguments_(notification.remoteDBusCallArguments_)
{
}

QDBusArgument &operator<<(QDBusArgument &argument, const Notification &notification)
{
    argument.beginStructure();
    argument << Notification::appName();
    argument << notification.replacesId_;
    argument << QString();
    argument << notification.summary_;
    argument << notification.body_;
    argument << (QStringList() << "default" << "");
    argument << notification.hints_;
    argument << -1;
    argument.endStructure();
    return argument;
}

const QDBusArgument &operator>>(const QDBusArgument &argument, Notification &notification)
{
    QString tempString;
    QStringList tempStringList;
    int tempInt;

    argument.beginStructure();
    argument >> tempString;
    argument >> notification.replacesId_;
    argument >> tempString;
    argument >> notification.summary_;
    argument >> notification.body_;
    argument >> tempStringList;
    argument >> notification.hints_;
    argument >> tempInt;
    argument.endStructure();
    return argument;
}
