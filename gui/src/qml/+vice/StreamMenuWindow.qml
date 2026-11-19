// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../StreamMenuWindow.qml: the same window, signals and
// open/closing contract, with the Vice quick menu inside and sliding in from
// the right. Used when the OpenGL renderer cannot draw QML over the video.
// A replacement resolved by type name imports as if it were the original file.
import QtQuick
import QtQuick.Window

import org.streetpea.chiaking

import vice
import vice.overlay as Overlay

Window {
    id: streamMenuWindow
    property bool open: false
    property bool closing: false

    signal closeRequested()
    signal displaySettingsRequested()
    signal placeboSettingsRequested()
    signal mainViewRequested()
    signal disconnectRequested()
    signal closeAnimationFinished()

    visible: open || closing
    flags: Qt.Tool | Qt.FramelessWindowHint
    color: "transparent"
    modality: Qt.NonModal

    function focusInitialItem() {
        requestActivate();
        quickMenu.initialFocusItem.forceActiveFocus(Qt.TabFocusReason);
    }

    onVisibleChanged: if (visible) focusTimer.restart()
    onActiveChanged: if (active && visible) focusTimer.restart()

    Shortcut {
        sequence: "Ctrl+O"
        onActivated: if (streamMenuWindow.open) quickMenu.resume()
    }

    Behavior on x {
        NumberAnimation {
            duration: Theme.dur(Theme.normal)
            onRunningChanged: {
                if (!running && !streamMenuWindow.open)
                    streamMenuWindow.closeAnimationFinished();
            }
        }
    }

    Timer {
        id: focusTimer
        interval: 0
        onTriggered: if (streamMenuWindow.visible) streamMenuWindow.focusInitialItem()
    }

    Overlay.QuickMenu {
        id: quickMenu
        anchors.fill: parent
        focus: true
        onCloseRequested: streamMenuWindow.closeRequested()
        onDisplaySettingsRequested: streamMenuWindow.displaySettingsRequested()
        onPlaceboSettingsRequested: streamMenuWindow.placeboSettingsRequested()
        onDisconnectRequested: streamMenuWindow.disconnectRequested()
    }
}
