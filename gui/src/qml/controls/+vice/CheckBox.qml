// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The check box upstream's pages use, drawn as a Vice toggle.
import QtQuick
import vice.components as V

V.Toggle {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false
}
