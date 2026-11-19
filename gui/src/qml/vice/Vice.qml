// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
pragma Singleton
import QtQuick
import QtCore

// Vice UI state that the upstream backend does not keep: the notification
// queue, the dialog coordinator, operation identities, local session history
// and a few preferences. No visuals here, so it can be tested on its own
// (see gui/vice-preview/tests).
QtObject {
    id: vice

    // ---- Preferences and local records -------------------------------------

    // The preview harness turns this off so fixtures never reach disk
    property bool persist: true
    property bool reduceMotion: false
    // Draw the app under the window's title bar, so the bar blends into the page
    property bool blendTitleBar: true
    // During play: no readout, no hints, no notices over the picture
    property bool cleanView: false
    // Stable key of the console shown as the hero on Home
    property string selectedConsole: ""
    // [{ console, type, started, seconds, bitrate, loss, dropped, resolution, fps }]; null = not recorded
    property var history: []
    // Last finished connection check: { key, ping, jitter, loss, link, samples, at }
    property var lastCheck: null
    // The console the user last asked to connect to: { key, name, type }
    property var target: null
    // Set while a connection attempt or session has failed and is unresolved
    property var failed: null
    // A session ended on purpose to apply stream changes: { op, key }
    property var reconnect: null
    // Benchmark results; null until a build can measure them: { example, link, rows: [{ label, unit, stock, vice }] }
    property var benchmark: null
    // Stick tuning values; null until the backend has deadzones and curves: { preset, left, right, curve }
    property var stickTuning: null
    // Replay capture; false until a build can record the stream
    property bool replayAvailable: false
    // Asks the stream view to open the quick menu (from a notification action)
    signal quickMenuRequested()
    // Asks for the last seconds of the stream to be saved; nothing answers it until replay capture exists
    signal replayRequested()

    readonly property int historyLimit: 50

    property Settings store: Settings {
        category: "vice"
        property string history: "[]"
        property string selectedConsole: ""
        property bool reduceMotion: false
        property bool blendTitleBar: true
        property bool cleanView: false
    }

    Component.onCompleted: {
        reduceMotion = store.reduceMotion;
        blendTitleBar = store.blendTitleBar;
        cleanView = store.cleanView;
        selectedConsole = store.selectedConsole;
        try { history = JSON.parse(store.history); } catch (e) { history = []; }
    }
    onReduceMotionChanged: { Theme.reducedMotion = reduceMotion; if (persist) store.reduceMotion = reduceMotion; }
    onSelectedConsoleChanged: if (persist) store.selectedConsole = selectedConsole
    onBlendTitleBarChanged: if (persist) store.blendTitleBar = blendTitleBar
    onCleanViewChanged: if (persist) store.cleanView = cleanView

    function recordSession(entry) {
        history = [entry].concat(history).slice(0, historyLimit);
        if (persist)
            store.history = JSON.stringify(history);
    }

    function clearHistory() {
        history = [];
        if (persist)
            store.history = "[]";
    }

    // ---- Console helpers ----------------------------------------------------

    // Chiaki.hosts keeps hidden entries and backend calls take an index into
    // that full list, so every visible console carries its original index
    // and a key that survives discovery refreshes.
    function consoles(hosts) {
        const out = [];
        for (let i = 0; i < hosts.length; ++i) {
            const host = hosts[i];
            if (host.display)
                out.push({ index: i, key: host.mac || host.duid || host.address || host.name, host: host });
        }
        return out;
    }
    // Consoles the app has found on this network, hidden ones included, each
    // with the address discovery reported for it. Nobody has to type these.
    function found(hosts) {
        const out = [];
        for (let i = 0; i < hosts.length; ++i) {
            const host = hosts[i];
            if (host.discovered && host.address)
                out.push({ index: i, key: host.mac || host.address, name: host.name, address: host.address, ps5: host.ps5 !== false,
                           registered: host.registered === true, hidden: host.display === false, mac: host.mac || "", state: stateOf(host) });
        }
        return out;
    }
    function stateOf(host) { return host.state === "ready" ? "on" : host.state === "standby" ? "rest" : "off" }
    function consoleIcon(type) { return type === "PS4" ? "console4" : "console" }
    function typeOf(host) { return host.ps5 === undefined ? "" : host.ps5 ? "PS5" : "PS4" }
    function isRemote(host) { return host.duid && !host.discovered ? true : false }
    function stateText(host) {
        if (isRemote(host))
            return qsTr("Away, through PSN");
        if (host.state === "ready")
            return qsTr("Online");
        if (host.state === "standby")
            return qsTr("Rest mode");
        return qsTr("Not found");
    }
    // Game and Quality are two of upstream's renderer presets (ChiakiWindow.VideoPreset)
    function modeOf(preset) { return preset === 0 ? "game" : preset === 2 ? "quality" : "custom" }
    function presetFor(mode) { return mode === "game" ? 0 : 2 }
    function modeText(mode) { return mode === "game" ? qsTr("Game") : mode === "quality" ? qsTr("Quality") : qsTr("Custom") }
    function canWake(host) { return host.registered && !host.duid && host.state !== "ready" ? true : false }
    function describe(entry) { return { key: entry.key, name: entry.host.name, type: typeOf(entry.host), remote: isRemote(entry.host) } }

    function durationText(seconds) {
        if (seconds === null || seconds === undefined)
            return "—";
        const minutes = Math.round(seconds / 60);
        if (minutes < 1)
            return qsTr("Under a minute");
        if (minutes < 60)
            return qsTr("%1 min").arg(minutes);
        return qsTr("%1 hr %2 min").arg(Math.floor(minutes / 60)).arg(minutes % 60);
    }
    function dayText(ms) {
        const days = Math.floor((new Date().setHours(0, 0, 0, 0) - new Date(ms).setHours(0, 0, 0, 0)) / 86400000);
        return days <= 0 ? qsTr("Today") : days === 1 ? qsTr("Yesterday") : qsTr("%1 days ago").arg(days);
    }
    // Missing measurements read as a dash, never as zero
    function valueText(value, unit, digits) {
        return value === null || value === undefined || !isFinite(value) ? "—" : Number(value).toFixed(digits || 0) + (unit || "");
    }

    // ---- Operation identity -------------------------------------------------

    // Each start bumps the id; a callback that arrives with an old id is stale.
    property var ops: ({})
    function beginOp(name) {
        ops[name] = (ops[name] || 0) + 1;
        return ops[name];
    }
    function cancelOp(name) { ops[name] = (ops[name] || 0) + 1 }
    function isCurrent(name, id) { return ops[name] === id }

    // ---- Notifications ------------------------------------------------------

    // Ordered: the host shows the first few, the rest wait.
    property var toasts: []
    property int toastSeq: 0

    function toastRank(note) {
        const base = { "error": 3, "warning": 2, "info": 1, "success": 0 }[note.severity] || 0;
        return base + (note.action ? 0.5 : 0);
    }

    // note: { key, severity, title, body, iconName, actionText, action, sticky }
    // `key` identifies the event (and console); the same key updates in place.
    function notify(note) {
        const entry = Object.assign({}, note);
        if (!entry.key)
            entry.key = entry.title;
        if (entry.sticky === undefined)
            entry.sticky = (entry.severity === "error" || entry.severity === "warning") && entry.action ? true : false;
        const list = toasts.slice();
        const at = list.findIndex(t => t.key === entry.key);
        if (at >= 0) {
            entry.seq = list[at].seq;
            list[at] = entry;
        } else {
            entry.seq = ++toastSeq;
            list.push(entry);
        }
        list.sort((a, b) => toastRank(b) - toastRank(a) || a.seq - b.seq);
        // Bounded: the lowest-ranked, newest notices are dropped first
        toasts = list.slice(0, Theme.toastsVisible + Theme.toastsQueued);
    }

    function dismissToast(key) {
        if (toasts.some(t => t.key === key))
            toasts = toasts.filter(t => t.key !== key);
    }

    // ---- Dialog coordinator -------------------------------------------------

    // Only one modal owns focus. `dialog` is the one on screen.
    property var dialog: null
    property var dialogQueue: []

    function dialogRank(request) {
        if (request.priority !== undefined)
            return request.priority;
        return request.severity === "error" ? 2 : 1;
    }

    // request: { key, severity, iconName, title, body, note, console: { name, type },
    //            primary: { text, run, keepOpen }, secondary: { text, run, danger, keepOpen },
    //            cancel: "primary" | "secondary" | function, cancelText, defaultFocus,
    //            closable, priority }
    // A more urgent request replaces the current one, which is answered as cancelled.
    function ask(request) {
        if (!request.key)
            request.key = request.title;
        if (!dialog) {
            dialog = request;
        } else if (dialog.key === request.key) {
            dialog = request;
        } else if (dialogRank(request) > dialogRank(dialog)) {
            const replaced = dialog;
            dialog = request;
            runAnswer(replaced, "cancel");
        } else if (!dialogQueue.some(d => d.key === request.key)) {
            dialogQueue = dialogQueue.concat([request]);
        }
        return request.key;
    }

    function answerFor(request, which) {
        if (which !== "cancel")
            return request[which];
        if (typeof request.cancel === "function")
            return { run: request.cancel };
        return request[request.cancel || (request.secondary ? "secondary" : "primary")];
    }

    function runAnswer(request, which) {
        const answer = answerFor(request, which);
        if (answer && answer.run)
            answer.run();
    }

    // Called by the dialog host with "primary", "secondary" or "cancel"
    function resolveDialog(which) {
        const request = dialog;
        if (!request)
            return;
        const answer = answerFor(request, which);
        if (!answer || !answer.keepOpen)
            closeDialog(request.key);
        if (answer && answer.run)
            answer.run();
    }

    function updateDialog(key, patch) {
        if (dialog && dialog.key === key)
            dialog = Object.assign({}, dialog, patch);
    }

    function closeDialog(key) {
        if (dialog && dialog.key === key) {
            const next = dialogQueue.length ? dialogQueue[0] : null;
            dialogQueue = dialogQueue.slice(1);
            dialog = next;
        } else {
            dialogQueue = dialogQueue.filter(d => d.key !== key);
        }
    }
}
