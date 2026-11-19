// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.Button {
    id: control

    // primary: pink pill. outline: a quiet translucent pill (no outline, despite the name).
    // danger: the same with a coral label. text: label only.
    property string kind: "primary"
    // lg | md | sm
    property string size: "md"
    property string iconName
    // A pending operation: shows a spinner and swallows presses, so an
    // action cannot be submitted twice. Connect to triggered(), not clicked().
    property bool busy: false
    signal triggered()

    // Label and icon colour; set it to override what the kind gives
    property color ink: kind === "primary" ? Theme.pinkInk : kind === "danger" ? Theme.error : Theme.text

    implicitHeight: size === "lg" ? Theme.buttonLg : size === "sm" ? Theme.buttonSm : Theme.buttonMd
    implicitWidth: Math.max(implicitHeight * 2, implicitContentWidth + leftPadding + rightPadding)
    leftPadding: kind === "text" ? Theme.unit * 1.5 : Math.round(implicitHeight * 0.6)
    rightPadding: leftPadding
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Theme.disabledOpacity
    font.family: Theme.family
    font.weight: kind === "text" ? Theme.weightStrong : Theme.weightButton
    font.pixelSize: size === "lg" ? Theme.px(34) : size === "sm" ? Theme.textLabel : Theme.textHeading

    Accessible.name: text
    Accessible.role: Accessible.Button

    onClicked: if (!busy) triggered()
    Keys.onReturnPressed: clicked()
    Keys.onEnterPressed: clicked()
    Keys.onPressed: (event) => Theme.navKey(control, event, false)

    contentItem: Item {
        implicitWidth: row.implicitWidth
        implicitHeight: row.implicitHeight

        Row {
            id: row
            anchors.centerIn: parent
            spacing: Theme.unit * 1.5

            Spinner {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.busy
                size: control.font.pixelSize
                color: control.ink
            }

            Icon {
                anchors.verticalCenter: parent.verticalCenter
                visible: control.iconName && !control.busy
                name: control.iconName
                size: control.font.pixelSize * 1.15
                color: control.ink
                weight: 2.2
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: control.text
                font: control.font
                color: control.ink
            }
        }
    }

    background: Rectangle {
        radius: height / 2
        color: control.kind === "primary" ? (control.down ? Theme.pinkPressed : Theme.pink)
             : control.kind === "text" ? (control.down ? Theme.alpha(Theme.text, 0.12) : "transparent")
             : control.down ? Theme.alpha(Theme.text, 0.26)
             : control.hovered ? Theme.alpha(Theme.text, 0.2) : Theme.alpha(Theme.text, 0.13)
        Behavior on color { ColorAnimation { duration: Theme.dur(Theme.fast) } }

        FocusRing { active: control.visualFocus }
    }
}
