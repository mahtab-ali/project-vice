// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.RadioButton {
    id: control

    implicitHeight: Theme.px(40)
    implicitWidth: indicator.width + spacing + label.implicitWidth
    spacing: Theme.unit * 1.5
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Theme.disabledOpacity
    Accessible.role: Accessible.RadioButton
    Accessible.checked: checked

    Keys.onReturnPressed: { checked = true; toggled() }
    Keys.onPressed: (event) => Theme.navKey(control, event, false)

    indicator: Rectangle {
        y: (control.height - height) / 2
        width: Theme.px(24)
        height: width
        radius: width / 2
        color: "transparent"
        border.width: Math.max(2, Theme.px(2))
        border.color: control.checked ? Theme.pink : Theme.alpha(Theme.text, 0.6)

        Rectangle {
            anchors.centerIn: parent
            visible: control.checked
            width: parent.width * 0.5
            height: width
            radius: width / 2
            color: Theme.pink
        }

        FocusRing { active: control.visualFocus; border.color: Theme.pink }
    }

    contentItem: Label {
        id: label
        leftPadding: control.indicator.width + control.spacing
        text: control.text
        verticalAlignment: Text.AlignVCenter
    }
}
