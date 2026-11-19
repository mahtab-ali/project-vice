// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// A pending operation with honest phases: no percentage, no time estimate.
Column {
    id: progress

    property string title
    property string body
    // [{ text, state: "done" | "active" | "pending" }]
    property var phases: []
    property string cancelText: qsTr("Cancel")
    property bool cancellable: true
    property alias cancelButton: cancel
    signal cancelled()

    spacing: Theme.unit * 2
    width: Theme.px(640)
    Accessible.role: Accessible.ProgressBar
    Accessible.name: title

    Item {
        anchors.horizontalCenter: parent.horizontalCenter
        width: Theme.px(96)
        height: width
        Spinner { anchors.fill: parent; size: parent.width; weight: 1.6 }
        Icon { anchors.centerIn: parent; name: "console"; size: Theme.px(44) }
    }

    Label {
        width: parent.width
        text: progress.title
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: Theme.textHeadline
        font.weight: Theme.weightDisplay
    }

    Label {
        width: parent.width
        visible: text
        text: progress.body
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Row {
        anchors.horizontalCenter: parent.horizontalCenter
        spacing: Theme.unit * 1.5

        Repeater {
            model: progress.phases
            Row {
                id: phase
                required property int index
                required property var modelData
                spacing: Theme.unit * 1.5

                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    visible: phase.index > 0
                    width: Theme.px(24); height: Theme.border
                    color: Theme.alpha(Theme.text, 0.5)
                }
                Rectangle {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Theme.px(22); height: width; radius: width / 2
                    color: phase.modelData.state === "done" ? Theme.success : "transparent"
                    border.width: Math.max(2, Theme.px(3))
                    border.color: phase.modelData.state === "done" ? Theme.success : phase.modelData.state === "active" ? Theme.warning : Theme.textFaint
                    Icon { anchors.centerIn: parent; visible: phase.modelData.state === "done"; name: "check"; size: Theme.px(14); weight: 3.5; color: Theme.pinkInk }
                }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: phase.modelData.text
                    font.pixelSize: Theme.textLabel
                    font.weight: phase.modelData.state === "active" ? Theme.weightStrong : Theme.weightBody
                    color: phase.modelData.state === "pending" ? Theme.textMuted : Theme.text
                    Accessible.name: phase.modelData.state === "done" ? qsTr("%1, done").arg(text) : phase.modelData.state === "active" ? qsTr("%1, in progress").arg(text) : text
                }
            }
        }
    }

    Item { width: 1; height: Theme.unit / 2 }

    Button {
        id: cancel
        anchors.horizontalCenter: parent.horizontalCenter
        visible: progress.cancellable
        kind: "outline"
        width: Theme.px(240)
        text: progress.cancelText
        onTriggered: progress.cancelled()
    }
}
