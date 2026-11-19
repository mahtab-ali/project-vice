// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Names the console a dialog is about
Rectangle {
    id: chip
    property string name
    property string type

    implicitWidth: row.implicitWidth + Theme.unit * 8
    implicitHeight: Theme.buttonMd
    radius: Theme.radiusField
    color: Theme.alpha(Theme.surfaceRaised, 0.7)

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.unit * 2

        Icon { anchors.verticalCenter: parent.verticalCenter; name: Vice.consoleIcon(chip.type); size: Theme.px(34) }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(28); color: Theme.alpha(Theme.text, 0.5) }
        Label {
            anchors.verticalCenter: parent.verticalCenter
            text: chip.type ? chip.name + "  ·  " + chip.type : chip.name
            font.weight: Theme.weightStrong
        }
    }
}
