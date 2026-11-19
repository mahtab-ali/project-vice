// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// "PROJECT VICE", stacked, with the short pink dash. Real text in an
// open-licensed font (Bungee, SIL OFL), not a drawn logo.
Item {
    id: mark
    implicitWidth: Theme.px(150)
    implicitHeight: Theme.px(62)

    Accessible.name: Theme.appName
    Accessible.role: Accessible.Graphic

    component Line: Text {
        color: Theme.text
        font.family: Theme.wordmarkFamily
        font.pixelSize: Theme.px(31)
        lineHeight: 0.9
    }

    Line { id: top; text: "PROJECT" }
    Line { id: bottom; y: Theme.px(29); text: "VICE" }

    Rectangle {
        anchors { left: bottom.right; leftMargin: Theme.px(8); verticalCenter: bottom.verticalCenter }
        width: top.width - bottom.width - Theme.px(8)
        height: Theme.px(9)
        radius: Theme.px(2)
        color: Theme.dash
    }
}
