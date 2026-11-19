// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.Slider {
    id: control

    implicitWidth: Theme.px(320)
    implicitHeight: Theme.controlHeight
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Theme.disabledOpacity
    Accessible.role: Accessible.Slider

    // Left/right change the value; up/down move on
    Keys.onPressed: (event) => Theme.navKey(control, event, true)

    background: Rectangle {
        x: control.leftPadding
        y: control.topPadding + (control.availableHeight - height) / 2
        width: control.availableWidth
        height: Theme.px(8)
        radius: height / 2
        color: Theme.alpha(Theme.text, 0.2)

        Rectangle {
            width: control.visualPosition * parent.width
            height: parent.height
            radius: height / 2
            color: Theme.pink
        }
    }

    handle: Rectangle {
        x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
        y: control.topPadding + (control.availableHeight - height) / 2
        width: Theme.px(24)
        height: width
        radius: width / 2
        color: Theme.text

        FocusRing { active: control.visualFocus; border.color: Theme.pink }
    }
}
