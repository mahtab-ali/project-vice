// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
pragma Singleton
import QtQuick

// Preview stand-in for the C++ QmlBackend. Deterministic fixtures only:
// nothing here ships in the app, and nothing here is a live measurement.
QtObject {
    id: chiaki

    enum PsnConnectState { NotStarted, WaitingForInternet, InitiatingConnection, LinkingConsole, RegisteringConsole, RegistrationFinished, DataConnectionStart, DataConnectionFinished, ConnectFailed, ConnectFailedStart, ConnectFailedConsoleUnreachable }

    property bool discoveryEnabled: true
    property bool autoConnect: false
    property int connectState: 0
    property var hosts: []
    property var controllers: [controllerFixture]
    property var session: null
    property var window: ChiakiWindow { }

    readonly property var controllerFixture: ({ dualSense: true, dualSenseEdge: false, handheld: false, steamVirtual: false, playStation: true, name: "DualSense Wireless Controller" })
    readonly property var sampleHosts: [
        { display: true, discovered: true, manual: false, registered: true, name: "Living room", address: "192.168.1.20", mac: "a", duid: "", ps5: true, state: "ready", app: "" },
        { display: false, discovered: true, manual: false, registered: false, name: "Hidden", address: "192.168.1.9", mac: "z", duid: "", ps5: true, state: "ready" },
        { display: true, discovered: true, manual: false, registered: true, name: "Bedroom", address: "192.168.1.31", mac: "b", duid: "", ps5: true, state: "standby", app: "" },
        { display: true, discovered: false, manual: true, registered: true, name: "Studio", address: "10.0.0.7", mac: "c", duid: "", ps5: false, state: "unknown" },
        { display: true, discovered: true, manual: false, registered: false, name: "Guest room", address: "192.168.1.44", mac: "d", duid: "", ps5: true, state: "ready", app: "" },
        { display: true, discovered: false, manual: false, registered: true, name: "Office", address: "", mac: "", duid: "remote-1", ps5: true, state: "unknown" }
    ]

    // What the next registerHost() does: "ok" | "fail" | "hang" (never answers)
    property string pairOutcome: "ok"
    // What the next connectToHost() does: "ok" | "fail" | "hang"
    property string connectOutcome: "ok"
    property var pendingRegister: null

    signal error(string title, string text)
    signal sessionError(string title, string text)
    signal registDialogRequested(string host, bool ps5, string duid)
    signal wakeupStartInitiated()
    signal wakeupStartFailed()
    signal showPsnView()
    signal psnCredsExpired()
    signal sessionPinDialogRequested()
    signal psnLoginAccountIdDone(string accountId)
    signal psnLoginAccountIdError(string error)
    // What the next PSN sign-in does: "ok" | "fail" | "hang"
    property string psnOutcome: "ok"
    signal sessionStopDialogRequested()

    property var settings: QtObject {
        property bool streamerMode: false
        property bool addSteamShortcutAsk: false
        property bool remotePlayAsk: false
        property string psnAuthToken: "token"
        property string psnRefreshToken: "token"
        property string psnAuthTokenExpiry: "never"
        property string psnAccountId: "AAAAAAAAAAA="
        property int resolutionLocalPS5: 4
        property int resolutionRemotePS5: 3
        property int resolutionLocalPS4: 3
        property int resolutionRemotePS4: 3
        property int fpsLocalPS5: 60
        property int fpsRemotePS5: 60
        property int fpsLocalPS4: 60
        property int fpsRemotePS4: 60
        property int bitrateLocalPS5: 30000
        property int bitrateRemotePS5: 0
        property int bitrateLocalPS4: 0
        property int bitrateRemotePS4: 0
        property int codecLocalPS5: 1
        property int codecRemotePS5: 1
        property int videoPreset: 2
        property int rendererBackend: 0
        property int windowType: 3
        property bool vSyncEnabled: true
        property bool hideCursor: true
        property bool showStreamStats: true
        property int wifiDroppedNotif: 3
        property int packetLossReportedMax: 5
        property bool iDROnFECFailureEnabled: true
        property bool portGuessingEnabled: false
        property bool buttonsByPosition: false
        property bool keyboardEnabled: true
        property bool mouseTouchEnabled: true
        property bool dpadTouchEnabled: true
        property int rumbleHapticsIntensity: 3
        property bool streamMenuEnabled: true
        property int audioVolume: 128
        property int audioBufferSize: 9600
        property bool directFrameMapping: true
        property int placeboFrameMixer: 0
        property string audioOutDevice: ""
        property string audioInDevice: ""
        property var availableAudioOutDevices: ["Speakers", "Headphones"]
        property var availableAudioInDevices: ["Built-in microphone"]
        property bool startMicUnmuted: false
        property bool speechProcessing: false
        property int audioVideoDisabled: 0
        property int disconnectAction: 2
        property real sZoomFactor: 0
        property var registeredHosts: [{ name: "Living room", mac: "aa:bb:cc:dd:ee:ff" }]
        property var profiles: ["default", "GTA VI", "create new profile"]
        property string currentProfile: ""
        function deleteProfile(name) { profiles = profiles.filter(p => p !== name) }
        function stringForStreamMenuShortcut() { return "L1+R1+L3+R3" }
        function stringForDpadShortcut() { return "L1+R1+Dpad Up" }
    }

    property Timer answer: Timer {
        interval: 900
        onTriggered: {
            const pending = chiaki.pendingRegister;
            chiaki.pendingRegister = null;
            if (pending && chiaki.pairOutcome !== "hang")
                pending(chiaki.pairOutcome === "ok" ? "Registered" : "Regist request failed: 80108b15", chiaki.pairOutcome === "ok", true);
        }
    }

    function connectToHost(index, name) {
        console.log("connectToHost", index, name);
        if (!hosts[index].registered && !hosts[index].duid) {
            registDialogRequested(hosts[index].address, hosts[index].ps5, "");
            return;
        }
        if (connectOutcome === "fail")
            error("Stream failed", "Failed to start Stream Session: console unreachable");
        else if (connectOutcome === "ok")
            startSession(hosts[index].address);
    }
    // "loading" leaves the picture off, which is the connecting state
    function startSession(host, loading) {
        session = sessionFixture.createObject(chiaki, { host: host });
        engineStreaming(true);
        window.hasVideo = !loading;
    }
    function stopSession(sleep) {
        console.log("stopSession", sleep);
        if (!session)
            return;
        session.destroy();
        session = null;
        engineStreaming(false);
        window.hasVideo = false;
    }
    // The preview's Engine fixture shows numbers only while a session is up
    signal engineStreaming(bool on)
    function wakeUpHost(index, name) { console.log("wakeUpHost", index, name) }
    function deleteHost(index) { console.log("deleteHost", index) }
    function hideHost(mac, name) { console.log("hideHost", mac, name) }
    function unhideHost(mac) { console.log("unhideHost", mac) }
    function refreshPsnToken() { console.log("refreshPsnToken") }
    function registerHost(host, psnId, pin, cpin, broadcast, target, callback) {
        // The PIN is never logged, here or in the app
        console.log("registerHost", host, target);
        pendingRegister = callback;
        answer.restart();
        return true;
    }
    function autoRegister() { console.log("autoRegister") }
    function addManualHost(index, address) { console.log("addManualHost", index, address) }
    function setConsolePin(index, pin) { console.log("setConsolePin", index) }
    function openPsnLink() { console.log("openPsnLink"); return "https://example.invalid/psn-sign-in" }
    function psnLoginUrl() { return "about:blank" }
    function checkPsnRedirectURL(url) { return false }
    function setWebEngineHints(profile) { }
    function clearCookies(profile) { }
    function initPsnAuth(url, callback) {
        console.log("initPsnAuth");
        if (psnOutcome === "hang") { callback("Asking PlayStation Network for a token", false, false); return; }
        if (psnOutcome === "ok") settings.psnAuthToken = "token";
        callback(psnOutcome === "ok" ? "Signed in" : "The address was not a PlayStation sign-in redirect", psnOutcome === "ok", true);
    }
    function handlePsnLoginRedirect(url) {
        if (psnOutcome === "ok") psnLoginAccountIdDone("AAAAAAAAAAA=");
        else if (psnOutcome === "fail") psnLoginAccountIdError("The address was not a PlayStation sign-in redirect");
    }
    function stopAutoConnect() { console.log("stopAutoConnect") }
    function sessionGoHome() { console.log("sessionGoHome") }
    function enterPin(pin) { console.log("enterPin") }
    function psnCancel(stop) { console.log("psnCancel") }

    property Component sessionFixture: Component {
        QtObject {
            property string host
            property bool connected: true
            property real measuredBitrate: 29.4
            property real averagePacketLoss: 0
            property bool muted: true
            property bool cantDisplay: false
            property int framesLost: 0
        }
    }
}
