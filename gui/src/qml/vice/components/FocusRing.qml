// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Drawn outside its parent with a gap, so the focused control keeps its shape.
Rectangle {
    property bool active: false

    anchors.fill: parent
    anchors.margins: -Theme.focusWidth * 2
    radius: parent.radius + Theme.focusWidth * 2
    color: "transparent"
    border.color: Theme.text
    border.width: Theme.focusWidth
    opacity: active && Theme.keyboardNav ? 1 : 0
    Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.fast) } }
}
