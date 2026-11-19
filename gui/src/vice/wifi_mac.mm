// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Wi-Fi band and signal on macOS.

#include "vice/engine.h"

#import <CoreWLAN/CoreWLAN.h>

bool vicePlatformWifi(QString *band, int *signal)
{
	@autoreleasepool {
		CWInterface *interface = [[CWWiFiClient sharedWiFiClient] interface];
		if(!interface || !interface.powerOn)
			return false;
		CWChannel *channel = interface.wlanChannel;
		if(!channel)
			return false;
		switch(channel.channelBand)
		{
			case kCWChannelBand2GHz:
				*band = QStringLiteral("2.4");
				break;
			case kCWChannelBand5GHz:
				*band = QStringLiteral("5");
				break;
			default:
				// 6 GHz on systems that report it
				*band = channel.channelNumber > 0 ? QStringLiteral("6") : QString();
				break;
		}
		const NSInteger rssi = interface.rssiValue;
		*signal = rssi == 0 ? -1 : static_cast<int>(MAX(0, MIN(100, 2 * (rssi + 100))));
		return !band->isEmpty();
	}
}
