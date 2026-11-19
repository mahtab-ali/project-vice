// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Severity badge: a shape and a mark, so status never depends on colour alone.
Rectangle {
    id: badge

    // success | warning | error | info | question
    property string severity: "info"
    // Overrides the mark, e.g. "linkOff" on the connection-lost dialog
    property string iconName
    property real size: Theme.px(44)

    readonly property var marks: ({ "success": "check", "warning": "bang", "error": "close", "info": "i", "question": "question" })

    width: size
    height: size
    radius: size / 2
    color: severity === "question" ? Theme.info : Theme.severityColor(severity)

    Icon {
        anchors.centerIn: parent
        name: badge.iconName || badge.marks[badge.severity] || "i"
        size: badge.size * 0.62
        weight: badge.iconName ? 2.2 : 3
        color: Theme.pinkInk
    }
}
