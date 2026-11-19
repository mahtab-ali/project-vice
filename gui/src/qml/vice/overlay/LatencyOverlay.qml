// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking
import vice.backend

import ".."
import "../components" as V

// Compact stream readout. Every figure is measured by the client: frame rate,
// received bitrate, round trip to the console (taken once while connecting),
// packet loss, decode and draw time, the client's whole share of the delay,
// how long a controller change waits before it is sent, and frames dropped.
// A figure that has not been measured yet shows as a dash.
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
        spacing: Theme.unit * 1.75

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.unit * 1.25
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(12); height: width; radius: width / 2; color: Theme.pink }
            V.Label { anchors.verticalCenter: parent.verticalCenter; text: Vice.modeText(overlay.mode); font.pixelSize: Theme.textLabel; font.weight: Theme.weightStrong }
        }
        Rule { }
        V.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Vice.valueText(Engine.fps, "", 0) + " " + qsTr("fps")
            font.pixelSize: Theme.px(28)
            font.weight: Theme.weightDisplay
        }
        Rule { }
        Stat { label: qsTr("Mbps"); value: overlay.session ? Vice.valueText(overlay.session.measuredBitrate, "", 1) : "—" }
        Rule { }
        Stat { label: qsTr("Ping"); value: Vice.valueText(Engine.rttMs, " ms", 0) }
        Rule { }
        Stat { label: qsTr("Loss"); value: overlay.session ? Vice.valueText(overlay.session.averagePacketLoss * 100, "%", 1) : "—" }
        Rule { }
        Stat { label: qsTr("Decode"); value: Vice.valueText(Engine.decodeMs, " ms", 1) }
        Rule { }
        // Drawing a frame, which includes scaling it to the window
        Stat { label: qsTr("Render"); value: Vice.valueText(Engine.renderMs, " ms", 1) }
        Rule { }
        // From a frame arriving to it being drawn: the client's share of the delay
        Stat { label: qsTr("Client"); value: Vice.valueText(Engine.pipelineMs, " ms", 0) }
        Rule { }
        Stat { label: qsTr("Input"); value: Vice.valueText(Engine.inputMs, " ms", 1) }
        Rule { }
        Stat { label: qsTr("Dropped"); value: Vice.valueText(Chiaki.window.droppedFrames, "", 0) }
        Rule { }
        // Times in the last minute the link went quiet for three frames or more
        Stat { label: qsTr("Pauses"); value: isNaN(Engine.fps) ? "—" : qsTr("%1/min").arg(Engine.stallsPerMinute) }
    }
}
