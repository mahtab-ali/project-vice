// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Project Vice: pre-flight check of the link to one console.

#ifndef VICE_NETCHECK_H
#define VICE_NETCHECK_H

#include <QElapsedTimer>
#include <QHostAddress>
#include <QObject>
#include <QTcpSocket>
#include <QTimer>
#include <QUdpSocket>
#include <QVariantList>

/**
 * Two probes every intervalMs.
 *
 * Loss comes from the console's own discovery request ("SRCH"), the request the
 * app already sends to find consoles: a probe with no reply before the next one
 * counts as lost.
 *
 * Ping and jitter come from timing a TCP connection to the port a session is
 * requested on. The discovery reply cannot be used for them: a PS5 takes about
 * 100 ms to answer it however good the network is (104 ms was measured on a link
 * whose real round trip was 3 ms, which made a perfect connection read as "expect
 * stutter"). A TCP connection is answered by the console's network stack at once,
 * open or refused, so its time is the network's. If the console does not answer
 * TCP at all, the discovery times are used as before.
 * Exposed to QML as vice.backend/NetCheck.
 */
class ViceNetCheck : public QObject
{
	Q_OBJECT
	Q_PROPERTY(bool running READ running NOTIFY runningChanged)
	Q_PROPERTY(int expected READ expected NOTIFY changed)
	Q_PROPERTY(int sent READ sent NOTIFY changed)
	Q_PROPERTY(int received READ received NOTIFY changed)
	// Round trip of each probe in ms, in order; -1 for a probe that got no reply
	Q_PROPERTY(QVariantList samples READ samples NOTIFY changed)
	// Median round trip, mean change between consecutive replies, share of probes lost. NaN until measured.
	Q_PROPERTY(double ping READ ping NOTIFY changed)
	Q_PROPERTY(double jitter READ jitter NOTIFY changed)
	Q_PROPERTY(double loss READ loss NOTIFY changed)
	// "wired", "wifi" or "unknown", as the operating system reports it
	Q_PROPERTY(QString link READ link NOTIFY changed)

	public:
		explicit ViceNetCheck(QObject *parent = nullptr);

		bool running() const { return timer.isActive(); }
		int expected() const { return probes_expected; }
		int sent() const { return rtts.size(); }
		int received() const;
		QVariantList samples() const;
		double ping() const;
		double jitter() const;
		double loss() const;
		QString link() const { return link_type; }

		Q_INVOKABLE void start(const QString &host, bool ps5, int seconds);
		Q_INVOKABLE void stop();

		static const int intervalMs = 500;

	signals:
		void runningChanged();
		void changed();
		void finished();

	private:
		void probe();
		void readReplies();
		void closeProbe();
		void tcpProbe();
		void tcpDone(int index, bool answered);
		const QList<double> &timed() const;
		static QString detectLink();

		QUdpSocket socket;
		QTimer timer;
		QElapsedTimer clock;
		QHostAddress address;
		quint16 port = 0;
		QByteArray request;
		QList<double> rtts;
		// One per probe, the TCP round trip in ms; -1 where there was none
		QList<double> tcp_rtts;
		QTcpSocket *tcp = nullptr;
		QElapsedTimer tcp_clock;
		bool awaiting = false;
		int probes_expected = 0;
		QString link_type = QStringLiteral("unknown");
};

void viceRegisterQmlTypes();

#endif // VICE_NETCHECK_H
