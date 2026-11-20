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

    // "full": everything. "compact": one line with the figures that matter while playing.
    // "mini": frame rate and ping.
    property string size: Vice.readoutSize
    readonly property bool full: size === "full"
    readonly property bool mini: size === "mini"

    implicitWidth: row.implicitWidth + (full ? Theme.unit * 5 : Theme.px(22))
    implicitHeight: full ? Theme.px(62) : Theme.px(30)
    radius: full ? Theme.px(16) : height / 2
    color: Theme.alpha(Theme.surfaceSolid, full ? 0.86 : 0.72)
    border.width: full ? Theme.border : 0
    border.color: Theme.line
    Accessible.role: Accessible.StaticText
    Accessible.name: qsTr("Stream statistics")

    // tier 0 shows in every size, 1 from compact up, 2 only in full
    component Stat: Row {
        property alias label: statLabel.text
        property alias value: statValue.text
        property int tier: 2
        visible: tier === 0 || (tier === 1 && !overlay.mini) || overlay.full
        anchors.verticalCenter: parent.verticalCenter
        spacing: overlay.full ? Theme.unit * 1.75 : Theme.px(10)
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: overlay.full ? Theme.px(32) : Theme.px(12); color: Theme.alpha(Theme.text, 0.3) }
        Grid {
            anchors.verticalCenter: parent.verticalCenter
            columns: overlay.full ? 1 : 2
            columnSpacing: Theme.px(5)
            verticalItemAlignment: Grid.AlignVCenter
            V.Label { id: statLabel; font.pixelSize: overlay.full ? Theme.textSmall : Theme.px(11); color: overlay.full ? Theme.text : Theme.textMuted }
            V.Label { id: statValue; font.pixelSize: overlay.full ? Theme.textBody : Theme.px(13); font.weight: Theme.weightButton }
        }
    }

    Row {
        id: row
        anchors.centerIn: parent
        spacing: overlay.full ? Theme.unit * 1.75 : Theme.px(10)

        Row {
            anchors.verticalCenter: parent.verticalCenter
            visible: overlay.full
            spacing: Theme.unit * 1.25
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(12); height: width; radius: width / 2; color: Theme.pink }
            V.Label { anchors.verticalCenter: parent.verticalCenter; text: Vice.modeText(overlay.mode); font.pixelSize: Theme.textLabel; font.weight: Theme.weightStrong }
        }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; visible: overlay.full; width: Theme.border; height: Theme.px(32); color: Theme.alpha(Theme.text, 0.3) }
        V.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: Vice.valueText(Engine.fps, "", 0) + " " + qsTr("fps")
            font.pixelSize: overlay.full ? Theme.px(28) : Theme.px(14)
            font.weight: Theme.weightDisplay
        }
        // What the game is really drawing: below the stream's rate when pictures repeat
        Stat { tier: 0; label: qsTr("Game"); value: Vice.valueText(Engine.uniqueFps, "", 0) + " " + qsTr("fps") }
        Stat { tier: 1; label: qsTr("Mbps"); value: overlay.session ? Vice.valueText(overlay.session.measuredBitrate, "", 1) : "—" }
        Stat { tier: 0; label: qsTr("Ping"); value: Vice.valueText(Engine.rttMs, " ms", 0) }
        Stat { tier: 1; label: qsTr("Loss"); value: overlay.session ? Vice.valueText(overlay.session.averagePacketLoss * 100, "%", 1) : "—" }
        Stat { label: qsTr("Decode"); value: Vice.valueText(Engine.decodeMs, " ms", 1) }
        // Drawing a frame, which includes scaling it to the window
        Stat { label: qsTr("Render"); value: Vice.valueText(Engine.renderMs, " ms", 1) }
        // From a frame arriving to it being drawn: the client's share of the delay
        Stat { tier: 1; label: qsTr("Client"); value: Vice.valueText(Engine.pipelineMs, " ms", 0) }
        Stat { label: qsTr("Input"); value: Vice.valueText(Engine.inputMs, " ms", 1) }
        Stat { label: qsTr("Dropped"); value: Vice.valueText(Chiaki.window.droppedFrames, "", 0) }
        // Times in the last minute the link went quiet for three frames or more
        Stat { tier: 1; label: qsTr("Pauses"); value: isNaN(Engine.fps) ? "—" : qsTr("%1/min").arg(Engine.stallsPerMinute) }
    }
}
