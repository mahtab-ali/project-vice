// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL

#include "vice/netcheck.h"

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
	awaiting = false;
	emit runningChanged();
	emit changed();
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
	for(double v : rtts)
		out.append(v);
	return out;
}

double ViceNetCheck::ping() const
{
	QList<double> replies;
	for(double v : rtts)
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
	for(double v : rtts)
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
}
