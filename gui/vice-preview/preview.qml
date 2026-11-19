// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Runs the real Vice UI (../src/qml/Main.qml with the "vice" file selector)
// against the mock backend in this folder: no console, no app rebuild.
//
//   cd gui/vice-preview
//   QT_FILE_SELECTORS=vice QT_QUICK_CONTROLS_STYLE=Material qml -I . preview.qml -- [scene] [WIDTHxHEIGHT] [shot.png]
//
// With no scene it opens Home with two consoles. `./shots.sh` renders every
// scene to shots/. Scenes are listed in `scenes` below. Everything shown
// here is a fixture; none of it is measured.
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material
import org.streetpea.chiaking
import "../src/qml/vice"
import "../src/qml" as App

Window {
    id: win

    readonly property var args: Qt.application.arguments.slice(Qt.application.arguments.indexOf("--") + 1)
    readonly property string scene: args.length && Qt.application.arguments.includes("--") ? args[0] : "home"
    readonly property var size: (args[1] || "1280x720").split("x")
    readonly property string shot: args[2] || ""
    readonly property var ui: loader.item

    width: parseInt(size[0])
    height: parseInt(size[1])
    visible: true
    color: "black"
    title: "Project Vice preview: " + scene

    function hosts(names) { return Chiaki.sampleHosts.filter(h => !h.display || names.includes(h.name)) }
    function entry(name) { return Vice.consoles(Chiaki.hosts).find(c => c.host.name === name) }
    function daysAgo(days, hour) { const d = new Date(); d.setDate(d.getDate() - days); d.setHours(hour, 0, 0, 0); return d.getTime() }

    readonly property var historyFixture: [
        { console: "Living room", type: "PS5", started: daysAgo(0, 9), seconds: 42 * 60, bitrate: 29.1, loss: 0, dropped: 0, resolution: 4, fps: 60 },
        { console: "Bedroom", type: "PS5", started: daysAgo(1, 20), seconds: 72 * 60, bitrate: 14.2, loss: 1.4, dropped: 3, resolution: 4, fps: 60 },
        { console: "Living room", type: "PS5", started: daysAgo(1, 13), seconds: 35 * 60, bitrate: 29.3, loss: 0, dropped: 0, resolution: 4, fps: 60 },
        { console: "Bedroom", type: "PS5", started: daysAgo(2, 21), seconds: 58 * 60, bitrate: null, loss: null, dropped: 6, resolution: 3, fps: 60 }
    ]
    readonly property var benchmarkFixture: ({
        example: true, link: "Wired  ·  1080p  ·  60 fps",
        rows: [
            { label: "Client pipeline · median", unit: "ms", stock: 12.4, vice: 8.1 },
            { label: "Client pipeline · p99", unit: "ms", stock: 21.6, vice: 13.2 },
            { label: "Stutters per minute", unit: "", stock: 6, vice: 2 }
        ]
    })

    // Dialog and notification fixtures, reused by several scenes
    function lostDialog() { ui.attempt = null; Vice.target = { key: "a", name: "Living room", type: "PS5" }; ui.failureDialog(true, "") }
    function note(kind) {
        const notes = {
            linked: { key: "linked", severity: "success", title: "Console linked", body: "Living room is ready to play.", actionText: "Connect", action: () => console.log("connect") },
            unstable: { key: "unstable:a", severity: "warning", title: "Connection unstable", body: "Packet loss detected. Try a lower bitrate.", actionText: "Adjust stream", action: () => Vice.quickMenuRequested(), sticky: true },
            settings: { key: "settings-saved", severity: "success", title: "Settings saved", body: "Your video preferences have been updated." },
            replay: { key: "replay", severity: "success", title: "Replay saved", body: "Last 30 seconds saved as MP4.", actionText: "Open folder", action: () => console.log("open folder") },
            controller: { key: "controller", severity: "error", iconName: "gamepad", title: "Controller disconnected", body: "Reconnect your controller or use the keyboard.", actionText: "Controller settings", action: () => ui.showTab("settings", { category: "input" }), sticky: true },
            rtx: { key: "rtx", severity: "info", title: "RTX upscaling unavailable", body: "A compatible RTX GPU and plugin are required.", actionText: "Choose another upscaler", action: () => ui.showTab("settings") },
            long: { key: "long", severity: "warning", title: "A notification with a long title that has to wrap onto a second line", body: "Long or localised text wraps inside the notification and never pushes its action or its close button out of reach, however much of it there is.", actionText: "Understood", action: () => { } }
        };
        Vice.notify(notes[kind]);
    }

    readonly property var scenes: ({
        "home": () => { },
        "home-empty": () => { Chiaki.hosts = [] },
        "home-search-off": () => { Chiaki.hosts = []; Chiaki.discoveryEnabled = false },
        "home-one": () => { Chiaki.hosts = hosts(["Living room"]) },
        "home-many": () => { Chiaki.hosts = Chiaki.sampleHosts },
        "home-unpaired": () => { Chiaki.hosts = hosts(["Guest room", "Bedroom"]) },
        "pair": () => { ui.showRegistDialog("192.168.1.20", true); typePin.start() },
        "pair-no-account": () => { Chiaki.settings.psnAccountId = ""; Chiaki.settings.psnAuthToken = ""; ui.showRegistDialog("192.168.1.20", true) },
        "pair-pending": () => { Chiaki.pairOutcome = "hang"; ui.showRegistDialog("192.168.1.20", true); typePin.submit = true; typePin.start() },
        "pair-failed": () => { Chiaki.pairOutcome = "fail"; ui.showRegistDialog("192.168.1.20", true); typePin.submit = true; typePin.start() },
        "pair-linked": () => { Chiaki.pairOutcome = "ok"; ui.showRegistDialog("192.168.1.20", true); typePin.submit = true; typePin.start() },
        "check": () => { ui.showConnectionCheck(entry("Living room")) },
        "check-running": () => { checkFixture = "slow"; ui.showConnectionCheck(entry("Living room")) },
        "check-wifi": () => { checkFixture = "wifi"; ui.showConnectionCheck(entry("Living room")) },
        "check-silent": () => { checkFixture = "silent"; ui.showConnectionCheck(entry("Living room")) },
        "mode": () => { ui.showChooseMode(entry("Living room")) },
        "mode-custom": () => { Chiaki.settings.videoPreset = 5; ui.showChooseMode(entry("Living room")) },
        "settings": () => { ui.showTab("settings") },
        "settings-network": () => { ui.showTab("settings", { category: "network" }) },
        "settings-input": () => { ui.showTab("settings", { category: "input" }) },
        "settings-audio": () => { ui.showTab("settings", { category: "audio" }) },
        "settings-advanced": () => { ui.showTab("settings", { category: "advanced" }) },
        "settings-all": () => { ui.showUpstreamSettings() },
        "profiles": () => { Vice.stickTuning = { preset: "Driving & aiming", left: 8, right: 6, curve: "Smooth" }; Chiaki.settings.currentProfile = "GTA VI"; Chiaki.settings.videoPreset = 0; ui.showProfiles() },
        "profiles-real": () => { ui.showProfiles() },
        "sessions": () => { Vice.history = historyFixture; ui.showTab("sessions") },
        "sessions-empty": () => { Vice.history = []; ui.showTab("sessions") },
        "benchmark": () => { Vice.benchmark = benchmarkFixture; ui.showBenchmark() },
        "benchmark-unavailable": () => { Vice.benchmark = null; ui.showBenchmark() },
        "stream": () => { Chiaki.startSession("192.168.1.20") },
        "stream-quick": () => { Chiaki.startSession("192.168.1.20"); later(() => Vice.quickMenuRequested()) },
        "stream-quick-replay": () => { Vice.replayAvailable = true; Chiaki.startSession("192.168.1.20"); later(() => { Vice.quickMenuRequested(); note("replay") }) },
        "stream-disconnect": () => { Chiaki.startSession("192.168.1.20"); later(() => Chiaki.sessionStopDialogRequested()) },
        "stream-unstable": () => { Chiaki.startSession("192.168.1.20"); later(() => note("unstable")) },
        "waking": () => { Vice.target = { key: "b", name: "Bedroom", type: "PS5" }; Chiaki.wakeupStartInitiated() },
        "dialog-lost": () => lostDialog(),
        "dialog-lost-retrying": () => { Chiaki.connectOutcome = "hang"; lostDialog(); later(() => Vice.resolveDialog("primary")) },
        "dialog-lost-retry-failed": () => { Chiaki.connectOutcome = "fail"; lostDialog(); later(() => Vice.resolveDialog("primary")) },
        "dialog-linked": () => Vice.ask({ key: "linked", severity: "success", title: "Console linked", body: "Living room is ready to play.", console: { name: "Living room", type: "PS5" }, primary: { text: "Connect" }, secondary: { text: "Back to consoles" }, cancel: "secondary" }),
        "dialog-reconnect": () => Vice.ask({ key: "reconnect", severity: "info", title: "Apply stream changes?", body: "A quick reconnect is needed. The stream stops for a moment while it restarts.", primary: { text: "Reconnect" }, secondary: { text: "Cancel" }, cancel: "secondary", defaultFocus: "secondary" }),
        "dialog-unsaved": () => { ui.showTab("settings"); later(() => { ui.children; const page = stackItem(); page.draft = { videoPreset: 0 }; page.revision++; ui.showTab("consoles") }) },
        "dialog-quit": () => ui.confirmQuit(),
        "dialog-long": () => Vice.ask({ key: "long", severity: "warning", title: "A dialog whose title runs long enough to wrap", body: "Long or localised text wraps and scrolls inside the dialog. ".repeat(14), primary: { text: "A primary action" }, secondary: { text: "A secondary action" }, cancel: "secondary" }),
        "dialog-urgent": () => { ui.confirmQuit(); later(() => lostDialog()) },
        "toasts": () => { note("linked"); note("unstable"); note("settings") },
        "toasts-more": () => { note("replay"); note("controller"); note("rtx") },
        "toasts-overflow": () => { ["linked", "unstable", "settings", "replay", "controller", "rtx", "long"].forEach(note); note("unstable") },
        "toast-long": () => note("long"),
        "toast-controller": () => { Chiaki.controllers = [] },
        "toast-controller-back": () => { Chiaki.controllers = []; later(() => { Chiaki.controllers = [Chiaki.controllerFixture] }) },
        "error": () => Chiaki.error("Wakeup failed", "Failed to send Wakeup packet:\nNetwork is unreachable")
    })

    property string checkFixture: "good"
    function stackItem() {
        // Main.qml keeps its StackView private; the current page is its visible child
        for (let i = 0; i < ui.children.length; ++i)
            if (ui.children[i].currentItem !== undefined)
                return ui.children[i].currentItem;
        return null;
    }
    function later(run) { laterTimer.run = run; laterTimer.start() }
    Timer { id: laterTimer; property var run; interval: 500; onTriggered: run() }

    // Types a PIN into the pairing page the way a user would
    Timer {
        id: typePin
        property bool submit: false
        interval: 500
        onTriggered: {
            const page = win.stackItem();
            const pins = [];
            const find = (item) => { if (item.digits !== undefined && item.clear) pins.push(item); for (let i = 0; i < item.children.length; ++i) find(item.children[i]); };
            find(page);
            if (pins.length) {
                pins[0].text = "48210736";
                pins[0].forceActiveFocus(Qt.TabFocusReason);
            }
            if (submit)
                page.submit();
        }
    }

    // Stands in for the video in stream scenes. The app shows the real stream here.
    Rectangle {
        anchors.fill: parent
        visible: Chiaki.session !== null
        gradient: Gradient {
            GradientStop { position: 0; color: "#C9A7D8" }
            GradientStop { position: 0.45; color: "#F2B8A8" }
            GradientStop { position: 1; color: "#4B4763" }
        }
        Text { anchors.centerIn: parent; text: "Preview placeholder for the video"; color: "#30FFFFFF"; font.pixelSize: 28 }
    }

    Loader {
        id: loader
        anchors.fill: parent
        // By type name, as the app's own lookup does, so the "vice" selector
        // swaps in +vice/Main.qml with the same import rules as in the app
        sourceComponent: App.Main { }
        focus: true
        onLoaded: {
            Vice.persist = false;
            Vice.history = [];
            Vice.selectedConsole = "";
            Chiaki.hosts = win.hosts(["Living room", "Bedroom"]);
            const run = win.scenes[win.scene];
            if (run)
                run();
            else
                console.warn("Unknown scene", win.scene, "- try one of:", Object.keys(win.scenes).join(", "));
        }
    }

    Timer {
        interval: 2600
        running: win.shot !== ""
        onTriggered: win.contentItem.grabToImage((image) => { image.saveToFile(win.shot); Qt.quit() })
    }
}
