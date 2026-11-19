// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Project Vice: small pieces of platform behaviour the Vice UI needs.

#ifndef VICE_PLATFORM_H
#define VICE_PLATFORM_H

#include <QObject>
#include <QString>

class QEvent;
class QQuickWindow;
class QWindow;

/**
 * During a stream every touch and click goes to the game. This says when one
 * should go to the app's own interface instead: when it starts on a visible
 * item that declares `property bool viceTouchTarget: true` (a notice, the
 * quick-menu tab). The answer holds from press to release.
 */
bool viceRouteToOverlay(QQuickWindow *window, QEvent *event);

/**
 * One window per user. A second launch asks the first to come forward and
 * returns true, and the caller should then exit. Starting the app twice would
 * otherwise show a fresh home screen while the first copy is still streaming.
 */
bool viceHandOverToRunningInstance();
void viceListenForLaterInstances(QWindow *window);

/**
 * Chooses the Steam Input layout Steam uses for this app on a Steam Deck.
 * Exposed to QML as vice.backend/SteamSetup. Steam reads the file at start,
 * so a change takes effect after Steam restarts.
 */
class ViceSteamSetup : public QObject
{
	Q_OBJECT
	// True when Steam's controller settings for a Steam Deck are present on this computer
	Q_PROPERTY(bool available READ available CONSTANT)

	public:
		explicit ViceSteamSetup(QObject *parent = nullptr) : QObject(parent) {}

		bool available() const { return !configFile().isEmpty(); }

		// "playstation": the community Remote Play layout (touchpad, PS button, gyro).
		// "gamepad": Steam's own gamepad template. Returns an empty string on
		// success, otherwise what went wrong.
		Q_INVOKABLE QString applyLayout(const QString &shortcutName, const QString &layout);
		// "playstation", "gamepad", or "" when Steam has nothing set for this shortcut
		Q_INVOKABLE QString currentLayout(const QString &shortcutName) const;

	private:
		static QString configFile();
};

#endif // VICE_PLATFORM_H
