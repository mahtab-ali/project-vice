// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
pragma Singleton
import QtQuick

// Preview stand-in for the C++ ViceEngine. The numbers are fixtures for
// reviewing layouts; the app measures them.
QtObject {
    property bool lowDelayDecoder: true
    property bool qosTagging: true
    property bool threadPriority: true
    property bool systemTuning: true
    property bool systemTuningSupported: false
    property bool stockMode: false

    property real leftDeadzone: 0
    property real rightDeadzone: 0
    property int stickCurve: 0
    property bool viewAsTouchpad: false

    property bool streaming: false
    readonly property real fps: streaming ? 59.8 : NaN
    readonly property real decodeMs: streaming ? 4.6 : NaN
    readonly property real renderMs: streaming ? 9.2 : NaN
    readonly property real pipelineMs: streaming ? 15.8 : NaN
    readonly property int stuttersPerMinute: streaming ? 2 : 0
    property int stallsPerMinute: streaming ? 1 : 0
    readonly property real rttMs: streaming ? 4.7 : NaN
    readonly property real inputMs: streaming ? 0.4 : NaN

    property bool replayEnabled: true
    readonly property real replaySeconds: streaming && replayEnabled ? 30 : 0
    property bool replaySaving: false

    property string wifiBand: "5"
    property int wifiSignal: 96

    signal replaySaved(string path, real seconds)
    signal replayFailed(string reason)

    function beginRun() { }
    function endRun() { return { seconds: 30, frames: 1790, fps: 59.7, pipelineMedian: 15.8, pipelineP99: 30.9, decodeMedian: 3.9, renderMedian: 9.3, stutters: 1, stuttersPerMinute: 2 } }
    function saveReplay() { replaySaved("/home/you/Videos/Project Vice/Replay.mp4", 34.2) }
    function refreshWifi() { }
    function revealFile(path) { console.log("revealFile", path) }
}
