// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The slider upstream's pages use, drawn as a Vice slider.
import QtQuick
import "../vice/components" as V

V.Slider {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false
}
