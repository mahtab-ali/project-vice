// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.Switch {
    id: control

    implicitHeight: Theme.controlHeight
    implicitWidth: indicator.width + (text ? spacing + label.implicitWidth : 0)
    spacing: Theme.unit * 1.5
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Theme.disabledOpacity
    Accessible.role: Accessible.CheckBox
    Accessible.checked: checked

    Keys.onReturnPressed: toggle(), toggled()
    Keys.onPressed: (event) => Theme.navKey(control, event, false)

    indicator: Rectangle {
        y: (control.height - height) / 2
        width: Theme.px(56)
        height: Theme.px(30)
        radius: height / 2
        color: control.checked ? Theme.pink : Theme.alpha(Theme.text, 0.18)
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.fast) } }

        Rectangle {
            readonly property int inset: Theme.px(4)
            x: control.checked ? parent.width - width - inset : inset
            y: inset
            width: parent.height - inset * 2
            height: width
            radius: width / 2
            color: Theme.text
            Behavior on x { NumberAnimation { duration: Theme.dur(Theme.fast); easing.type: Easing.OutCubic } }
        }

        FocusRing { active: control.visualFocus; border.color: Theme.pink }
    }

    contentItem: Label {
        id: label
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        verticalAlignment: Text.AlignVCenter
        color: Theme.text
    }
}
