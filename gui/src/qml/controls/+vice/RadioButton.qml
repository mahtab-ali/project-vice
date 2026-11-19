// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The radio button upstream's pages use, drawn as a Vice radio button.
import QtQuick
import "../vice/components" as V

V.Radio {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false
}
