// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../Main.qml, picked by the "vice" file selector.
// It keeps upstream's root API (every show*/open*/close* function upstream
// screens call on `root`) and adds the Vice shell: navigation between
// Consoles / Sessions / Settings, the notification host, the dialog
// coordinator's host, and session records. Blocks marked "upstream" are
// copied unchanged from ../Main.qml; re-copy them when merging upstream.
import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import QtQuick.Controls.Material

import org.streetpea.chiaking
import vice.backend

// A file in +vice/ stands in for the file of the same name one folder up,
// and its imports resolve as if it were that file: so "vice", not "../vice".
import "vice"
import "vice/components" as V
import "vice/screens" as Screens

Item {
    id: root
    property list<Item> restoreFocusItems
    property bool initialAsk: false
    readonly property bool preferSeparateStreamSettingsWindows: Chiaki.window.runtimeRendererBackend === 1 && Chiaki.session
    property bool useSeparateStreamSettingsWindows: false

    // Upstream dialogs are Material controls; give them the Vice palette and type
    Material.theme: Material.Dark
    Material.accent: Theme.pink
    Material.primary: Theme.surfaceSolid
    Material.background: Theme.bg
    Material.foreground: Theme.text

    Binding {
        target: Theme
        property: "scale"
        value: Math.max(0.75, Math.min(3, root.width / 1280, root.height / 720))
    }

    // ---- upstream: root API used by upstream screens ------------------------

    // vice: the label style can be chosen in Settings, Input; "auto" is upstream's rule
    function controllerButton(name) {
        let type = "deck";
        if (Vice.controllerStyle === "ps") {
            type = "ps";
        } else if (Vice.controllerStyle === "auto") {
            for (let i = 0; i < Chiaki.controllers.length; ++i) {
                if (Chiaki.controllers[i].playStation) {
                    type = "ps";
                    break;
                }
            }
        }
        return "image://svg/button-%1#%2".arg(type).arg(name);
    }
    function grabInput(item) {
        Chiaki.window.grabInput();
        restoreFocusItems.push(Window.window.activeFocusItem);
        if (item)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function releaseInput() {
        Chiaki.window.releaseInput();
        let item = restoreFocusItems.pop();
        if (item && item.visible)
            item.forceActiveFocus(Qt.TabFocusReason);
    }

    function autoRegister(auto, host, ps5) {
        if(auto)
            Chiaki.autoRegister()
        else
            showRegistDialog(host, ps5);
    }

    function openDisplaySettings() {
        useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
        const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
        if(loader.status == Loader.Ready)
        {
            if(placeboSettingsRect.opacity || displaySettingsRect.opacity || colorMappingSettingsRect.opacity)
                closeDialog();
            displaySettingsRect.opacity = 0.8;
            grabInput(loader);
            if (!loader.item.restoreFocusItem) {
                let item = loader.item.mainItem.nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
            } else {
                loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                loader.item.restoreFocusItem = null;
            }
        }
    }
    function openPlaceboSettings() {
        if (!displaySettingsRect.opacity && !placeboSettingsRect.opacity && !colorMappingSettingsRect.opacity)
            useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
        const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
        if(loader.status == Loader.Ready)
        {
            if(placeboSettingsRect.opacity || displaySettingsRect.opacity || colorMappingSettingsRect.opacity)
                closeDialog();
            placeboSettingsRect.opacity = 0.8;
            grabInput(loader);
            if (!loader.item.restoreFocusItem) {
                let item = loader.item.mainItem.nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
            } else {
                loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                loader.item.restoreFocusItem = null;
            }
        }
    }

    function closeDialog() {
       if(displaySettingsRect.opacity) {
        displaySettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        releaseInput();
        useSeparateStreamSettingsWindows = false;
       }
       else if(placeboSettingsRect.opacity) {
        placeboSettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        releaseInput();
        useSeparateStreamSettingsWindows = false;
       }
       else if(colorMappingSettingsRect.opacity) {
        releaseInput();
        colorMappingSettingsRect.opacity = 0.0;
        const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
        loader.item.restoreFocusItem = Window.window.activeFocusItem;
        root.openPlaceboSettings();
       }
       else
        stack.pop();
    }

    function showMainView() {
        if(displaySettingsRect.opacity) {
            displaySettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separateDisplaySettingsLoader : displaySettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        else if(placeboSettingsRect.opacity) {
            placeboSettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separatePlaceboSettingsLoader : placeboSettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        else if(colorMappingSettingsRect.opacity) {
            colorMappingSettingsRect.opacity = 0.0;
            const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
            loader.item.restoreFocusItem = Window.window.activeFocusItem;
            releaseInput();
            useSeparateStreamSettingsWindows = false;
        }
        if (stack.depth > 1)
            stack.pop(stack.get(0));
        else
            stack.replace(stack.get(0), mainViewComponent);
    }

    function showStreamView() {
        stack.replace(stack.get(0), streamViewComponent);
    }

    // vice: a live session always shows the stream. If anything left another
    // page on screen while the game is still running (seen after switching
    // away and back on a Steam Deck), this puts the picture back.
    function ensureStreamShown() {
        if (!Chiaki.session)
            return;
        const base = stack.get(0);
        if (base && base.isStreamView === true && stack.depth === 1)
            return;
        if (stack.depth > 1)
            stack.pop(null, StackView.Immediate);
        if (!(stack.get(0) && stack.get(0).isStreamView === true))
            stack.replace(stack.get(0), streamViewComponent, {}, StackView.Immediate);
    }
    Connections {
        target: Chiaki.window
        ignoreUnknownSignals: true
        function onActiveChanged() { root.ensureStreamShown() }
        function onVisibilityChanged() { root.ensureStreamShown() }
    }

    // ---- Vice: Steam Deck controller layout ----------------------------------
    SteamSetup { id: steamSetup }
    readonly property bool steamLayoutAvailable: steamSetup.available
    readonly property string steamShortcutName: Theme.appName

    // Returns true when Steam's settings were changed
    function applyDeckLayout(layout) {
        const problem = steamSetup.applyLayout(steamShortcutName, layout);
        if (problem) {
            Vice.notify({ key: "deck-layout", severity: "error", title: qsTr("Controller layout not changed"), body: problem, sticky: true });
            return false;
        }
        Vice.deckLayout = layout;
        Vice.notify({
            key: "deck-layout",
            severity: "success",
            iconName: "gamepad",
            title: layout === "playstation" ? qsTr("PlayStation layout chosen") : qsTr("Gamepad layout chosen"),
            body: qsTr("Restart Steam to start using it.")
        });
        return true;
    }

    function showPsnView() {
        stack.replace(stack.get(0), psnViewComponent, {}, StackView.Immediate)
    }

    function showManualHostDialog() {
        stack.push(manualHostDialogComponent);
    }

    function showConfirmDialog(title, text, callback, rejectCallback = null) {
        Vice.ask({
            key: "confirm:" + title,
            severity: "question",
            title: title,
            body: text,
            primary: { text: qsTr("Yes"), run: callback },
            secondary: { text: qsTr("No"), run: rejectCallback },
            cancel: "secondary"
        });
    }

    function showInfoDialog(title, text) {
        Vice.ask({ key: "info:" + title, severity: "info", title: title, body: text, primary: { text: qsTr("OK") }, cancel: "primary" });
    }

    function showRendererFallbackDialog(reason) {
        Vice.notify({
            key: "renderer-fallback",
            severity: "info",
            title: qsTr("Using OpenGL"),
            body: qsTr("The Vulkan renderer is not available here: %1").arg(reason)
        });
    }

    // Yes runs the callback, the second button stops the question for good,
    // and closing the dialog means "ask me again next time".
    function showRemindDialog(title, text, remotePlay, callback) {
        Vice.ask({
            key: "remind:" + title,
            severity: "question",
            title: title,
            body: text,
            primary: { text: qsTr("Yes"), run: callback },
            secondary: {
                text: qsTr("Don't ask again"),
                run: () => {
                    if (remotePlay)
                        Chiaki.settings.remotePlayAsk = false;
                    else
                        Chiaki.settings.addSteamShortcutAsk = false;
                }
            },
            cancelText: qsTr("Later"),
            cancel: () => { }
        });
    }

    function showRegistDialog(host, ps5) {
        stack.push(pairComponent, { host: host, ps5: ps5 });
    }

    function showSettingsDialog() {
        showTab("settings");
    }

    function showDisplaySettingsDialog() {
        stack.push(displaySettingsDialogComponent);
    }

    function showPlaceboSettingsDialog() {
        stack.push(placeboSettingsDialogComponent);
    }

    function showPlaceboColorMappingDialog() {
        if(placeboSettingsRect.opacity)
        {
            root.closeDialog();
            useSeparateStreamSettingsWindows = preferSeparateStreamSettingsWindows;
            const loader = useSeparateStreamSettingsWindows ? separateColorMappingSettingsLoader : colorMappingSettingsLoader;
            if(loader.status == Loader.Ready)
            {
                grabInput(loader);
                colorMappingSettingsRect.opacity = 0.8;
                if (!loader.item.restoreFocusItem) {
                    let item = loader.item.mainItem.nextItemInFocusChain();
                    if (item)
                        item.forceActiveFocus(Qt.TabFocusReason);
                } else {
                    loader.item.restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
                    loader.item.restoreFocusItem = null;
                }
            }
        }
        else
            stack.push(placeboColorMappingDialogComponent);
    }

    function showProfileDialog() {
        stack.push(profilesComponent)
    }

    function showConsolePinDialog(consoleIndex) {
        stack.push(consolePinDialogComponent, {consoleIndex: consoleIndex});
    }

    function showSteamShortcutDialog(fromReminder) {
        stack.push(steamShortcutDialogComponent, {fromReminder: fromReminder});
    }

    function showPSNTokenDialog(psnurl, expired) {
        stack.push(psnTokenDialogComponent, {psnurl: psnurl, expired: expired});
    }

    function showControllerMappingDialog() {
        stack.push(controllerMappingDialogComponent)
    }

    // ---- Vice: navigation ---------------------------------------------------

    readonly property var tabComponents: ({ "consoles": mainViewComponent, "sessions": sessionsComponent, "settings": settingsComponent })
    property string currentTab: "consoles"

    function showTab(id, properties) {
        // While a session is live the picture stays on screen; pages wait until it ends
        if (!tabComponents[id] || Chiaki.session)
            return;
        const leave = () => {
            currentTab = id;
            if (stack.depth > 1)
                stack.pop(null, StackView.Immediate);
            stack.replace(stack.get(0), tabComponents[id], properties || {});
        };
        // A page with unsaved edits gets to ask before it is left
        const page = stack.currentItem;
        if (page && typeof page.confirmLeave === "function" && !page.confirmLeave(leave))
            return;
        leave();
    }

    function showUpstreamSettings() { stack.push(settingsDialogComponent) }
    function showProfiles() { stack.push(profilesComponent) }
    function showRemotePlay() { stack.push(remotePlayComponent) }
    function showBenchmark() { stack.push(benchmarkComponent) }
    function showConnectionCheck(entry) { stack.push(connectionCheckComponent, { entry: entry }) }
    function showChooseMode(entry) { stack.push(chooseModeComponent, { entry: entry }) }
    function focusPage() {
        const page = stack.currentItem;
        if (page && typeof page.focusFirst === "function")
            page.focusFirst();
        else if (page)
            page.forceActiveFocus(Qt.TabFocusReason);
    }

    function showAccount() {
        if (!Chiaki.settings.psnAuthToken) {
            showPSNTokenDialog(false);
            return;
        }
        Vice.ask({
            key: "account",
            severity: "success",
            iconName: "user",
            title: qsTr("Signed in to PSN"),
            body: qsTr("Consoles on your account pair without a PIN and can be reached away from home."),
            primary: { text: qsTr("Done") },
            secondary: { text: qsTr("Play from anywhere"), run: () => showRemotePlay() },
            tertiary: { text: qsTr("Sign in again"), run: () => showPSNTokenDialog(false) },
            cancel: "primary"
        });
    }

    function confirmQuit() {
        Vice.ask({
            key: "quit",
            severity: "question",
            title: qsTr("Quit %1?").arg(Theme.appName),
            primary: { text: qsTr("Stay") },
            secondary: { text: qsTr("Quit"), run: () => Qt.quit() },
            cancel: "primary"
        });
    }

    // ---- Vice: console commands --------------------------------------------

    // The configured stream for the selected console type, as plain text
    readonly property string streamSummary: {
        const s = Chiaki.settings;
        const ps5 = !Vice.target || Vice.target.type !== "PS4";
        const resolution = ps5 ? s.resolutionLocalPS5 : s.resolutionLocalPS4;
        const fps = ps5 ? s.fpsLocalPS5 : s.fpsLocalPS4;
        const names = ["360p", "540p", "720p", "1080p"];
        return (names[resolution - 1] || "—") + "  ·  " + qsTr("%1 fps").arg(fps);
    }

    function findConsole(key) {
        return Vice.consoles(Chiaki.hosts).find(c => c.key === key) || null;
    }

    function connectOrPair(entry) {
        if (!entry)
            return;
        Vice.target = Vice.describe(entry);
        if (entry.host.registered || Vice.isRemote(entry.host))
            showChooseMode(entry);
        else
            Chiaki.connectToHost(entry.index);   // unregistered: the backend answers with registDialogRequested
    }

    // Starts one connection attempt. Returns false when the console is not listed right now.
    function startPlaying(key) {
        const entry = findConsole(key);
        if (!entry)
            return false;
        Vice.target = Vice.describe(entry);
        Vice.failed = null;
        attempt = { op: Vice.beginOp("connect"), key: entry.key, connected: false, error: "" };
        if (entry.host.discovered)
            Chiaki.connectToHost(entry.index, entry.host.name);
        else
            Chiaki.connectToHost(entry.index);
        return true;
    }

    function wake(entry) {
        Chiaki.wakeUpHost(entry.index, entry.host.discovered ? entry.host.name : "");
        Vice.notify({
            key: "wake:" + entry.key,
            severity: "info",
            iconName: "power",
            title: qsTr("Wake request sent"),
            body: qsTr("%1 can take a little while to come online.").arg(entry.host.name)
        });
    }

    function removeConsole(entry) {
        const host = entry.host;
        if (host.manual) {
            Vice.ask({
                key: "remove:" + entry.key, severity: "question", title: qsTr("Remove %1?").arg(host.name),
                body: qsTr("It leaves this list. Its pairing is kept in Settings."),
                console: Vice.describe(entry),
                primary: { text: qsTr("Keep") },
                secondary: { text: qsTr("Remove"), danger: true, run: () => Chiaki.deleteHost(entry.index) },
                cancel: "primary"
            });
        } else if (host.discovered && !host.registered) {
            Vice.ask({
                key: "hide:" + entry.key, severity: "question", title: qsTr("Hide %1?").arg(host.name),
                body: qsTr("You can bring it back in Settings, under All settings, Consoles."),
                console: Vice.describe(entry),
                primary: { text: qsTr("Keep") },
                secondary: { text: qsTr("Hide"), danger: true, run: () => Chiaki.hideHost(host.mac, host.name) },
                cancel: "primary"
            });
        }
    }

    // ---- Vice: connection attempts, failures and session records ------------

    // The attempt or session in progress: { op, key, connected, error, started, samples... }
    property var attempt: null
    property double unstableShownAt: 0
    property int unstableStreak: 0
    property int controllerCount: 0

    function failureDialog(wasConnected, detail) {
        const target = Vice.target;
        const name = target ? target.name : qsTr("your console");
        Vice.failed = target;
        Vice.ask({
            key: "connection-lost",
            severity: "error",
            iconName: "linkOff",
            priority: 3,
            title: wasConnected ? qsTr("Connection lost") : qsTr("Couldn't connect"),
            body: (wasConnected ? qsTr("We lost the connection to %1.").arg(name) : qsTr("%1 did not answer.").arg(name))
                  + " " + qsTr("Check your console and network, then try again."),
            error: detail || "",
            console: target ? { name: target.name, type: target.type } : null,
            primary: {
                text: qsTr("Try again"),
                keepOpen: true,
                run: () => {
                    if (!target || !startPlaying(target.key)) {
                        Vice.updateDialog("connection-lost", { busy: false, error: qsTr("%1 is not visible on this network right now.").arg(name) });
                        return;
                    }
                    Vice.updateDialog("connection-lost", { busy: true, busyText: qsTr("Connecting…"), error: "" });
                }
            },
            secondary: { text: qsTr("Back to consoles"), run: () => { Vice.failed = null; Vice.cancelOp("connect"); } },
            cancel: "secondary"
        });
    }

    function sampleSession() {
        const session = Chiaki.session;
        if (!session || !attempt)
            return;
        if (session.connected && !attempt.connected) {
            attempt.connected = true;
            attempt.started = Date.now();
            attempt.bitrate = [];
            attempt.loss = [];
            Vice.closeDialog("connection-lost");
            Vice.failed = null;
        }
        if (!attempt.connected)
            return;
        if (isFinite(session.measuredBitrate) && session.measuredBitrate > 0)
            attempt.bitrate.push(session.measuredBitrate);
        const loss = session.averagePacketLoss;
        if (isFinite(loss))
            attempt.loss.push(loss);
        // Packet loss above the user's own warning threshold, twice in a row
        const threshold = Math.max(0.01, Chiaki.settings.wifiDroppedNotif * 0.01);
        unstableStreak = isFinite(loss) && loss > threshold ? unstableStreak + 1 : 0;
        if (unstableStreak >= 2 && Date.now() - unstableShownAt > 60000) {
            unstableShownAt = Date.now();
            Vice.notify({
                key: "unstable:" + attempt.key,
                severity: "warning",
                title: qsTr("Connection unstable"),
                body: qsTr("Packet loss detected. Try a lower bitrate."),
                actionText: qsTr("Adjust stream"),
                action: () => Vice.quickMenuRequested(),
                sticky: true
            });
        }
    }

    function finishSession() {
        const done = attempt;
        attempt = null;
        Vice.dismissToast("unstable:" + (done ? done.key : ""));
        if (!done)
            return;
        if (done.connected) {
            const mean = (list) => list.length ? list.reduce((a, b) => a + b, 0) / list.length : null;
            const ps5 = !Vice.target || Vice.target.type !== "PS4";
            Vice.recordSession({
                console: Vice.target ? Vice.target.name : "",
                type: Vice.target ? Vice.target.type : "",
                started: done.started,
                seconds: Math.round((Date.now() - done.started) / 1000),
                bitrate: mean(done.bitrate),
                loss: mean(done.loss) === null ? null : mean(done.loss) * 100,
                dropped: done.dropped === undefined ? null : done.dropped,
                resolution: ps5 ? Chiaki.settings.resolutionLocalPS5 : Chiaki.settings.resolutionLocalPS4,
                fps: ps5 ? Chiaki.settings.fpsLocalPS5 : Chiaki.settings.fpsLocalPS4
            });
        }
        if (done.error && Vice.isCurrent("connect", done.op))
            failureDialog(done.connected, done.error);
        else if (Vice.reconnect && Vice.isCurrent("reconnect", Vice.reconnect.op))
            resumeAfterReconnect();
    }

    // "Reconnect to apply": the session was ended on purpose; start it again once
    function resumeAfterReconnect() {
        const request = Vice.reconnect;
        Vice.reconnect = null;
        if (!startPlaying(request.key))
            failureDialog(false, qsTr("The console is not visible on this network right now."));
    }

    Timer {
        interval: 2000
        repeat: true
        running: Chiaki.session !== null
        onTriggered: {
            root.ensureStreamShown();
            root.sampleSession();
            if (root.attempt && root.attempt.connected)
                root.attempt.dropped = Chiaki.window.droppedFrames;
        }
    }

    // Focus rings follow how the user is driving the app (see Theme.keyboardNav)
    HoverHandler { onPointChanged: Theme.keyboardNav = false }

    // A handheld (Steam Deck) is told by its built-in controls
    Binding { target: Theme; property: "handheld"; value: Chiaki.controllers.some(c => c.handheld === true) }

    // ---- Vice: window chrome ----------------------------------------------------
    // The system title bar is turned off and the app draws the window's controls
    // itself (components/TitleBar.qml), so the top of the window is the same
    // picture and gradient as the rest. A setting turns the system bar back on.
    // A handheld runs full screen and is left alone.
    readonly property bool chromeSupported: !Theme.handheld
    readonly property bool frameless: chromeSupported && Vice.blendTitleBar
    readonly property bool fullScreen: Chiaki.window.visibility === 5   // Window.FullScreen
    readonly property bool maximized: Chiaki.window.visibility === 4    // Window.Maximized
    readonly property bool chromeBlended: frameless && !fullScreen

    function applyChrome() {
        const flags = Chiaki.window.flags;
        if (flags === undefined)
            return;
        // Without a frame the window still needs to be allowed to minimise, maximise and close
        const framelessFlags = Qt.FramelessWindowHint | Qt.WindowSystemMenuHint | Qt.WindowMinimizeButtonHint | Qt.WindowMaximizeButtonHint | Qt.WindowCloseButtonHint;
        const wanted = frameless ? (flags | framelessFlags) : (flags & ~Qt.FramelessWindowHint);
        if (wanted !== flags)
            Chiaki.window.flags = wanted;
    }
    onFramelessChanged: applyChrome()
    Binding { target: Theme; property: "topInset"; value: !root.chromeBlended ? 0 : Qt.platform.os === "osx" ? Theme.px(10) : Theme.px(20) }

    function toggleFullScreen() {
        if (root.fullScreen)
            Chiaki.window.showNormal();
        else
            Chiaki.window.showFullScreen();
    }
    function toggleMaximized() {
        if (root.maximized)
            Chiaki.window.showNormal();
        else
            Chiaki.window.showMaximized();
    }

    Component.onCompleted: {
        applyChrome();
        Theme.keyboardNav = Chiaki.controllers.length > 0;
        controllerCount = Chiaki.controllers.length;
        // First run on a Steam Deck: give Steam a layout whose triggers, touchpad
        // and menu buttons reach the game, unless one is already set
        if (steamSetup.available && !Vice.deckLayout && Chiaki.controllers.some(c => c.handheld === true)) {
            const current = steamSetup.currentLayout(steamShortcutName);
            if (current)
                Vice.deckLayout = current;
            else
                applyDeckLayout("playstation");
        }
        if (Chiaki.session)
            stack.replace(stack.get(0), streamViewComponent, {}, StackView.Immediate);
        else if (Chiaki.autoConnect)
            stack.replace(stack.get(0), autoConnectViewComponent, {}, StackView.Immediate);
    }

    // ---- Scene ---------------------------------------------------------------

    Rectangle {
        anchors.fill: parent
        color: Theme.bg
        visible: !Chiaki.window.hasVideo && !Chiaki.window.keepVideo
    }

    StackView {
        id: stack
        anchors.fill: parent
        hoverEnabled: false
        initialItem: mainViewComponent
        font.pixelSize: 20
        font.family: Theme.family

        replaceEnter: Transition { NumberAnimation { property: "opacity"; from: 0.01; to: 1; duration: Theme.dur(Theme.normal) } }
        replaceExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.normal) } }
        pushEnter: Transition { NumberAnimation { property: "opacity"; from: 0.01; to: 1; duration: Theme.dur(Theme.normal) } }
        pushExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.normal) } }
        popEnter: Transition { NumberAnimation { property: "opacity"; from: 0.01; to: 1; duration: Theme.dur(Theme.normal) } }
        popExit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.normal) } }
    }

    // ---- upstream: in-stream display and placebo settings panels -------------

    Rectangle {
        id: placeboSettingsRect
        opacity: 0.0
        visible: opacity && !useSeparateStreamSettingsWindows
        height: 650
        width: 1200
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        color: Material.background
        Loader {
            anchors.fill: parent
            id: placeboSettingsLoader
            sourceComponent: placeboSettingsDialogComponent
        }
    }
    Rectangle {
        id: displaySettingsRect
        opacity: 0.0
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        height: 500
        width: 1200
        visible: opacity && !useSeparateStreamSettingsWindows
        color: Material.background
        Loader {
            anchors.fill: parent
            id: displaySettingsLoader
            sourceComponent: displaySettingsDialogComponent
        }
    }
    Rectangle {
        id: colorMappingSettingsRect
        anchors.top: parent.top
        anchors.horizontalCenter: parent.horizontalCenter
        opacity: 0.0
        height: 600
        width: 1200
        visible: opacity && !useSeparateStreamSettingsWindows
        color: Material.background
        Loader {
            anchors.fill: parent
            id: colorMappingSettingsLoader
            sourceComponent: placeboColorMappingDialogComponent
        }
    }

    Window {
        id: separateDisplaySettingsWindow
        visible: useSeparateStreamSettingsWindows && displaySettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: separateDisplaySettingsLoader.item ? Math.min(Math.round(root.height), Math.round(separateDisplaySettingsLoader.item.gridHeight + 140)) : 500
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separateDisplaySettingsLoader
            sourceComponent: displaySettingsDialogComponent
        }
    }

    Window {
        id: separatePlaceboSettingsWindow
        visible: useSeparateStreamSettingsWindows && placeboSettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: Math.min(Math.round(root.height), 650)
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separatePlaceboSettingsLoader
            sourceComponent: placeboSettingsDialogComponent
        }
    }

    Window {
        id: separateColorMappingSettingsWindow
        visible: useSeparateStreamSettingsWindows && colorMappingSettingsRect.opacity > 0.0
        transientParent: Chiaki.window
        flags: Qt.Dialog | Qt.FramelessWindowHint
        color: Material.background
        modality: Qt.NonModal
        x: Math.round(root.mapToGlobal(0, 0).x)
        y: Math.round(root.mapToGlobal(0, 0).y)
        width: Math.round(root.width)
        height: Math.min(Math.round(root.height), 600)
        onVisibleChanged: if (visible) requestActivate()

        Shortcut {
            sequence: "Ctrl+O"
            onActivated: root.closeDialog()
        }

        Shortcut {
            sequence: StandardKey.Cancel
            onActivated: root.closeDialog()
        }

        Loader {
            anchors.fill: parent
            id: separateColorMappingSettingsLoader
            sourceComponent: placeboColorMappingDialogComponent
        }
    }

    // The window's own controls. Over a stream they show only while the pointer is at the top.
    HoverHandler { id: topEdge; margin: 0; enabled: root.chromeBlended; onPointChanged: topEdge.near = point.position.y < Theme.px(40) ; property bool near: false }
    V.TitleBar {
        z: 45
        width: parent.width
        visible: root.chromeBlended && (!Chiaki.session || topEdge.near)
        onMaximizeToggled: root.toggleMaximized()
    }

    // Without a frame, the edges resize the window. macOS does this itself.
    Repeater {
        model: root.chromeBlended && !root.maximized && Qt.platform.os !== "osx" ? [
            { edges: Qt.LeftEdge, cursor: Qt.SizeHorCursor }, { edges: Qt.RightEdge, cursor: Qt.SizeHorCursor },
            { edges: Qt.TopEdge, cursor: Qt.SizeVerCursor }, { edges: Qt.BottomEdge, cursor: Qt.SizeVerCursor },
            { edges: Qt.LeftEdge | Qt.TopEdge, cursor: Qt.SizeFDiagCursor }, { edges: Qt.RightEdge | Qt.BottomEdge, cursor: Qt.SizeFDiagCursor },
            { edges: Qt.RightEdge | Qt.TopEdge, cursor: Qt.SizeBDiagCursor }, { edges: Qt.LeftEdge | Qt.BottomEdge, cursor: Qt.SizeBDiagCursor }
        ] : []
        MouseArea {
            required property var modelData
            readonly property int grip: Theme.px(5)
            readonly property bool horizontal: (modelData.edges & (Qt.LeftEdge | Qt.RightEdge)) !== 0
            readonly property bool vertical: (modelData.edges & (Qt.TopEdge | Qt.BottomEdge)) !== 0
            z: 46
            x: modelData.edges & Qt.RightEdge ? root.width - grip : 0
            y: modelData.edges & Qt.BottomEdge ? root.height - grip : 0
            width: horizontal ? grip : root.width
            height: vertical ? grip : root.height
            cursorShape: modelData.cursor
            onPressed: Chiaki.window.startSystemResize(modelData.edges)
        }
    }

    // ---- Vice: the one notification host and the one dialog host ------------

    V.NotificationHost {
        id: notifications
        z: 50
        inStream: Chiaki.session !== null
        // Over the stream the OpenGL renderer cannot draw QML above the video
        visible: !(inStream && (Chiaki.window.runtimeRendererBackend === 1 || Vice.cleanView))
        // Over the game: bottom left, where game notices usually sit, clear of
        // the quick menu. On pages: top right, clear of the content on the left.
        x: inStream ? Theme.px(28) : parent.width - width - Theme.margin + Theme.unit
        y: inStream ? parent.height - height - Theme.px(28) : Theme.headerHeight
        onFocusFallback: root.focusPage()
    }

    V.DialogHost {
        id: dialogHost
        suppressed: Chiaki.session !== null && Chiaki.window.runtimeRendererBackend === 1
        onFocusFallback: root.focusPage()
        // While a dialog owns the controller, its input must not reach the game
        onOpened: if (Chiaki.session) Chiaki.window.grabInput()
        onClosed: if (Chiaki.session) Chiaki.window.releaseInput()
    }

    Connections {
        target: Chiaki

        function onSessionChanged() {
            if (Chiaki.session) {
                if (!root.attempt)
                    root.attempt = { op: Vice.beginOp("connect"), key: Vice.target ? Vice.target.key : "", connected: false, error: "" };
                root.showStreamView();
            } else {
                root.finishSession();
            }
        }

        function onShowPsnView() {
            root.showPsnView();
        }

        function onPsnCredsExpired() {
            Chiaki.settings.psnRefreshToken = ""
            Chiaki.settings.psnAuthToken = ""
            Chiaki.settings.psnAuthTokenExpiry = ""
            Chiaki.settings.psnAccountId = ""
            root.showPSNTokenDialog(true);
        }

        // Failures outside a session: they stay until dismissed
        function onError(title, text) {
            if (root.attempt && !Chiaki.session) {
                const done = root.attempt;
                root.attempt = null;
                if (Vice.isCurrent("connect", done.op)) {
                    root.failureDialog(false, text);
                    return;
                }
            }
            Vice.notify({ key: "error:" + title, severity: "error", title: title, body: text, sticky: true });
        }

        // A session that ended with an error: shown once it has closed
        function onSessionError(title, text) {
            if (root.attempt)
                root.attempt.error = text || title;
        }

        function onControllersChanged() {
            const count = Chiaki.controllers.length;
            if (count === 0 && root.controllerCount > 0) {
                Vice.notify({
                    key: "controller",
                    severity: "error",
                    iconName: "gamepad",
                    title: qsTr("Controller disconnected"),
                    body: qsTr("Reconnect your controller or use the keyboard."),
                    // Settings can't open over a live game, so there the notice has no action
                    actionText: Chiaki.session ? "" : qsTr("Controller settings"),
                    action: Chiaki.session ? null : () => root.showTab("settings", { category: "input" }),
                    sticky: true
                });
            } else if (count > 0) {
                Vice.dismissToast("controller");
            }
            root.controllerCount = count;
        }

        function onRegistDialogRequested(host, ps5, duid) {
            if (!duid) {
                showRegistDialog(host, ps5);
                return;
            }
            Vice.ask({
                key: "auto-register",
                severity: "question",
                title: qsTr("Pair with your PSN account?"),
                body: ps5 ? qsTr("This console is on your PSN account, so it can be paired without a PIN.")
                          : qsTr("This works when the console is the main PS4 on your PSN account."),
                primary: { text: qsTr("Pair automatically"), run: () => root.autoRegister(true, host, ps5) },
                secondary: { text: qsTr("Enter a PIN"), run: () => root.autoRegister(false, host, ps5) },
                cancelText: qsTr("Cancel"),
                cancel: () => { }
            });
        }

        function onWakeupStartInitiated() {
            stack.replace(stack.get(0), autoConnectViewComponent, {}, StackView.Immediate);
        }
    }

    Component { id: mainViewComponent; Screens.Home { } }
    Component { id: sessionsComponent; Screens.Sessions { } }
    Component { id: settingsComponent; Screens.Settings { } }
    Component { id: pairComponent; Screens.Pair { } }
    Component { id: connectionCheckComponent; Screens.ConnectionCheck { } }
    Component { id: chooseModeComponent; Screens.ChooseMode { } }
    Component { id: profilesComponent; Screens.Profiles { } }
    Component { id: benchmarkComponent; Screens.Benchmark { } }
    Component { id: remotePlayComponent; Screens.RemotePlay { } }

    Component { id: streamViewComponent; StreamView { } }
    Component { id: autoConnectViewComponent; AutoConnectView { } }
    Component { id: psnViewComponent; PsnView { } }
    Component { id: manualHostDialogComponent; ManualHostDialog { } }
    Component { id: settingsDialogComponent; SettingsDialog { } }
    Component { id: displaySettingsDialogComponent; DisplaySettingsDialog { } }
    Component { id: placeboSettingsDialogComponent; PlaceboSettingsDialog { } }
    Component { id: placeboColorMappingDialogComponent; PlaceboColorMappingDialog { } }
    Component { id: consolePinDialogComponent; ConsolePinDialog { } }
    Component { id: steamShortcutDialogComponent; SteamShortcutDialog { } }
    Component { id: psnTokenDialogComponent; PSNTokenDialog { } }
    Component { id: controllerMappingDialogComponent; ControllerMappingDialog { } }
}
