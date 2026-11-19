// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// One notification. It never takes focus on its own; its action can be
// reached with Tab or the D-pad, and hovering or focusing it pauses dismissal.
Panel {
    id: toast

    // See Vice.notify() for the fields
    property var note: ({})
    // The in-game form: a small dark box with no buttons. A tap anywhere on
    // it runs its action, or dismisses it when it has none.
    property bool compact: false
    // Lets a tap reach this notice while the game otherwise takes every touch
    readonly property bool viceTouchTarget: compact
    readonly property bool focused: actionButton.activeFocus
    readonly property bool held: hover.hovered || focused
    signal action()
    signal dismissed()

    implicitWidth: Theme.toastWidth
    implicitHeight: content.implicitHeight + Theme.unit * (compact ? 2.5 : 4)
    radius: compact ? Theme.radiusTip : Theme.radiusPanel
    color: compact ? Theme.tipBg : Theme.alpha(Theme.surfaceSolid, 0.94)
    Accessible.role: Accessible.AlertMessage
    Accessible.name: (note.title || "") + ". " + (note.body || "")

    HoverHandler { id: hover }
    TapHandler {
        enabled: toast.compact
        onTapped: toast.note.action ? toast.action() : toast.dismissed()
    }

    Row {
        id: content
        anchors { left: parent.left; right: parent.right; verticalCenter: parent.verticalCenter; leftMargin: Theme.unit * (toast.compact ? 1.75 : 2.5); rightMargin: Theme.unit * (toast.compact ? 1.75 : 6) }
        spacing: Theme.unit * (toast.compact ? 1.5 : 2)

        StatusIcon {
            id: badge
            anchors.top: parent.top
            anchors.topMargin: Theme.unit / 2
            severity: toast.note.severity || "info"
            iconName: toast.note.iconName || ""
            size: toast.compact ? Theme.px(26) : Theme.px(44)
        }

        Column {
            width: content.width - badge.width - content.spacing
            spacing: Theme.unit / 2

            Label {
                width: parent.width
                text: toast.note.title || ""
                font.pixelSize: toast.compact ? Theme.textLabel : Theme.textHeading
                font.weight: toast.compact ? Theme.weightStrong : Theme.weightButton
                wrapMode: Text.Wrap
            }

            Label {
                width: parent.width
                visible: text
                text: toast.note.body || ""
                font.pixelSize: toast.compact ? Theme.textSmall : Theme.textLabel
                wrapMode: Text.Wrap
                maximumLineCount: 4
                elide: Text.ElideRight
            }

            Label {
                width: parent.width
                visible: toast.compact
                text: toast.note.actionText ? qsTr("Tap: %1").arg(toast.note.actionText) : qsTr("Tap to dismiss")
                font.pixelSize: Theme.textSmall
                font.weight: Theme.weightStrong
                color: Theme.pink
            }

            Item { width: 1; height: Theme.unit / 2; visible: actionButton.visible }

            Button {
                id: actionButton
                visible: !toast.compact && toast.note.actionText ? true : false
                size: "sm"
                text: toast.note.actionText || ""
                onTriggered: toast.action()
                Keys.onEscapePressed: toast.dismissed()
            }
        }
    }

    Item {
        visible: !toast.compact
        anchors { top: parent.top; right: parent.right; margins: Theme.unit }
        width: Theme.px(36)
        height: width
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Dismiss")

        Icon { anchors.centerIn: parent; name: "close"; size: Theme.px(20); weight: 2.6; color: closeTap.pressed ? Theme.pink : Theme.text }
        TapHandler { id: closeTap; onTapped: toast.dismissed() }
    }
}
