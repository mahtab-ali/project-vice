// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking

import ".."
import "../components" as V

// Compact stream readout. It shows what the client actually measures:
// received bitrate, packet loss, how long a frame waits to be shown, and
// frames dropped. Frame rate, ping, decode and upscale time are not measured
// by this build, so they are not shown.
Rectangle {
    id: overlay

    readonly property var session: Chiaki.session
    readonly property string mode: Vice.modeOf(Chiaki.window.videoPreset)

    implicitWidth: row.implicitWidth + Theme.unit * 5
    implicitHeight: Theme.px(62)
    radius: Theme.px(16)
    color: Theme.alpha(Theme.surfaceSolid, 0.86)
    border.width: Theme.border
    border.color: Theme.line
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("Stream statistics")

    component Rule: Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(32); color: Theme.alpha(Theme.text, 0.3) }
    component Stat: Column {
        property alias label: statLabel.text
        property alias value: statValue.text
        anchors.verticalCenter: parent.verticalCenter
        V.Label { id: statLabel; font.pixelSize: Theme.textSmall }
        V.Label { id: statValue; font.pixelSize: Theme.textBody; font.weight: Theme.weightButton }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: Theme.unit * 2.25

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.unit * 1.5
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(12); height: width; radius: width / 2; color: Theme.pink }
            V.Label { anchors.verticalCenter: parent.verticalCenter; text: Vice.modeText(overlay.mode); font.pixelSize: Theme.textLabel; font.weight: Theme.weightStrong }
        }
        Rule { }
        V.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: overlay.session ? Vice.valueText(overlay.session.measuredBitrate, "", 1) + " " + qsTr("Mbps") : "—"
            font.pixelSize: Theme.px(30)
            font.weight: Theme.weightDisplay
        }
        Rule { }
        Stat { label: qsTr("Loss"); value: overlay.session ? Vice.valueText(overlay.session.averagePacketLoss * 100, "%", 1) : "—" }
        Rule { }
        Stat { label: qsTr("Frame wait"); value: Vice.valueText(Chiaki.window.pendingFrameAge * 1000, " ms", 0) }
        Rule { }
        Stat { label: qsTr("Dropped"); value: Vice.valueText(Chiaki.window.droppedFrames, "", 0) }
    }
}
