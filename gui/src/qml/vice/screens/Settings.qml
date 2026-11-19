// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Window

import org.streetpea.chiaking

import ".."
import "../components" as V

// The settings people change most, grouped. Edits are a draft until Save;
// the backend's own values are untouched until then. Everything else is one
// step away under Advanced, in upstream's full settings.
V.Page {
    id: page

    // video | network | input | audio | advanced
    property string category: "video"
    // Which stream the Video page edits: LocalPS5, RemotePS5, LocalPS4, RemotePS4
    property string stream: "LocalPS5"
    // Draft values by row key; a key is present only once it has been edited
    property var draft: ({})
    property int revision: 0
    readonly property bool dirty: revision >= 0 && Object.keys(draft).length > 0
    readonly property bool openGl: Chiaki.settings.rendererBackend === 1

    tab: "settings"
    showStatus: true
    initialFocus: navRepeater.count ? navRepeater.itemAt(Math.max(0, categories.findIndex(c => c.id === category))) : null
    artwork.preset: "palms"
    onBack: confirmLeave(() => root.showTab("consoles")) && root.showTab("consoles")

    readonly property var categories: [
        { id: "video", icon: "monitor", text: qsTr("Video"), title: qsTr("Picture & playback") },
        { id: "network", icon: "wifi", text: qsTr("Network"), title: qsTr("Network & account") },
        { id: "input", icon: "gamepad", text: qsTr("Input"), title: qsTr("Controllers & keys") },
        { id: "audio", icon: "volume", text: qsTr("Audio"), title: qsTr("Sound & microphone") },
        { id: "advanced", icon: "sliders", text: qsTr("Advanced"), title: qsTr("Advanced") },
        { id: "shortcuts", icon: "search", text: qsTr("Shortcuts"), title: qsTr("Keyboard & controller shortcuts") }
    ]
    readonly property var current: categories.find(c => c.id === category) || categories[0]

    // ---- Rows -----------------------------------------------------------------
    // type: choice | segmented | range | toggle | info | action
    // prop: a Chiaki.settings property. get/set convert between that and the control.
    // def: upstream's default, used by Reset defaults; rows without one are left alone.

    readonly property var defaultBitrate: [2, 6, 10, 15]
    function rows(id) {
        const s = Chiaki.settings;
        const ps5 = stream.endsWith("PS5");
        const local = stream.startsWith("Local");
        switch (id) {
        case "video": return [
            { group: qsTr("Stream") },
            { key: "resolution" + stream, prop: "resolution" + stream, label: qsTr("Resolution"), type: "choice",
              options: ["360p", "540p", "720p", ps5 ? "1080p" : qsTr("1080p (PS4 Pro)")],
              get: (v) => v - 1, set: (v) => v + 1, def: ps5 && local ? 4 : 3 },
            { key: "fps" + stream, prop: "fps" + stream, label: qsTr("Frame rate"), type: "choice",
              options: [qsTr("30 fps"), qsTr("60 fps")], get: (v) => v / 30 - 1, set: (v) => (v + 1) * 30, def: 60 },
            { key: "bitrate" + stream, prop: "bitrate" + stream, label: qsTr("Bitrate"), type: "range", from: 2, to: 100, unit: qsTr(" Mbps"),
              // 0 means "the default for this resolution"
              get: (v) => v ? v / 1000 : defaultBitrate[value("resolution" + stream) - 1] || 10, set: (v) => v * 1000, def: 0 },
            { key: "codec" + stream, prop: "codec" + stream, label: qsTr("Video codec"), type: "choice", visible: ps5,
              options: openGl ? ["H264", "H265"] : ["H264", "H265", qsTr("H265 with HDR")], get: (v) => v, set: (v) => v, def: 1 },
            { group: qsTr("Upscaling") },
            { key: "upscaler", label: qsTr("Upscaler"), type: "choice", local: true, options: [qsTr("Built-in"), qsTr("RTX Video")], disabled: [1],
              hint: qsTr("RTX Video needs an NVIDIA RTX GPU and plugin"), chip: qsTr("RTX Video not available"), get: () => 0, set: () => { } },
            { key: "videoPreset", prop: "videoPreset", label: qsTr("Picture preset"), type: "segmented",
              options: [qsTr("Crisp"), qsTr("Natural"), qsTr("Performance")],
              hint: () => [0, 1, 2].includes(value("videoPreset")) ? "" : qsTr("A custom preset is in use"),
              get: (v) => [2, 1, 0].indexOf(v), set: (v) => [2, 1, 0][v] },
            { key: "display", label: qsTr("Display output"), type: "info",
              text: Math.round(Screen.width * Screen.devicePixelRatio) + " × " + Math.round(Screen.height * Screen.devicePixelRatio) },
            { key: "hdr", label: qsTr("HDR conversion"), type: "toggle", local: true, unavailable: true,
              side: qsTr("Not available in this build"), get: () => false, set: () => { } }
        ];
        case "network": return [
            { group: qsTr("Connection") },
            { key: "wifiDroppedNotif", prop: "wifiDroppedNotif", label: qsTr("Warn about packet loss above"), type: "range", from: 0, to: 100, unit: "%", get: (v) => v, set: (v) => v, def: 3 },
            { key: "packetLossReportedMax", prop: "packetLossReportedMax", label: qsTr("Most packet loss reported"), type: "range", from: 0, to: 100, unit: "%",
              hint: qsTr("What the console is told, at most"), get: (v) => v, set: (v) => v },
            { key: "iDROnFECFailureEnabled", prop: "iDROnFECFailureEnabled", label: qsTr("Ask for a fresh frame after errors"), type: "toggle", get: (v) => v, set: (v) => v },
            { key: "portGuessingEnabled", prop: "portGuessingEnabled", label: qsTr("Guess ports when away from home"), type: "toggle", get: (v) => v, set: (v) => v, def: false },
            { group: qsTr("Away from home") },
            { key: "remote", label: qsTr("Play from anywhere"), type: "action", text: qsTr("Set up"), hint: qsTr("PSN sign-in or port forwarding, step by step"), run: () => root.showRemotePlay() },
            { key: "psn", label: qsTr("PSN account"), type: "action", text: s.psnAuthToken ? qsTr("Signed in") : qsTr("Sign in"), run: () => root.showAccount() }
        ];
        case "shortcuts": {
            const combo = s.streamMenuEnabled && typeof s.stringForStreamMenuShortcut === "function" ? s.stringForStreamMenuShortcut() : "";
            const touch = s.dpadTouchEnabled && typeof s.stringForDpadShortcut === "function" ? s.stringForDpadShortcut() : "";
            return [
                { group: qsTr("Anywhere") },
                { key: "k-full", label: qsTr("Full screen, no window frame"), type: "keys", keys: ["F11"] },
                { key: "k-quit", label: qsTr("Quit"), type: "keys", keys: ["Ctrl+Q"], visible: Qt.platform.os !== "osx" },
                { group: qsTr("In menus") },
                { key: "k-move", label: qsTr("Move"), type: "keys", keys: [qsTr("Arrow keys"), qsTr("D-pad")] },
                { key: "k-select", label: qsTr("Select and go back"), type: "keys", keys: ["Enter", "Esc"] },
                { key: "k-tabs", label: qsTr("Consoles, Sessions, Settings"), type: "keys", keys: ["Page Up", "Page Down", "L1", "R1"] },
                { key: "k-add", label: qsTr("Add a console"), type: "keys", keys: ["F2", "R3"] },
                { key: "k-steam", label: qsTr("Add to Steam"), type: "keys", keys: ["F1", "L3"], visible: typeof Chiaki.createSteamShortcut === "function" },
                { group: qsTr("During play") },
                { key: "k-menu", label: qsTr("Quick menu"), type: "keys", keys: combo ? ["Ctrl+O", combo] : ["Ctrl+O"] },
                { key: "k-mic", label: qsTr("Microphone on or off"), type: "keys", keys: ["Ctrl+M"] },
                { key: "k-zoom", label: qsTr("Zoom the picture"), type: "keys", keys: ["Ctrl+Z"] },
                { key: "k-stretch", label: qsTr("Stretch the picture"), type: "keys", keys: ["Ctrl+S"] },
                { key: "k-touch", label: qsTr("D-pad as touchpad"), type: "keys", keys: [touch], visible: touch !== "" }
            ];
        }
        case "input": return [
            { group: qsTr("Controls") },
            { key: "controllerStyle", label: qsTr("Button labels"), type: "segmented", local: true,
              options: [qsTr("Automatic"), qsTr("PlayStation"), qsTr("Xbox")], hint: qsTr("The symbols shown in hints"),
              get: () => ["auto", "ps", "xbox"].indexOf(Vice.controllerStyle), set: (v) => Vice.controllerStyle = ["auto", "ps", "xbox"][v] },
            { key: "deckLayout", label: qsTr("Steam Deck layout"), type: "segmented", local: true, visible: root.steamLayoutAvailable,
              options: [qsTr("PlayStation"), qsTr("Gamepad")], hint: qsTr("Applies after Steam restarts"),
              get: () => ["playstation", "gamepad"].indexOf(Vice.deckLayout), set: (v) => root.applyDeckLayout(["playstation", "gamepad"][v]) },
            { key: "buttonsByPosition", prop: "buttonsByPosition", label: qsTr("Match buttons by position"), type: "toggle", hint: qsTr("For controllers with a different face-button layout"), get: (v) => v, set: (v) => v },
            { key: "keyboardEnabled", prop: "keyboardEnabled", label: qsTr("Keyboard controls"), type: "toggle", get: (v) => v, set: (v) => v, def: true },
            { key: "mouseTouchEnabled", prop: "mouseTouchEnabled", label: qsTr("Mouse as touchpad"), type: "toggle", get: (v) => v, set: (v) => v, def: true },
            { key: "dpadTouchEnabled", prop: "dpadTouchEnabled", label: qsTr("D-pad as touchpad"), type: "toggle", get: (v) => v, set: (v) => v, def: true },
            { key: "rumbleHapticsIntensity", prop: "rumbleHapticsIntensity", label: qsTr("Rumble strength"), type: "choice",
              options: [qsTr("Off"), qsTr("Very weak"), qsTr("Weak"), qsTr("Normal"), qsTr("Strong"), qsTr("Very strong")], get: (v) => v, set: (v) => v },
            { key: "streamMenuEnabled", prop: "streamMenuEnabled", label: qsTr("Quick menu from the controller"), type: "toggle", get: (v) => v, set: (v) => v, def: true },
            { group: qsTr("More") },
            { key: "mapping", label: qsTr("Button mapping"), type: "action", text: qsTr("Open"), run: () => root.showControllerMappingDialog() },
            { key: "profiles", label: qsTr("Game profiles"), type: "action", text: qsTr("Open"), run: () => root.showProfiles() }
        ];
        case "audio": return [
            { group: qsTr("Output") },
            { key: "audioVolume", prop: "audioVolume", label: qsTr("Volume"), type: "range", from: 0, to: 128, percent: true, get: (v) => v, set: (v) => v, def: 128 },
            { key: "audioOutDevice", prop: "audioOutDevice", label: qsTr("Speakers"), type: "choice",
              options: [qsTr("Automatic")].concat(s.availableAudioOutDevices), get: (v) => Math.max(0, s.availableAudioOutDevices.indexOf(v) + 1),
              set: (v) => v ? s.availableAudioOutDevices[v - 1] : "", def: "" },
            { key: "audioBufferSize", prop: "audioBufferSize", label: qsTr("Audio buffer"), type: "range", from: 1, to: 10,
              hint: qsTr("Smaller is quicker, larger is steadier"), get: (v) => v / 1920 ? v / 1920 : 5, set: (v) => v * 1920 },
            { group: qsTr("Microphone") },
            { key: "audioInDevice", prop: "audioInDevice", label: qsTr("Microphone"), type: "choice",
              options: [qsTr("Automatic")].concat(s.availableAudioInDevices), get: (v) => Math.max(0, s.availableAudioInDevices.indexOf(v) + 1),
              set: (v) => v ? s.availableAudioInDevices[v - 1] : "", def: "" },
            { key: "startMicUnmuted", prop: "startMicUnmuted", label: qsTr("Start with the microphone on"), type: "toggle", get: (v) => v, set: (v) => v },
            { key: "speechProcessing", prop: "speechProcessing", label: qsTr("Clean up voice"), type: "toggle", hint: qsTr("Noise and echo reduction"), get: (v) => v, set: (v) => v, def: false }
        ];
        default: return [
            { group: qsTr("Display") },
            { key: "fullScreen", label: qsTr("Full screen, no window frame"), type: "toggle", local: true, hint: qsTr("F11 does the same at any time"),
              get: () => root.fullScreen, set: () => root.toggleFullScreen() },
            { key: "blendTitleBar", label: qsTr("Blend the title bar into the app"), type: "toggle", local: true, visible: root.chromeSupported,
              hint: qsTr("Off brings back the system title bar"),
              get: () => Vice.blendTitleBar, set: (v) => Vice.blendTitleBar = v },
            { key: "windowType", prop: "windowType", label: qsTr("Window during play"), type: "choice",
              options: [qsTr("Stream resolution"), qsTr("Custom resolution"), qsTr("Resizable"), qsTr("Full screen"), qsTr("Zoom"), qsTr("Stretch")], get: (v) => v, set: (v) => v },
            { key: "vSyncEnabled", prop: "vSyncEnabled", label: qsTr("V-sync"), type: "toggle", get: (v) => v, set: (v) => v },
            { key: "rendererBackend", prop: "rendererBackend", label: qsTr("Renderer"), type: "choice", options: ["Vulkan", "OpenGL"],
              hint: qsTr("Takes effect after a restart"), get: (v) => v, set: (v) => v },
            { key: "hideCursor", prop: "hideCursor", label: qsTr("Hide the pointer during play"), type: "toggle", get: (v) => v, set: (v) => v },
            { group: qsTr("This app") },
            { key: "showStreamStats", prop: "showStreamStats", label: qsTr("Latency overlay"), type: "toggle", get: (v) => v, set: (v) => v },
            { key: "streamerMode", prop: "streamerMode", label: qsTr("Hide addresses and IDs"), type: "toggle", get: (v) => v, set: (v) => v },
            { key: "reduceMotion", label: qsTr("Reduce motion"), type: "toggle", local: true, get: () => Vice.reduceMotion, set: (v) => Vice.reduceMotion = v },
            { key: "steam", label: qsTr("Add to Steam"), type: "action", text: qsTr("Open"), visible: typeof Chiaki.createSteamShortcut === "function",
              hint: qsTr("A Steam entry with artwork and a controller layout"), run: () => root.showSteamShortcutDialog(false) },
            { key: "all", label: qsTr("All settings"), type: "action", text: qsTr("Open"), hint: qsTr("Every option, including consoles, keys and export"), run: () => root.showUpstreamSettings() }
        ];
        }
    }

    // ---- Draft ----------------------------------------------------------------

    // The value to show for a backend property: the draft if edited, else the saved one
    function value(prop) {
        return revision >= 0 && draft[prop] !== undefined ? draft[prop] : Chiaki.settings[prop];
    }
    function edit(row, controlValue) {
        if (row.local) {
            row.set(controlValue);
            revision++;
            return;
        }
        const next = row.set(controlValue);
        if (next === Chiaki.settings[row.prop])
            delete draft[row.prop];
        else
            draft[row.prop] = next;
        // As upstream does: a new resolution goes back to that resolution's default bitrate
        if (row.prop.startsWith("resolution"))
            draft[row.prop.replace("resolution", "bitrate")] = 0;
        revision++;
    }
    function save() {
        const edited = Object.keys(draft);
        for (const prop of edited)
            Chiaki.settings[prop] = draft[prop];
        // Confirm what the backend now reports, not the click
        const refused = edited.filter(prop => Chiaki.settings[prop] != draft[prop]);
        draft = {};
        revision++;
        if (refused.length)
            Vice.notify({ key: "settings-failed", severity: "error", title: qsTr("Some settings were not saved"), body: qsTr("%n setting(s) kept their old value.", "", refused.length), sticky: true });
        else
            Vice.notify({ key: "settings-saved", severity: "success", title: qsTr("Settings saved"), body: qsTr("Your %1 preferences have been updated.").arg(current.text.toLowerCase()) });
    }
    function resetDefaults() {
        for (const row of rows(category)) {
            if (row.prop && row.def !== undefined) {
                if (row.def === Chiaki.settings[row.prop])
                    delete draft[row.prop];
                else
                    draft[row.prop] = row.def;
            }
        }
        revision++;
    }
    // Used by Main before leaving this page. Returns true when it is fine to go now.
    function confirmLeave(proceed) {
        if (!dirty)
            return true;
        Vice.ask({
            key: "unsaved",
            severity: "question",
            title: qsTr("Save your changes?"),
            body: qsTr("You have changed settings that are not saved yet."),
            primary: { text: qsTr("Save changes"), run: () => { save(); proceed(); } },
            secondary: { text: qsTr("Discard"), danger: true, run: () => { draft = {}; revision++; proceed(); } },
            cancelText: qsTr("Keep editing"),
            cancel: () => { }
        });
        return false;
    }

    // ---- Layout ---------------------------------------------------------------

    V.Label {
        id: heading
        x: Theme.margin
        y: Theme.px(8)
        text: qsTr("Settings")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }

    Column {
        id: nav
        x: Theme.px(36)
        anchors { top: heading.bottom; topMargin: Theme.px(14) }
        width: Theme.px(240)
        spacing: Theme.px(6)

        Repeater {
            id: navRepeater
            model: page.categories
            Rectangle {
                id: navItem
                required property var modelData
                readonly property bool current: modelData.id === page.category
                width: nav.width
                height: Theme.px(44)
                radius: height / 2
                color: current ? Theme.pink : "transparent"
                activeFocusOnTab: true
                Accessible.role: Accessible.PageTab
                Accessible.name: modelData.text
                Accessible.selected: current

                function pick() { page.category = modelData.id; forceActiveFocus() }
                Keys.onReturnPressed: pick()
                Keys.onRightPressed: { pick(); const first = Theme.firstFocusable(list); if (first) first.forceActiveFocus(Qt.TabFocusReason) }
                Keys.onPressed: (event) => Theme.navKey(navItem, event, true)
                TapHandler { onTapped: navItem.pick() }

                V.FocusRing { active: navItem.activeFocus; border.color: navItem.current ? Theme.text : Theme.pink }
                V.Icon { x: Theme.px(26); anchors.verticalCenter: parent.verticalCenter; name: navItem.modelData.icon; size: Theme.px(30); weight: 2; color: navItem.current ? Theme.pinkInk : Theme.text }
                V.Label { x: Theme.px(74); anchors.verticalCenter: parent.verticalCenter; text: navItem.modelData.text; font.pixelSize: Theme.textHeading; font.weight: Theme.weightButton; color: navItem.current ? Theme.pinkInk : Theme.text }
            }
        }
    }

    Rectangle { x: Theme.px(294); y: Theme.px(12); width: Theme.border; height: parent.height - Theme.px(36); color: Theme.alpha(Theme.text, 0.2) }

    V.Label {
        id: title
        x: Theme.px(328)
        y: Theme.px(8)
        text: page.current.title
        font.pixelSize: Theme.px(38)
        font.weight: Theme.weightDisplay
    }

    V.Dropdown {
        // Stream settings are kept per console type and per network
        visible: page.category === "video"
        anchors { right: parent.right; rightMargin: Theme.margin - Theme.unit; verticalCenter: title.verticalCenter }
        width: Theme.px(270)
        implicitHeight: Theme.px(36)
        font.pixelSize: Theme.textLabel
        readonly property var ids: ["LocalPS5", "RemotePS5", "LocalPS4", "RemotePS4"]
        model: [qsTr("PS5 at home"), qsTr("PS5 away from home"), qsTr("PS4 at home"), qsTr("PS4 away from home")]
        currentIndex: ids.indexOf(page.stream)
        onActivated: (index) => page.stream = ids[index]
        Accessible.name: qsTr("Stream settings for")
    }

    ListView {
        id: list
        anchors { left: title.left; right: parent.right; rightMargin: Theme.margin - Theme.unit; top: title.bottom; topMargin: Theme.px(4); bottom: actions.top; bottomMargin: Theme.px(10) }
        clip: true
        spacing: Theme.px(3)
        boundsBehavior: Flickable.StopAtBounds
        // Rebuilt only when the page or the stream being edited changes, never on an edit
        model: page.rows(page.category).filter(r => r.visible !== false)

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool isGroup: modelData.group !== undefined
            readonly property real controlX: Theme.px(352)
            width: list.width
            height: isGroup ? Theme.px(30) : Theme.px(42)

            V.Label {
                visible: row.isGroup
                anchors.bottom: parent.bottom
                anchors.bottomMargin: Theme.px(2)
                text: row.modelData.group || ""
                font.pixelSize: Theme.textHeading
                font.weight: Theme.weightButton
            }

            Item {
                visible: !row.isGroup
                anchors.fill: parent
                opacity: row.modelData.unavailable ? 0.75 : 1

                Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }

                Column {
                    x: Theme.px(2)
                    anchors.verticalCenter: parent.verticalCenter
                    width: row.controlX - x - Theme.unit
                    V.Label { width: parent.width; text: row.modelData.label || ""; font.weight: Theme.weightStrong; elide: Text.ElideRight }
                    V.Label {
                        width: parent.width
                        visible: text
                        text: typeof row.modelData.hint === "function" ? (page.revision >= 0 ? row.modelData.hint() : "") : row.modelData.hint || ""
                        font.pixelSize: Theme.px(12)
                        color: Theme.textMuted
                        elide: Text.ElideRight
                    }
                }

                Loader {
                    id: control
                    x: row.controlX
                    anchors.verticalCenter: parent.verticalCenter
                    sourceComponent: row.isGroup ? null
                        : row.modelData.type === "choice" ? choiceRow
                        : row.modelData.type === "segmented" ? segmentedRow
                        : row.modelData.type === "range" ? rangeRow
                        : row.modelData.type === "toggle" ? toggleRow
                        : row.modelData.type === "action" ? actionRow
                        : row.modelData.type === "keys" ? keysRow : infoRow
                    property var spec: row.modelData
                    property real shown: page.revision >= 0 && row.modelData.get ? row.modelData.get(row.modelData.prop ? page.value(row.modelData.prop) : undefined) : 0
                    onActiveFocusChanged: if (activeFocus) list.positionViewAtIndex(row.index, ListView.Contain)
                }

                Rectangle {
                    visible: row.modelData.chip ? true : false
                    anchors { left: control.right; leftMargin: Theme.unit * 2; verticalCenter: parent.verticalCenter }
                    width: chipLabel.implicitWidth + Theme.unit * 3
                    height: Theme.px(28)
                    radius: height / 2
                    color: Theme.alpha(Theme.info, 0.28)
                    V.Label { id: chipLabel; anchors.centerIn: parent; text: row.modelData.chip || ""; font.pixelSize: Theme.textSmall; font.weight: Theme.weightStrong }
                }
            }
        }
    }

    Component {
        id: choiceRow
        V.Dropdown {
            width: Theme.px(330)
            implicitHeight: Theme.px(36)
            model: spec.options
            disabledIndexes: spec.disabled || []
            currentIndex: shown
            onActivated: (index) => page.edit(spec, index)
            Accessible.name: spec.label
        }
    }
    Component {
        id: segmentedRow
        V.Segmented {
            width: Theme.px(520)
            implicitHeight: Theme.px(36)
            model: spec.options
            currentIndex: shown
            onActivated: (index) => page.edit(spec, index)
            Accessible.name: spec.label
        }
    }
    Component {
        id: rangeRow
        Row {
            spacing: Theme.unit * 3
            V.Slider {
                id: slider
                width: Theme.px(420)
                implicitHeight: Theme.px(36)
                from: spec.from
                to: spec.to
                stepSize: 1
                value: shown
                onMoved: page.edit(spec, value)
                Accessible.name: spec.label
            }
            V.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: spec.percent ? Math.round(slider.value / spec.to * 100) + "%" : Math.round(slider.value) + (spec.unit || "")
            }
        }
    }
    Component {
        id: toggleRow
        Row {
            spacing: Theme.unit * 2
            V.Toggle {
                implicitHeight: Theme.px(36)
                enabled: !spec.unavailable
                checked: shown ? true : false
                onToggled: page.edit(spec, checked)
                Accessible.name: spec.label
            }
            V.Label { anchors.verticalCenter: parent.verticalCenter; visible: text; text: spec.side || ""; color: Theme.textMuted }
        }
    }
    Component {
        id: actionRow
        V.Button {
            kind: "outline"
            size: "sm"
            implicitHeight: Theme.px(34)
            text: spec.text
            onTriggered: page.confirmLeave(spec.run) && spec.run()
        }
    }
    Component {
        id: keysRow
        Row {
            spacing: Theme.unit
            Repeater {
                model: spec.keys
                Rectangle {
                    required property string modelData
                    width: keyLabel.implicitWidth + Theme.unit * 3
                    height: Theme.px(30)
                    radius: Theme.px(8)
                    color: Theme.alpha(Theme.text, 0.1)
                    V.Label { id: keyLabel; anchors.centerIn: parent; text: parent.modelData; font.pixelSize: Theme.textLabel; font.weight: Theme.weightStrong }
                }
            }
        }
    }
    Component {
        id: infoRow
        V.Label { text: spec.text || ""; font.weight: Theme.weightStrong }
    }

    Row {
        id: actions
        anchors { horizontalCenter: list.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(12) }
        spacing: Theme.unit * 3

        V.Button {
            width: Theme.px(326)
            visible: page.category !== "shortcuts"
            text: qsTr("Save changes")
            font.pixelSize: Theme.px(26)
            enabled: page.dirty
            onTriggered: page.save()
        }
        V.Button {
            anchors.verticalCenter: parent.verticalCenter
            kind: "outline"
            width: Theme.px(266)
            implicitHeight: Theme.px(46)
            visible: page.category !== "shortcuts"
            text: qsTr("Reset defaults")
            onTriggered: page.resetDefaults()
        }
    }
}
