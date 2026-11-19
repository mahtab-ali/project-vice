// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Effects
import ".."

// The card of a modal dialog. It only shows `request` and reports which way
// the user went; Vice.qml (the coordinator) owns what the answers do.
FocusScope {
    id: dialog

    // See Vice.ask() for the fields
    property var request: null
    property real maxHeight: Theme.px(640)
    signal resolved(string which)
    // D-pad focus stays among this dialog's own actions (see Theme.focusRoot)
    readonly property bool focusTrap: true

    readonly property bool busy: request && request.busy === true
    readonly property string cancelLabel: !request ? ""
        : request.cancelText ? request.cancelText
        : request.cancel === "primary" && request.primary ? request.primary.text
        : qsTr("Back")

    implicitWidth: Theme.dialogWidth
    implicitHeight: Math.min(maxHeight, column.implicitHeight + Theme.unit * 9)

    Accessible.role: Accessible.AlertMessage
    Accessible.name: request ? request.title : ""
    Accessible.description: request ? (request.body || "") : ""

    function focusDefault() {
        const target = request && request.defaultFocus === "secondary" && secondaryButton.visible ? secondaryButton : primaryButton;
        target.forceActiveFocus(Qt.TabFocusReason);
    }
    onRequestChanged: if (request) Qt.callLater(focusDefault)

    function cancel() {
        if (!busy || (request && request.cancelWhileBusy === true))
            resolved("cancel");
    }

    Keys.onEscapePressed: cancel()
    // The card carries the same picture as the pages, washed for reading and
    // cut to the card's rounded shape. A handheld gets the plain card.
    Item {
        id: backdrop
        anchors.fill: parent
        layer.enabled: Theme.richEffects
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: backdropMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1
        }

        Rectangle { anchors.fill: parent; radius: Theme.richEffects ? 0 : Theme.radiusDialog; color: Theme.surfaceSolid }
        Artwork {
            anchors.fill: parent
            visible: Theme.richEffects
            preset: "palms"
            zoom: 3.2
            imageY: 0.25
            atY: 0.2
            washLeft: 0.8
            washRight: 0.66
            fadeBottom: 0.7
            fadeColor: Theme.surfaceSolid
        }
    }
    Rectangle {
        id: backdropMask
        anchors.fill: backdrop
        radius: Theme.radiusDialog
        visible: false
        layer.enabled: true
    }
    Rectangle {
        anchors.fill: parent
        radius: Theme.radiusDialog
        color: "transparent"
        border.width: Theme.border
        border.color: Theme.line
    }

    Rectangle {
        id: closeButton
        anchors { top: parent.top; right: parent.right; margins: Theme.unit * 2.5 }
        visible: !dialog.request || dialog.request.closable !== false
        width: Theme.px(36)
        height: width
        radius: width / 2
        color: closeTap.pressed ? Theme.alpha(Theme.text, 0.26) : Theme.alpha(Theme.text, 0.13)
        Accessible.role: Accessible.Button
        Accessible.name: qsTr("Close")

        Icon { anchors.centerIn: parent; name: "close"; size: Theme.px(18); weight: 3 }
        TapHandler { id: closeTap; onTapped: dialog.cancel() }
    }

    Flickable {
        id: flick
        anchors { fill: parent; topMargin: Theme.unit * 4; bottomMargin: Theme.unit * 3; leftMargin: Theme.unit * 6; rightMargin: Theme.unit * 6 }
        contentHeight: column.implicitHeight
        clip: contentHeight > height
        interactive: contentHeight > height

        Column {
            id: column
            width: flick.width
            spacing: Theme.unit * 2

            StatusIcon {
                anchors.horizontalCenter: parent.horizontalCenter
                severity: dialog.request ? dialog.request.severity || "info" : "info"
                iconName: dialog.request && dialog.request.iconName ? dialog.request.iconName : ""
                color: dialog.request && dialog.request.iconColor ? dialog.request.iconColor
                     : severity === "question" ? Theme.info : Theme.severityColor(severity)
                size: Theme.px(60)
            }

            Label {
                width: parent.width
                text: dialog.request ? dialog.request.title : ""
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
                font.pixelSize: Theme.textHeadline
                font.weight: Theme.weightDisplay
                lineHeight: 0.95
            }

            Label {
                width: parent.width
                visible: text
                text: dialog.request ? dialog.request.body || "" : ""
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.Wrap
            }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: dialog.request && dialog.request.note ? true : false
                spacing: Theme.unit

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.px(22); height: width; radius: width / 2
                    color: "transparent"
                    border.width: Math.max(2, Theme.px(2)); border.color: Theme.warning
                    Icon { anchors.centerIn: parent; name: "i"; size: Theme.px(16); weight: 3; color: Theme.warning }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: dialog.request && dialog.request.note ? dialog.request.note : ""
                    font.pixelSize: Theme.textLabel
                }
            }

            ConsoleChip {
                anchors.horizontalCenter: parent.horizontalCenter
                visible: dialog.request && dialog.request.console ? true : false
                name: dialog.request && dialog.request.console ? dialog.request.console.name : ""
                type: dialog.request && dialog.request.console ? dialog.request.console.type || "" : ""
            }

            InlineAlert {
                width: parent.width
                visible: dialog.request && dialog.request.error ? true : false
                severity: "error"
                text: dialog.request && dialog.request.error ? dialog.request.error : ""
            }

            Item { width: 1; height: Theme.unit / 2 }

            Button {
                id: primaryButton
                width: parent.width
                visible: dialog.request && dialog.request.primary ? true : false
                text: dialog.busy && dialog.request.busyText ? dialog.request.busyText
                    : dialog.request && dialog.request.primary ? dialog.request.primary.text : ""
                busy: dialog.busy
                onTriggered: dialog.resolved("primary")
            }

            Button {
                id: secondaryButton
                width: parent.width
                visible: dialog.request && dialog.request.secondary ? true : false
                kind: dialog.request && dialog.request.secondary && dialog.request.secondary.danger ? "danger" : "outline"
                text: dialog.request && dialog.request.secondary ? dialog.request.secondary.text : ""
                enabled: !dialog.busy || (dialog.request && dialog.request.cancelWhileBusy === true)
                onTriggered: dialog.resolved("secondary")
            }

            Button {
                id: tertiaryButton
                anchors.horizontalCenter: parent.horizontalCenter
                visible: dialog.request && dialog.request.tertiary ? true : false
                kind: "text"
                size: "sm"
                text: dialog.request && dialog.request.tertiary ? dialog.request.tertiary.text : ""
                enabled: !dialog.busy
                onTriggered: dialog.resolved("tertiary")
            }

            // One hint set while the dialog owns the controller
            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.unit * 4
                topPadding: Theme.unit / 2

                Row {
                    spacing: Theme.unit
                    Glyph { anchors.verticalCenter: parent.verticalCenter; button: "cross"; size: Theme.px(22) }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Select"); font.pixelSize: Theme.textSmall }
                }
                Row {
                    spacing: Theme.unit
                    Glyph { anchors.verticalCenter: parent.verticalCenter; button: "moon"; size: Theme.px(22) }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: dialog.cancelLabel; font.pixelSize: Theme.textSmall }
                }
            }
        }
    }
}
