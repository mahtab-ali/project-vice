// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The parts of the engine that differ per operating system.
//
// The Windows branches below compile and link with MinGW. The Wi-Fi query has
// run on Windows 11 (the connection check shows its band and signal); the
// session tuning runs only during a stream and has not run yet.

#include "vice/engine.h"

#include <QDir>
#include <QFile>
#include <QLoggingCategory>

// What the session tuning did, so a user can see whether it took effect ("vice.platform" in the log)
Q_LOGGING_CATEGORY(vicePlatformLog, "vice.platform", QtInfoMsg)

#if defined(_WIN32)
#include <winsock2.h>
#include <windows.h>
#include <avrt.h>
#include <timeapi.h>
#include <wlanapi.h>
#include <qos2.h>
#include <setupapi.h>
#else
#include <netinet/in.h>
#include <netinet/ip.h>
#include <sys/socket.h>
#include <sys/resource.h>
#include <unistd.h>
#endif

#if defined(__APPLE__)
#include <pthread.h>
#include <pthread/qos.h>
#endif

#if defined(__linux__)
#include <sys/ioctl.h>
#include <sys/syscall.h>
#include <net/if.h>
#include <linux/wireless.h>
#include <cstring>
#endif

// ---- L2: the threads a frame or a button press passes through ---------------------

void vicePlatformRaiseCurrentThread()
{
#if defined(_WIN32)
	DWORD task = 0;
	const bool mmcss = AvSetMmThreadCharacteristicsW(L"Games", &task) != nullptr;
	const DWORD mmcss_error = mmcss ? 0 : GetLastError();
	const bool raised = SetThreadPriority(GetCurrentThread(), THREAD_PRIORITY_HIGHEST);
	qCInfo(vicePlatformLog) << "thread" << GetCurrentThreadId() << "multimedia class Games:" << (mmcss ? "on" : "failed")
		<< (mmcss ? QString() : QStringLiteral("(error %1)").arg(mmcss_error))
		<< "priority highest:" << (raised ? "on" : "failed");
#elif defined(__APPLE__)
	pthread_set_qos_class_self_np(QOS_CLASS_USER_INTERACTIVE, 0);
#elif defined(__linux__)
	// Allowed only when the system lets this user raise priority; otherwise nothing changes
	setpriority(PRIO_PROCESS, static_cast<id_t>(syscall(SYS_gettid)), -10);
#endif
}

// ---- L5: mark the stream's packets so routers that honour it can put them first ----

#if defined(_WIN32)
static HANDLE qos_handle = nullptr;
#endif

void vicePlatformTagSocket(chiaki_socket_t sock)
{
#if defined(_WIN32)
	// Windows ignores IP_TOS; the QoS service sets the marking instead
	QOS_VERSION version = { 1, 0 };
	if(!qos_handle && !QOSCreateHandle(&version, &qos_handle))
	{
		qCInfo(vicePlatformLog) << "packet priority: QoS service unavailable, error" << GetLastError();
		qos_handle = nullptr;
		return;
	}
	QOS_FLOWID flow = 0;
	if(QOSAddSocketToFlow(qos_handle, sock, nullptr, QOSTrafficTypeAudioVideo, QOS_NON_ADAPTIVE_FLOW, &flow))
		qCInfo(vicePlatformLog) << "packet priority: stream socket added to an audio/video QoS flow" << flow;
	else
		qCInfo(vicePlatformLog) << "packet priority: QOSAddSocketToFlow failed, error" << GetLastError();
#else
	// Expedited forwarding (DSCP 46)
	int tos = 0xB8;
	setsockopt(sock, IPPROTO_IP, IP_TOS, &tos, sizeof(tos));
#ifdef IPV6_TCLASS
	setsockopt(sock, IPPROTO_IPV6, IPV6_TCLASS, &tos, sizeof(tos));
#endif
#endif
}

// ---- L1 and L3: Windows settings held for the length of a session -----------------

#if defined(_WIN32)
static bool timer_raised = false;
static HANDLE wlan_handle = nullptr;

static void endSessionTuning()
{
	if(timer_raised)
	{
		timeEndPeriod(1);
		timer_raised = false;
		qCInfo(vicePlatformLog) << "1 ms timers: released";
	}
	// Closing the handle puts streaming mode and background scanning back as they were
	if(wlan_handle)
	{
		WlanCloseHandle(wlan_handle, nullptr);
		wlan_handle = nullptr;
		qCInfo(vicePlatformLog) << "Wi-Fi streaming mode: released";
	}
}
#endif

void vicePlatformSessionBegin(bool system_tuning)
{
#if defined(_WIN32)
	if(!system_tuning)
	{
		qCInfo(vicePlatformLog) << "Windows session tuning: off";
		return;
	}
	static bool exit_registered = false;
	if(!exit_registered)
	{
		// Also undone if the app leaves without ending the session
		atexit(endSessionTuning);
		exit_registered = true;
	}
	if(!timer_raised && timeBeginPeriod(1) == TIMERR_NOERROR)
		timer_raised = true;
	qCInfo(vicePlatformLog) << "1 ms timers:" << (timer_raised ? "on" : "failed");

	DWORD negotiated = 0;
	if(!wlan_handle && WlanOpenHandle(2, nullptr, &negotiated, &wlan_handle) != ERROR_SUCCESS)
	{
		qCInfo(vicePlatformLog) << "Wi-Fi streaming mode: WLAN service unavailable";
		wlan_handle = nullptr;
	}
	if(wlan_handle)
	{
		PWLAN_INTERFACE_INFO_LIST list = nullptr;
		if(WlanEnumInterfaces(wlan_handle, nullptr, &list) == ERROR_SUCCESS && list)
		{
			BOOL on = TRUE, off = FALSE;
			for(DWORD i = 0; i < list->dwNumberOfItems; i++)
			{
				if(list->InterfaceInfo[i].isState != wlan_interface_state_connected)
					continue;
				const GUID *guid = &list->InterfaceInfo[i].InterfaceGuid;
				const DWORD streaming = WlanSetInterface(wlan_handle, guid, wlan_intf_opcode_media_streaming_mode, sizeof(on), &on, nullptr);
				const DWORD scan = WlanSetInterface(wlan_handle, guid, wlan_intf_opcode_background_scan_enabled, sizeof(off), &off, nullptr);
				qCInfo(vicePlatformLog) << "Wi-Fi" << QString::fromWCharArray(list->InterfaceInfo[i].strInterfaceDescription)
					<< "streaming mode:" << (streaming == ERROR_SUCCESS ? QStringLiteral("on") : QStringLiteral("failed (error %1)").arg(streaming))
					<< "background scan off:" << (scan == ERROR_SUCCESS ? QStringLiteral("on") : QStringLiteral("failed (error %1)").arg(scan));
			}
			WlanFreeMemory(list);
		}
	}
#else
	(void)system_tuning;
#endif
}

void vicePlatformSessionEnd()
{
#if defined(_WIN32)
	endSessionTuning();
#endif
}

bool vicePlatformSystemTuningSupported()
{
#if defined(_WIN32)
	return true;
#else
	return false;
#endif
}

// ---- What a controller calls itself ------------------------------------------------

QString vicePlatformControllerName(quint16 vendor, quint16 product)
{
#if defined(_WIN32)
	// DEVPKEY_Device_BusReportedDeviceDesc: the product string from the device itself
	static const DEVPROPKEY bus_reported = { { 0x540b947e, 0x8b40, 0x45bc, { 0xa8, 0xa2, 0x6a, 0x0b, 0x89, 0x4c, 0xbd, 0xa2 } }, 4 };
	HDEVINFO devices = SetupDiGetClassDevsW(nullptr, L"USB", nullptr, DIGCF_PRESENT | DIGCF_ALLCLASSES);
	if(devices == INVALID_HANDLE_VALUE)
		return QString();
	const QString wanted = vendor ? QStringLiteral("VID_%1&PID_%2").arg(vendor, 4, 16, QChar('0')).arg(product, 4, 16, QChar('0')).toUpper() : QString();
	QString found;
	SP_DEVINFO_DATA info = {};
	info.cbSize = sizeof(info);
	for(DWORD i = 0; found.isEmpty() && SetupDiEnumDeviceInfo(devices, i, &info); i++)
	{
		wchar_t id[512] = {};
		if(!SetupDiGetDeviceInstanceIdW(devices, &info, id, 511, nullptr))
			continue;
		const QString instance = QString::fromWCharArray(id).toUpper();
		// "IG_" marks the XInput interface of a controller; with no IDs to go by, the first one is it
		if(wanted.isEmpty() ? !instance.contains(QLatin1String("&IG_")) : !instance.contains(wanted))
			continue;
		wchar_t text[512] = {};
		DEVPROPTYPE type = 0;
		if(!SetupDiGetDevicePropertyW(devices, &info, &bus_reported, &type, reinterpret_cast<PBYTE>(text), sizeof(text) - sizeof(wchar_t), nullptr, 0))
			continue;
		QString name = QString::fromWCharArray(text).trimmed();
		// The XInput interface wraps it: "Controller (Victrix Pro BFG ...)"
		if(name.startsWith(QLatin1String("Controller (")) && name.endsWith(QLatin1Char(')')))
			name = name.mid(12, name.size() - 13).trimmed();
		found = name;
	}
	SetupDiDestroyDeviceInfoList(devices);
	return found;
#else
	(void)vendor;
	(void)product;
	return QString();
#endif
}

// ---- Wi-Fi band and signal (macOS is in wifi_mac.mm) -------------------------------

#if defined(_WIN32)
bool vicePlatformWifi(QString *band, int *signal)
{
	DWORD negotiated = 0;
	HANDLE handle = nullptr;
	if(WlanOpenHandle(2, nullptr, &negotiated, &handle) != ERROR_SUCCESS)
		return false;
	bool found = false;
	PWLAN_INTERFACE_INFO_LIST list = nullptr;
	if(WlanEnumInterfaces(handle, nullptr, &list) == ERROR_SUCCESS && list)
	{
		for(DWORD i = 0; i < list->dwNumberOfItems && !found; i++)
		{
			if(list->InterfaceInfo[i].isState != wlan_interface_state_connected)
				continue;
			const GUID *guid = &list->InterfaceInfo[i].InterfaceGuid;
			DWORD size = 0;
			PWLAN_CONNECTION_ATTRIBUTES attributes = nullptr;
			if(WlanQueryInterface(handle, guid, wlan_intf_opcode_current_connection, nullptr, &size, reinterpret_cast<PVOID *>(&attributes), nullptr) == ERROR_SUCCESS && attributes)
			{
				*signal = static_cast<int>(attributes->wlanAssociationAttributes.wlanSignalQuality);
				WlanFreeMemory(attributes);
				found = true;
			}
			ULONG *channel = nullptr;
			if(found && WlanQueryInterface(handle, guid, wlan_intf_opcode_channel_number, nullptr, &size, reinterpret_cast<PVOID *>(&channel), nullptr) == ERROR_SUCCESS && channel)
			{
				// A channel number alone cannot tell 6 GHz from 5 GHz, so 6 GHz reads as 5 here
				*band = *channel <= 14 ? QStringLiteral("2.4") : QStringLiteral("5");
				WlanFreeMemory(channel);
			}
		}
		WlanFreeMemory(list);
	}
	WlanCloseHandle(handle, nullptr);
	return found;
}
#elif defined(__linux__)
bool vicePlatformWifi(QString *band, int *signal)
{
	// The first network interface that is a wireless one
	QString name;
	const auto interfaces = QDir(QStringLiteral("/sys/class/net")).entryList(QDir::Dirs | QDir::NoDotAndDotDot);
	for(const QString &candidate : interfaces)
	{
		if(QDir(QStringLiteral("/sys/class/net/%1/wireless").arg(candidate)).exists())
		{
			QFile state(QStringLiteral("/sys/class/net/%1/operstate").arg(candidate));
			if(state.open(QIODevice::ReadOnly) && state.readAll().trimmed() == "up")
			{
				name = candidate;
				break;
			}
		}
	}
	if(name.isEmpty())
		return false;

	int fd = socket(AF_INET, SOCK_DGRAM, 0);
	if(fd < 0)
		return false;
	bool found = false;
	struct iwreq request;
	memset(&request, 0, sizeof(request));
	strncpy(request.ifr_name, name.toLatin1().constData(), IFNAMSIZ - 1);
	if(ioctl(fd, SIOCGIWFREQ, &request) == 0)
	{
		double hz = request.u.freq.m;
		for(int i = 0; i < request.u.freq.e; i++)
			hz *= 10.0;
		const double mhz = hz / 1e6;
		if(mhz >= 2400 && mhz < 2500)
			*band = QStringLiteral("2.4");
		else if(mhz >= 5925)
			*band = QStringLiteral("6");
		else if(mhz >= 4900)
			*band = QStringLiteral("5");
		found = !band->isEmpty();
	}
	struct iw_statistics stats;
	memset(&stats, 0, sizeof(stats));
	memset(&request, 0, sizeof(request));
	strncpy(request.ifr_name, name.toLatin1().constData(), IFNAMSIZ - 1);
	request.u.data.pointer = &stats;
	request.u.data.length = sizeof(stats);
	request.u.data.flags = 1;
	if(ioctl(fd, SIOCGIWSTATS, &request) == 0 && (stats.qual.updated & IW_QUAL_DBM))
	{
		const int dbm = static_cast<int8_t>(stats.qual.level);
		*signal = qBound(0, 2 * (dbm + 100), 100);
		found = true;
	}
	close(fd);
	return found;
}
#elif !defined(__APPLE__)
bool vicePlatformWifi(QString *, int *)
{
	return false;
}
#endif
