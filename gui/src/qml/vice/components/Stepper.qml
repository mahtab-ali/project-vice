// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Numbered steps of a flow: done, current, upcoming
Row {
    id: stepper

    property var steps: []
    property int current: 0
    spacing: Theme.unit * 2

    Repeater {
        model: stepper.steps
        Row {
            id: step
            required property int index
            required property string modelData
            readonly property bool done: index < stepper.current
            readonly property bool active: index === stepper.current
            spacing: Theme.unit * 2

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                visible: step.index > 0
                width: Theme.px(52)
                height: Theme.border
                color: Theme.alpha(Theme.text, 0.5)
            }

            Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.px(34)
                height: width
                radius: width / 2
                color: step.done ? Theme.pink : "transparent"
                border.width: Math.max(2, Theme.px(2))
                border.color: step.done || step.active ? Theme.pink : Theme.textFaint

                Icon {
                    anchors.centerIn: parent
                    visible: step.done
                    name: "check"
                    size: Theme.px(20)
                    weight: 3
                    color: Theme.pinkInk
                }

                Label {
                    anchors.centerIn: parent
                    visible: !step.done
                    text: step.index + 1
                    font.pixelSize: Theme.textLabel
                    font.weight: Theme.weightStrong
                    color: step.active ? Theme.text : Theme.textFaint
                }
            }

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: step.modelData
                font.weight: step.active ? Theme.weightStrong : Theme.weightBody
                color: step.active ? Theme.text : Theme.textMuted
                Accessible.name: step.done ? qsTr("%1, done").arg(text) : step.active ? qsTr("%1, current step").arg(text) : text
            }
        }
    }
}
