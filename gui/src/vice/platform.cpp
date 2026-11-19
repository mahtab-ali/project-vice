// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "vice/platform.h"

#include <QDir>
#include <QEvent>
#include <QFile>
#include <QFileInfo>
#include <QLocalServer>
#include <QLocalSocket>
#include <QMouseEvent>
#include <QQuickItem>
#include <QQuickWindow>
#include <QRegularExpression>
#include <QSaveFile>
#include <QStandardPaths>
#include <QTouchEvent>

// ---- Touch routing ------------------------------------------------------------

static bool wantsPoint(QQuickItem *item, const QPointF &scene_pos)
{
	if(!item->isVisible() || !item->isEnabled() || item->opacity() < 0.01)
		return false;
	if(item->property("viceTouchTarget").toBool() && item->contains(item->mapFromScene(scene_pos)))
		return true;
	const auto children = item->childItems();
	for(QQuickItem *child : children)
	{
		if(wantsPoint(child, scene_pos))
			return true;
	}
	return false;
}

bool viceRouteToOverlay(QQuickWindow *window, QEvent *event)
{
	// One pointer sequence at a time is enough: a second finger follows the first
	static bool captured = false;
	switch(event->type())
	{
		case QEvent::MouseButtonPress:
			captured = wantsPoint(window->contentItem(), static_cast<QMouseEvent *>(event)->position());
			return captured;
		case QEvent::TouchBegin:
		{
			const auto points = static_cast<QTouchEvent *>(event)->points();
			captured = !points.isEmpty() && wantsPoint(window->contentItem(), points.first().position());
			return captured;
		}
		case QEvent::MouseButtonRelease:
		case QEvent::TouchEnd:
		case QEvent::TouchCancel:
		{
			const bool was = captured;
			captured = false;
			return was;
		}
		case QEvent::MouseMove:
		case QEvent::TouchUpdate:
			return captured;
		default:
			return false;
	}
}

// ---- One window per user ------------------------------------------------------

static QString instanceName()
{
	QString user = qEnvironmentVariable("USER", qEnvironmentVariable("USERNAME", QStringLiteral("user")));
	return QStringLiteral("project-vice-") + user.replace(QRegularExpression(QStringLiteral("[^A-Za-z0-9]")), QStringLiteral("_"));
}

bool viceHandOverToRunningInstance()
{
	QLocalSocket socket;
	socket.connectToServer(instanceName());
	if(!socket.waitForConnected(300))
		return false;
	socket.write("activate\n");
	socket.waitForBytesWritten(300);
	socket.disconnectFromServer();
	return true;
}

void viceListenForLaterInstances(QWindow *window)
{
	// Nothing answered under this name a moment ago, so a leftover socket is from a crash
	QLocalServer::removeServer(instanceName());
	auto server = new QLocalServer(window);
	server->setSocketOptions(QLocalServer::UserAccessOption);
	if(!server->listen(instanceName()))
		return;
	QObject::connect(server, &QLocalServer::newConnection, window, [server, window]() {
		while(QLocalSocket *socket = server->nextPendingConnection())
			socket->deleteLater();
		if(window->visibility() == QWindow::Minimized)
			window->showNormal();
		window->raise();
		window->requestActivate();
	});
}

// ---- Steam Deck controller layout ---------------------------------------------

// The community layout upstream points its own Steam shortcut at
static const char *const playstation_workshop_id = "3049833406";
static const char *const gamepad_template = "controller_neptune_gamepad+mouse.vdf";

QString ViceSteamSetup::configFile()
{
#if defined(Q_OS_LINUX)
	const QString home = QDir::homePath();
	const QStringList bases = { home + "/.steam/steam", home + "/.local/share/Steam" };
	QFileInfo newest;
	for(const QString &base : bases)
	{
		QDir users(base + "/steamapps/common/Steam Controller Configs");
		const auto entries = users.entryInfoList(QDir::Dirs | QDir::NoDotAndDotDot);
		for(const QFileInfo &user : entries)
		{
			QFileInfo file(user.absoluteFilePath() + "/config/configset_controller_neptune.vdf");
			if(file.exists() && (!newest.exists() || file.lastModified() > newest.lastModified()))
				newest = file;
		}
		if(newest.exists())
			break;
	}
	return newest.exists() ? newest.absoluteFilePath() : QString();
#else
	return QString();
#endif
}

// Finds `"key" { ... }` one level inside the file's outer block. Returns the
// span of the whole entry, or -1 when it is not there.
static int findEntry(const QString &text, const QString &key, int *length)
{
	QRegularExpression re(QStringLiteral("\"%1\"\\s*\\{[^{}]*\\}").arg(QRegularExpression::escape(key)),
			QRegularExpression::CaseInsensitiveOption);
	QRegularExpressionMatch m = re.match(text);
	if(!m.hasMatch())
		return -1;
	*length = m.capturedLength();
	return m.capturedStart();
}

QString ViceSteamSetup::currentLayout(const QString &shortcut_name) const
{
	QFile file(configFile());
	if(!file.open(QIODevice::ReadOnly))
		return QString();
	const QString text = QString::fromUtf8(file.readAll());
	int length = 0;
	int at = findEntry(text, shortcut_name.toLower(), &length);
	if(at < 0)
		return QString();
	const QString entry = text.mid(at, length);
	if(entry.contains(QLatin1String(playstation_workshop_id)))
		return QStringLiteral("playstation");
	if(entry.contains(QLatin1String(gamepad_template)))
		return QStringLiteral("gamepad");
	return QStringLiteral("other");
}

QString ViceSteamSetup::applyLayout(const QString &shortcut_name, const QString &layout)
{
	const QString path = configFile();
	if(path.isEmpty())
		return tr("Steam's controller settings were not found on this computer.");
	QFile file(path);
	if(!file.open(QIODevice::ReadOnly))
		return tr("Steam's controller settings could not be read.");
	QString text = QString::fromUtf8(file.readAll());
	file.close();

	const QString key = shortcut_name.toLower();
	const QString value = layout == QLatin1String("playstation")
		? QStringLiteral("\t\t\"workshop\"\t\t\"%1\"\n").arg(QLatin1String(playstation_workshop_id))
		: QStringLiteral("\t\t\"template\"\t\t\"%1\"\n").arg(QLatin1String(gamepad_template));
	const QString entry = QStringLiteral("\"%1\"\n\t{\n%2\t}").arg(key, value);

	int length = 0;
	int at = findEntry(text, key, &length);
	if(at >= 0)
		text.replace(at, length, entry);
	else
	{
		// Before the brace that closes the file's outer block
		int close = text.lastIndexOf(QLatin1Char('}'));
		if(close < 0 || text.count(QLatin1Char('{')) != text.count(QLatin1Char('}')))
			return tr("Steam's controller settings are in a form this app does not recognise. Nothing was changed.");
		text.insert(close, QStringLiteral("\t%1\n").arg(entry));
	}
	if(text.count(QLatin1Char('{')) != text.count(QLatin1Char('}')))
		return tr("Steam's controller settings are in a form this app does not recognise. Nothing was changed.");

	// Keep what was there, once, before the first change
	const QString backup = path + QStringLiteral(".before-project-vice");
	if(!QFile::exists(backup))
		QFile::copy(path, backup);

	QSaveFile out(path);
	if(!out.open(QIODevice::WriteOnly) || out.write(text.toUtf8()) < 0 || !out.commit())
		return tr("Steam's controller settings could not be saved.");
	return QString();
}
