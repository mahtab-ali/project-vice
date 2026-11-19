// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// A short in-game tip: plain white text on a dark box, with the keys or
// buttons it names drawn as caps. Used over the picture, so it stays small
// and quiet.
Rectangle {
    id: tip

    property string text
    property var keys: []
    property string iconName

    implicitWidth: row.implicitWidth + Theme.px(28)
    implicitHeight: row.implicitHeight + Theme.px(18)
    radius: Theme.radiusTip
    color: Theme.tipBg
    Accessible.role: Accessible.StaticText
    Accessible.name: text + " " + keys.join(" ")

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.px(10)

        Icon {
            anchors.verticalCenter: parent.verticalCenter
            visible: tip.iconName
            name: tip.iconName
            size: Theme.px(22)
            weight: 2
        }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: tip.text
            font.pixelSize: Theme.textLabel
            font.weight: Theme.weightStrong
        }
        Repeater {
            model: tip.keys
            Rectangle {
                required property string modelData
                anchors.verticalCenter: parent.verticalCenter
                width: Math.max(height, cap.implicitWidth + Theme.px(14))
                height: Theme.px(26)
                radius: Theme.px(6)
                color: Theme.alpha(Theme.text, 0.92)
                Label { id: cap; anchors.centerIn: parent; text: parent.modelData; color: Theme.pinkInk; font.pixelSize: Theme.textSmall; font.weight: Theme.weightButton }
            }
        }
    }
}
