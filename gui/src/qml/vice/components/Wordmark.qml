// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

Item {
    id: mark
    implicitWidth: Theme.px(138)
    implicitHeight: Math.round(implicitWidth * 684 / 1451)

    Accessible.name: Theme.appName
    Accessible.role: Accessible.Graphic

    Image {
        anchors.fill: parent
        source: "../images/wordmark.svg"
        sourceSize: Qt.size(width, height)
    }

    Rectangle {
        x: mark.width * 0.588
        y: mark.height * 0.541
        width: mark.width * 0.409
        height: mark.height * 0.145
        radius: Theme.px(2)
        color: Theme.dash
    }
}
