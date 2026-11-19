// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// A status line that lives next to the thing it is about: validation
// errors, unavailable capabilities, pending notes.
Rectangle {
    id: alert

    property string severity: "info"
    property string text
    property string actionText
    signal action()

    implicitWidth: row.implicitWidth + Theme.unit * 4
    implicitHeight: Math.max(Theme.controlHeight, label.implicitHeight + Theme.unit * 2)
    radius: Theme.radiusField
    color: Theme.alpha(Theme.severityColor(severity), 0.12)
    border.width: Theme.border
    border.color: Theme.alpha(Theme.severityColor(severity), 0.6)
    Accessible.role: Accessible.StaticText
    Accessible.name: text

    Row {
        id: row
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; margins: Theme.unit * 1.5 }
        spacing: Theme.unit * 1.5

        StatusIcon { id: badge; anchors.verticalCenter: parent.verticalCenter; severity: alert.severity; size: Theme.px(24) }

        Label {
            id: label
            anchors.verticalCenter: parent.verticalCenter
            width: Math.min(implicitWidth, row.width - badge.width - row.spacing - (link.visible ? link.width + row.spacing : 0))
            text: alert.text
            wrapMode: Text.Wrap
            font.pixelSize: Theme.textLabel
        }

        Button {
            id: link
            anchors.verticalCenter: parent.verticalCenter
            visible: alert.actionText
            kind: "text"
            size: "sm"
            text: alert.actionText
            onTriggered: alert.action()
        }
    }
}
