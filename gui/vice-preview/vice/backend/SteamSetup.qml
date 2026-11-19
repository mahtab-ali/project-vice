// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

// Preview stand-in for the C++ ViceSteamSetup: remembers the choice, touches nothing.
QtObject {
    property bool available: true
    property string layout: ""
    function currentLayout(name) { return layout }
    function applyLayout(name, value) { console.log("applyLayout", name, value); layout = value; return "" }
}
