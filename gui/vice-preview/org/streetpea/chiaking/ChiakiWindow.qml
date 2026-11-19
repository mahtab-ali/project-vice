// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

// Preview stand-in for QmlMainWindow: the enums and properties screens read.
QtObject {
    enum VideoMode { Normal, Stretch, Zoom }
    enum VideoPreset { Fast, Default, HighQuality, HighQualitySpatial, HighQualityAdvancedSpatial, Custom }

    property bool hasVideo: false
    property bool keepVideo: false
    property bool directStream: false
    property bool loadingTransitionComplete: true
    property int runtimeRendererBackend: 0
    property int droppedFrames: 0
    property real queueDepthAverage: 1.2
    property real pendingFrameAge: 0.004
    property int videoMode: 0
    property int videoPreset: 2
    property real zoomFactor: 0
    property string title: "chiaki-ng"
    property int flags: 0
    property int visibility: 2
    function showFullScreen() { visibility = 5 }
    function showNormal() { visibility = 2 }
    property int grabs: 0

    function grabInput() { grabs++ }
    function releaseInput() { grabs-- }
    function requestOverlayUpdate() { }
    function setOverlayInteractionActive(active) { }
    function setStatsOverlayActive(active) { }
    function noteLoadingTransitionComplete() { }
    function close() { console.log("window.close") }
}
