// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// What is on screen while a stream comes up: the app's icon breathing inside
// a turning ring, who is being connected to, and one tip at a time in the
// manner of a game's loading screen. Shown over the wallpaper.
Item {
    id: loading

    property string title
    // [{ text, keys: ["Ctrl", "O"] }]; shown one at a time, in order
    property var tips: []
    property bool running: visible

    readonly property bool animate: running && !Theme.reducedMotion
    property int tipIndex: 0
    readonly property var tip: tips.length ? tips[tipIndex % tips.length] : null

    onTipsChanged: tipIndex = 0
    onRunningChanged: if (running) tipIndex = 0

    Column {
        anchors.centerIn: parent
        anchors.verticalCenterOffset: -Theme.px(48)
        spacing: Theme.px(28)

        Item {
            id: emblem
            anchors.horizontalCenter: parent.horizontalCenter
            width: Theme.px(188)
            height: width

            // A soft light behind the icon that swells and settles with it
            Rectangle {
                anchors.centerIn: parent
                width: Theme.px(132)
                height: width
                radius: width / 2
                color: Theme.pink
                opacity: 0.16
                SequentialAnimation on scale {
                    running: loading.animate
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 1.42; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.42; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                }
            }

            Spinner { anchors.centerIn: parent; size: emblem.width; weight: 0.55 }

            Image {
                anchors.centerIn: parent
                width: Theme.px(118)
                height: width
                source: "../images/icon.png"
                sourceSize: Qt.size(256, 256)
                smooth: true
                mipmap: true
                SequentialAnimation on scale {
                    running: loading.animate
                    loops: Animation.Infinite
                    NumberAnimation { from: 1; to: 1.06; duration: 1500; easing.type: Easing.InOutSine }
                    NumberAnimation { from: 1.06; to: 1; duration: 1500; easing.type: Easing.InOutSine }
                }
            }
        }

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.px(6)

            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: loading.title
                font.pixelSize: Theme.textTitle
                font.weight: Theme.weightDisplay
            }
            Label {
                anchors.horizontalCenter: parent.horizontalCenter
                text: qsTr("Starting the stream")
                color: Theme.textMuted
                font.pixelSize: Theme.textLabel
            }
        }
    }

    // The tip: a labelled card low on the screen, one tip at a time
    Rectangle {
        id: card
        anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(72) }
        visible: loading.tip !== null
        width: Math.min(loading.width - Theme.margin * 2, Math.max(Theme.px(460), body.implicitWidth + Theme.px(64)))
        height: Theme.px(76)
        radius: Theme.radiusPanel
        color: Theme.alpha(Theme.bgDeep, 0.74)
        border.width: Theme.border
        border.color: Theme.line
        Accessible.role: Accessible.StaticText
        Accessible.name: loading.tip ? qsTr("Tip: %1 %2").arg(loading.tip.text).arg((loading.tip.keys || []).join(" ")) : ""

        Rectangle {
            x: Theme.px(14)
            anchors.verticalCenter: parent.verticalCenter
            width: Theme.px(5)
            height: parent.height - Theme.px(28)
            radius: width / 2
            color: Theme.pink
        }

        Row {
            id: body
            anchors.centerIn: parent
            spacing: Theme.px(14)

            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("TIP")
                color: Theme.pink
                font.pixelSize: Theme.textSmall
                font.weight: Theme.weightButton
                font.letterSpacing: Theme.px(2)
            }
            Label {
                anchors.verticalCenter: parent.verticalCenter
                text: loading.tip ? loading.tip.text : ""
                font.pixelSize: Theme.textBody
                font.weight: Theme.weightStrong
            }
            Row {
                anchors.verticalCenter: parent.verticalCenter
                spacing: Theme.px(6)
                Repeater {
                    model: loading.tip ? (loading.tip.keys || []) : []
                    Rectangle {
                        required property string modelData
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.max(height, cap.implicitWidth + Theme.px(16))
                        height: Theme.px(30)
                        radius: Theme.px(7)
                        color: Theme.alpha(Theme.text, 0.94)
                        // The lip under a key cap
                        Rectangle { anchors { fill: parent; topMargin: parent.height - Theme.px(4) } radius: parent.radius; color: Theme.alpha(Theme.pinkInk, 0.22) }
                        Label { id: cap; anchors.centerIn: parent; anchors.verticalCenterOffset: -Theme.px(1); text: parent.modelData; color: Theme.pinkInk; font.pixelSize: Theme.textSmall; font.weight: Theme.weightButton }
                    }
                }
            }
        }

        // Each tip fades out, changes, and fades in
        SequentialAnimation {
            id: swap
            NumberAnimation { target: body; property: "opacity"; to: 0; duration: Theme.dur(180) }
            ScriptAction { script: loading.tipIndex = (loading.tipIndex + 1) % loading.tips.length }
            NumberAnimation { target: body; property: "opacity"; to: 1; duration: Theme.dur(220) }
        }
        Timer { interval: 3800; repeat: true; running: loading.running && loading.tips.length > 1; onTriggered: swap.restart() }
    }

    // Which tip of how many
    Row {
        anchors { horizontalCenter: parent.horizontalCenter; top: card.bottom; topMargin: Theme.px(12) }
        visible: loading.tips.length > 1
        spacing: Theme.px(6)
        Repeater {
            model: loading.tips.length
            Rectangle {
                required property int index
                width: index === loading.tipIndex ? Theme.px(18) : Theme.px(6)
                height: Theme.px(6)
                radius: height / 2
                color: index === loading.tipIndex ? Theme.pink : Theme.alpha(Theme.text, 0.3)
                Behavior on width { NumberAnimation { duration: Theme.dur(Theme.normal) } }
            }
        }
    }
}
