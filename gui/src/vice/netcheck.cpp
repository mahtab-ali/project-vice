// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "vice/netcheck.h"
#include "vice/platform.h"
#include "vice/engine.h"

#include <chiaki/discovery.h>

#include <QNetworkInformation>
#include <QQmlEngine>

#include <algorithm>
#include <cmath>
#include <limits>

ViceNetCheck::ViceNetCheck(QObject *parent) : QObject(parent)
{
	timer.setInterval(intervalMs);
	connect(&timer, &QTimer::timeout, this, &ViceNetCheck::probe);
	connect(&socket, &QUdpSocket::readyRead, this, &ViceNetCheck::readReplies);
}

QString ViceNetCheck::detectLink()
{
	// Not every platform can tell; "unknown" is an honest answer
	if(!QNetworkInformation::loadDefaultBackend())
		return QStringLiteral("unknown");
	QNetworkInformation *info = QNetworkInformation::instance();
	if(!info || !info->supports(QNetworkInformation::Feature::TransportMedium))
		return QStringLiteral("unknown");
	switch(info->transportMedium())
	{
		case QNetworkInformation::TransportMedium::Ethernet:
			return QStringLiteral("wired");
		case QNetworkInformation::TransportMedium::WiFi:
			return QStringLiteral("wifi");
		default:
			return QStringLiteral("unknown");
	}
}

void ViceNetCheck::start(const QString &host, bool ps5, int seconds)
{
	stop();
	rtts.clear();
	tcp_rtts.clear();
	awaiting = false;
	probes_expected = std::max(1, seconds * 1000 / intervalMs);
	link_type = detectLink();
	address = QHostAddress(host);
	port = ps5 ? CHIAKI_DISCOVERY_PORT_PS5 : CHIAKI_DISCOVERY_PORT_PS4;

	char buf[512];
	ChiakiDiscoveryPacket packet = {};
	packet.cmd = CHIAKI_DISCOVERY_CMD_SRCH;
	packet.protocol_version = const_cast<char *>(ps5 ? CHIAKI_DISCOVERY_PROTOCOL_VERSION_PS5 : CHIAKI_DISCOVERY_PROTOCOL_VERSION_PS4);
	int len = chiaki_discovery_packet_fmt(buf, sizeof(buf), &packet);
	request = QByteArray(buf, std::min<int>(len, sizeof(buf)));

	// Host names are not resolved here: consoles are listed by address
	if(address.isNull() || len <= 0 || !socket.bind(QHostAddress(address.protocol() == QAbstractSocket::IPv6Protocol ? QHostAddress::AnyIPv6 : QHostAddress::AnyIPv4), 0))
	{
		emit changed();
		emit finished();
		return;
	}
	timer.start();
	emit runningChanged();
	probe();
}

void ViceNetCheck::stop()
{
	if(!timer.isActive())
		return;
	timer.stop();
	socket.close();
	if(tcp)
	{
		tcp->abort();
		tcp->deleteLater();
		tcp = nullptr;
	}
	awaiting = false;
	emit runningChanged();
	emit changed();
}

// The port a session is requested on, the same for a PS4 and a PS5
static const quint16 session_port = 9295;

void ViceNetCheck::tcpProbe()
{
	// The last one never answered: leave its slot empty and move on
	if(tcp)
	{
		tcp->abort();
		tcp->deleteLater();
		tcp = nullptr;
	}
	const int index = tcp_rtts.size();
	tcp_rtts.append(-1.0);
	tcp = new QTcpSocket(this);
	QTcpSocket *mine = tcp;
	connect(mine, &QTcpSocket::connected, this, [this, mine, index]() { if(mine == tcp) tcpDone(index, true); });
	connect(mine, &QTcpSocket::errorOccurred, this, [this, mine, index](QAbstractSocket::SocketError error) {
		// A refusal is the console answering too: it came back over the same path
		if(mine == tcp)
			tcpDone(index, error == QAbstractSocket::ConnectionRefusedError);
	});
	tcp_clock.restart();
	mine->connectToHost(address, session_port);
}

void ViceNetCheck::tcpDone(int index, bool answered)
{
	if(answered && index >= 0 && index < tcp_rtts.size())
		tcp_rtts[index] = tcp_clock.nsecsElapsed() / 1e6;
	if(tcp)
	{
		tcp->abort();
		tcp->deleteLater();
		tcp = nullptr;
	}
	emit changed();
}

// The times ping and jitter are worked out from: the TCP ones once the console has
// answered a few, the discovery ones until then or if it never does
const QList<double> &ViceNetCheck::timed() const
{
	const int answered = std::count_if(tcp_rtts.begin(), tcp_rtts.end(), [](double v) { return v >= 0; });
	return answered >= 3 ? tcp_rtts : rtts;
}

void ViceNetCheck::closeProbe()
{
	if(awaiting)
	{
		rtts.append(-1.0); // no reply before the next probe: lost
		awaiting = false;
	}
}

void ViceNetCheck::probe()
{
	closeProbe();
	if(rtts.size() >= probes_expected)
	{
		timer.stop();
		socket.close();
		if(tcp)
		{
			tcp->abort();
			tcp->deleteLater();
			tcp = nullptr;
		}
		emit runningChanged();
		emit changed();
		emit finished();
		return;
	}
	// Anything still queued answers an older probe; it must not be timed against this one
	while(socket.hasPendingDatagrams())
		socket.readDatagram(nullptr, 0);
	clock.restart();
	awaiting = socket.writeDatagram(request, address, port) == request.size();
	if(!awaiting)
		rtts.append(-1.0);
	tcpProbe();
	emit changed();
}

void ViceNetCheck::readReplies()
{
	while(socket.hasPendingDatagrams())
	{
		QHostAddress from;
		socket.readDatagram(nullptr, 0, &from);
		if(!awaiting || !from.isEqual(address, QHostAddress::TolerantConversion))
			continue;
		rtts.append(clock.nsecsElapsed() / 1e6);
		awaiting = false;
	}
	emit changed();
}

int ViceNetCheck::received() const
{
	return std::count_if(rtts.begin(), rtts.end(), [](double v) { return v >= 0; });
}

QVariantList ViceNetCheck::samples() const
{
	QVariantList out;
	const QList<double> &series = timed();
	for(int i = 0; i < rtts.size(); i++)
	{
		if(rtts.at(i) < 0)
			out.append(-1.0); // lost
		else if(&series == &rtts)
			out.append(rtts.at(i));
		else if(i < series.size() && series.at(i) >= 0)
			out.append(series.at(i));
		// answered, but not timed over TCP: nothing to plot for this probe
	}
	return out;
}

double ViceNetCheck::ping() const
{
	QList<double> replies;
	for(double v : timed())
		if(v >= 0)
			replies.append(v);
	if(replies.isEmpty())
		return std::numeric_limits<double>::quiet_NaN();
	std::sort(replies.begin(), replies.end());
	return replies.at(replies.size() / 2);
}

double ViceNetCheck::jitter() const
{
	double total = 0, previous = -1;
	int pairs = 0;
	for(double v : timed())
	{
		if(v < 0)
			continue;
		if(previous >= 0)
		{
			total += std::fabs(v - previous);
			pairs++;
		}
		previous = v;
	}
	return pairs ? total / pairs : std::numeric_limits<double>::quiet_NaN();
}

double ViceNetCheck::loss() const
{
	if(rtts.isEmpty())
		return std::numeric_limits<double>::quiet_NaN();
	return 100.0 * (rtts.size() - received()) / rtts.size();
}

void viceRegisterQmlTypes()
{
	qmlRegisterType<ViceNetCheck>("vice.backend", 1, 0, "NetCheck");
	qmlRegisterType<ViceSteamSetup>("vice.backend", 1, 0, "SteamSetup");
	qmlRegisterSingletonInstance("vice.backend", 1, 0, "Engine", ViceEngine::instance());
}
