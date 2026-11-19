// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking

import ".."

// The window's own controls, drawn by the app so they sit on the same picture
// and gradient as everything else. Used when the system title bar is turned
// off (see Main.qml). Close, minimise and maximise are on the left on macOS
// and on the right elsewhere; the strip itself drags the window.
Item {
    id: bar

    readonly property bool mac: Qt.platform.os === "osx"
    signal maximizeToggled()

    height: Theme.px(34)

    Rectangle {
        anchors.fill: parent
        height: parent.height + Theme.px(14)
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.bgDeep, 0.5) }
            GradientStop { position: 1; color: Theme.alpha(Theme.bgDeep, 0) }
        }
    }

    DragHandler {
        target: null
        onActiveChanged: if (active) Chiaki.window.startSystemMove()
    }
    TapHandler { onDoubleTapped: bar.maximizeToggled() }

    // macOS: three small dots, top left
    Row {
        visible: bar.mac
        x: Theme.px(14)
        anchors.verticalCenter: parent.verticalCenter
        spacing: Theme.px(8)

        component Dot: Rectangle {
            id: dot
            property string label
            signal activated()
            width: Theme.px(13)
            height: width
            radius: width / 2
            opacity: dotTap.pressed ? 0.6 : 1
            Accessible.role: Accessible.Button
            Accessible.name: label
            TapHandler { id: dotTap; onTapped: dot.activated() }
        }

        Dot { color: Theme.error; label: qsTr("Close"); onActivated: Chiaki.window.close() }
        Dot { color: Theme.warning; label: qsTr("Minimise"); onActivated: Chiaki.window.showMinimized() }
        Dot { color: Theme.success; label: qsTr("Maximise"); onActivated: bar.maximizeToggled() }
    }

    // Windows and Linux: three flat buttons, top right
    Row {
        visible: !bar.mac
        anchors.right: parent.right

        component Flat: Rectangle {
            id: flat
            property string iconName
            property string label
            property bool danger: false
            signal activated()
            width: Theme.px(46)
            height: bar.height
            color: flatHover.hovered ? (danger ? Theme.error : Theme.alpha(Theme.text, 0.14)) : "transparent"
            Accessible.role: Accessible.Button
            Accessible.name: label
            Icon { anchors.centerIn: parent; name: flat.iconName; size: Theme.px(16); weight: 2; color: flatHover.hovered && flat.danger ? Theme.pinkInk : Theme.text }
            HoverHandler { id: flatHover }
            TapHandler { onTapped: flat.activated() }
        }

        Flat { iconName: "minus"; label: qsTr("Minimise"); onActivated: Chiaki.window.showMinimized() }
        Flat { iconName: "square"; label: qsTr("Maximise"); onActivated: bar.maximizeToggled() }
        Flat { iconName: "close"; label: qsTr("Close"); danger: true; onActivated: Chiaki.window.close() }
    }
}
