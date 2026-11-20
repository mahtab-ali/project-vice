// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking
import vice.backend

import ".."
import "../components" as V

// The in-stream menu. Everything here acts on the live session through the
// same calls upstream's stream menu makes; closing it never disconnects.
FocusScope {
    id: menu

    signal closeRequested()
    signal displaySettingsRequested()
    signal placeboSettingsRequested()
    signal disconnectRequested()

    property Item initialFocusItem: resumeButton
    // D-pad focus stays inside the menu while it is open (see Theme.focusRoot)
    readonly property bool focusTrap: true
    readonly property var session: Chiaki.session
    readonly property var target: Vice.target
    readonly property string mode: Vice.modeOf(Chiaki.window.videoPreset)
    // The stream setting this session was started with
    readonly property string streamId: (target && target.remote ? "Remote" : "Local") + (target && target.type === "PS4" ? "PS4" : "PS5")
    readonly property var defaultBitrate: [2, 6, 10, 15]
    readonly property int savedBitrate: Chiaki.settings["bitrate" + streamId] ? Math.round(Chiaki.settings["bitrate" + streamId] / 1000)
                                      : defaultBitrate[Chiaki.settings["resolution" + streamId] - 1] || 10
    // A bitrate the user picked but that is not applied: it needs a reconnect
    property int pendingBitrate: savedBitrate
    readonly property bool hasPending: pendingBitrate !== savedBitrate

    function setPreset(preset) {
        Chiaki.window.videoPreset = preset;
        Chiaki.settings.videoPreset = preset;
    }

    function resume() {
        if (!hasPending) {
            closeRequested();
            return;
        }
        const wanted = pendingBitrate;
        const prop = "bitrate" + streamId;
        Vice.ask({
            key: "reconnect",
            severity: "info",
            title: qsTr("Apply stream changes?"),
            body: qsTr("%1 Mbps needs a quick reconnect. The stream stops for a moment while it restarts.").arg(wanted),
            primary: {
                text: qsTr("Reconnect"),
                run: () => {
                    Chiaki.settings[prop] = wanted * 1000;
                    if (menu.target) {
                        Vice.reconnect = { op: Vice.beginOp("reconnect"), key: menu.target.key };
                        Chiaki.stopSession(false);
                    } else {
                        Vice.notify({ key: "bitrate-next", severity: "info", title: qsTr("Bitrate saved"), body: qsTr("It applies the next time you connect.") });
                        menu.closeRequested();
                    }
                }
            },
            // The proposed value stays on the slider; the running stream is untouched
            secondary: { text: qsTr("Cancel"), run: () => menu.closeRequested() },
            cancel: "secondary",
            defaultFocus: "secondary"
        });
    }

    Keys.onEscapePressed: resume()
    Keys.onMenuPressed: resume()

    Rectangle {
        anchors { fill: parent; margins: Theme.unit * 1.5 }
        radius: Theme.radiusDialog
        color: Theme.alpha(Theme.surfaceSolid, 0.95)
        border.width: Theme.border
        border.color: Theme.line
    }

    // One setting, one line: icon and label on the left, the control on the right. Every
    // control sits in the same column (controlWidth), so the rows line up down the panel.
    readonly property int controlWidth: Theme.px(196)
    readonly property int controlHeight: Theme.px(28)
    readonly property int smallText: Theme.px(13)

    component MenuRow: Item {
        id: mrow
        property alias iconName: rowIcon.name
        property alias label: rowLabel.text
        default property alias control: rowSlot.data
        width: column.width
        height: visible ? Theme.px(42) : 0
        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.08) }
        V.Icon { id: rowIcon; anchors.verticalCenter: parent.verticalCenter; size: Theme.px(18); weight: 1.8; color: Theme.textMuted }
        V.Label {
            id: rowLabel
            x: Theme.px(30)
            anchors.verticalCenter: parent.verticalCenter
            width: parent.width - x - rowSlot.width - Theme.px(10)
            elide: Text.ElideRight
            font.pixelSize: Theme.px(14)
            font.weight: Theme.weightStrong
        }
        Row {
            id: rowSlot
            anchors { right: parent.right; verticalCenter: parent.verticalCenter }
            height: menu.controlHeight
            spacing: Theme.px(8)
        }
    }

    // Keeps the control the D-pad lands on in view when the menu is taller than the window
    Connections {
        target: menu.Window.window
        function onActiveFocusItemChanged() {
            const item = menu.Window.window ? menu.Window.window.activeFocusItem : null;
            if (!item || !menu.visible)
                return;
            let inside = false;
            for (let up = item; up; up = up.parent)
                if (up === column) { inside = true; break; }
            if (!inside)
                return;
            const top = item.mapToItem(column, 0, 0).y - Theme.px(48);
            const bottom = item.mapToItem(column, 0, item.height).y + Theme.px(16);
            if (top < flick.contentY)
                flick.contentY = Math.max(0, top);
            else if (bottom > flick.contentY + flick.height)
                flick.contentY = Math.min(Math.max(0, flick.contentHeight - flick.height), bottom - flick.height);
        }
    }

    Flickable {
        id: flick
        anchors { top: parent.top; left: parent.left; right: parent.right; bottom: actions.top; margins: Theme.unit * 1.5; leftMargin: Theme.px(30); rightMargin: Theme.px(30); topMargin: Theme.px(22); bottomMargin: 0 }
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds
        Behavior on contentY { NumberAnimation { duration: Theme.dur(Theme.fast) } }

        Column {
            id: column
            width: flick.width

            V.Label { text: qsTr("Quick menu"); font.pixelSize: Theme.px(21); font.weight: Theme.weightDisplay }
            Row {
                spacing: Theme.unit * 1.5
                topPadding: Theme.px(3)
                bottomPadding: Theme.px(12)
                width: parent.width
                V.StatusDot { anchors.verticalCenter: parent.verticalCenter; state: menu.session && menu.session.connected ? "on" : "rest" }
                V.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: parent.width - Theme.px(24)
                    elide: Text.ElideRight
                    font.pixelSize: menu.smallText
                    color: menu.hasPending ? Theme.pink : Theme.textMuted
                    text: menu.hasPending ? qsTr("Reconnect to apply %1 Mbps").arg(menu.pendingBitrate)
                        : (menu.target ? menu.target.name : Chiaki.settings.streamerMode || !menu.session ? qsTr("Console") : menu.session.host)
                          + "  ·  " + (menu.session && menu.session.connected ? qsTr("Connected") : qsTr("Connecting"))
                }
            }

            MenuRow {
                iconName: "gamepad"
                label: qsTr("Mode")
                V.Segmented {
                    width: menu.controlWidth
                    implicitHeight: menu.controlHeight
                    textSize: menu.smallText
                    model: [qsTr("Game"), qsTr("Quality")]
                    currentIndex: menu.mode === "game" ? 0 : menu.mode === "quality" ? 1 : -1
                    onActivated: (index) => menu.setPreset(Vice.presetFor(index === 0 ? "game" : "quality"))
                    Accessible.name: qsTr("Mode")
                }
            }
            MenuRow {
                iconName: "monitor"
                label: qsTr("Upscaler")
                V.Button {
                    kind: "text"
                    size: "sm"
                    implicitHeight: menu.controlHeight
                    font.pixelSize: menu.smallText
                    text: (Engine.rtxSuperResolution ? qsTr("RTX Video") : qsTr("Built-in")) + "  ›"
                    // RTX Video is not part of this build; the built-in scalers have their own page
                    onTriggered: Chiaki.window.videoPreset === 5 ? menu.placeboSettingsRequested() : menu.displaySettingsRequested()
                    Accessible.name: qsTr("Upscaler and picture settings")
                }
            }
            MenuRow {
                iconName: "signal"
                label: qsTr("Bitrate")
                V.Slider {
                    width: menu.controlWidth - Theme.px(62) - Theme.px(8)
                    implicitHeight: menu.controlHeight
                    from: 2; to: 100; stepSize: 1
                    value: menu.pendingBitrate
                    onMoved: menu.pendingBitrate = Math.round(value)
                    Accessible.name: qsTr("Bitrate")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(62); horizontalAlignment: Text.AlignRight; font.pixelSize: menu.smallText; font.weight: Theme.weightStrong; text: qsTr("%1 Mbps").arg(menu.pendingBitrate) }
            }
            MenuRow {
                iconName: "volume"
                label: qsTr("Volume")
                V.Slider {
                    width: menu.controlWidth - Theme.px(62) - Theme.px(8)
                    implicitHeight: menu.controlHeight
                    from: 0; to: 128; stepSize: 1
                    value: Chiaki.settings.audioVolume
                    onMoved: Chiaki.settings.audioVolume = value
                    Accessible.name: qsTr("Volume")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(62); horizontalAlignment: Text.AlignRight; font.pixelSize: menu.smallText; font.weight: Theme.weightStrong; text: Math.round(Chiaki.settings.audioVolume / 128 * 100) + "%" }
            }
            MenuRow {
                iconName: "mic"
                label: qsTr("Microphone")
                V.Toggle {
                    implicitHeight: menu.controlHeight
                    enabled: menu.session && menu.session.connected ? true : false
                    checked: menu.session && !menu.session.muted ? true : false
                    onToggled: menu.session.muted = !menu.session.muted
                    Accessible.name: qsTr("Microphone")
                }
            }
            MenuRow {
                iconName: "sliders"
                label: qsTr("Picture")
                V.Segmented {
                    // ChiakiWindow.VideoMode: Normal, Stretch, Zoom
                    readonly property var modes: [0, 2, 1]
                    width: menu.controlWidth
                    implicitHeight: menu.controlHeight
                    textSize: menu.smallText
                    model: [qsTr("Fit"), qsTr("Zoom"), qsTr("Stretch")]
                    currentIndex: modes.indexOf(Chiaki.window.videoMode)
                    onActivated: (index) => Chiaki.window.videoMode = modes[index]
                    Accessible.name: qsTr("Picture size")
                }
            }
            MenuRow {
                iconName: "pulse"
                label: qsTr("Stats overlay")
                V.Toggle {
                    implicitHeight: menu.controlHeight
                    checked: Chiaki.settings.showStreamStats
                    onToggled: Chiaki.settings.showStreamStats = checked
                    Accessible.name: qsTr("Latency overlay")
                }
            }
            MenuRow {
                iconName: "pulse"
                label: qsTr("Overlay size")
                visible: Chiaki.settings.showStreamStats
                V.Segmented {
                    readonly property var sizes: ["full", "compact", "mini"]
                    width: menu.controlWidth
                    implicitHeight: menu.controlHeight
                    textSize: menu.smallText
                    model: [qsTr("Full"), qsTr("Small"), qsTr("Mini")]
                    currentIndex: Math.max(0, sizes.indexOf(Vice.readoutSize))
                    onActivated: (index) => Vice.readoutSize = sizes[index]
                    Accessible.name: qsTr("Overlay size")
                }
            }
            Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.09) }
            // The stream's own size and the window it is scaled to are different things
            V.Label {
                width: parent.width
                topPadding: Theme.px(10)
                horizontalAlignment: Text.AlignHCenter
                elide: Text.ElideRight
                font.pixelSize: Theme.px(12)
                color: Theme.textMuted
                text: {
                    const names = ["360p", "540p", "720p", "1080p"];
                    const stream = names[Chiaki.settings["resolution" + menu.streamId] - 1] || "\u2014";
                    return qsTr("%1 stream, shown at %2 \u00d7 %3").arg(stream).arg(Math.round(menu.width > 0 ? Screen.devicePixelRatio * menu.Window.width : 0)).arg(Math.round(Screen.devicePixelRatio * menu.Window.height));
                }
            }

            Item { width: 1; height: Theme.px(12) }
        }
    }

    // More settings below (or above) fade out instead of being cut off mid-row
    Rectangle {
        anchors { left: flick.left; right: flick.right; bottom: flick.bottom }
        height: Theme.px(40)
        visible: flick.contentY + flick.height < flick.contentHeight - 2
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(Theme.surfaceSolid, 0) }
            GradientStop { position: 1; color: Theme.surfaceSolid }
        }
        V.Icon { anchors { horizontalCenter: parent.horizontalCenter; bottom: parent.bottom; bottomMargin: Theme.px(2) } name: "chevronDown"; size: Theme.px(16); weight: 2.2; color: Theme.textMuted }
    }
    Rectangle {
        anchors { left: flick.left; right: flick.right; top: flick.top }
        height: Theme.px(28)
        visible: flick.contentY > 2
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.surfaceSolid }
            GradientStop { position: 1; color: Theme.alpha(Theme.surfaceSolid, 0) }
        }
    }

    // What you came to do stays put: only the settings above scroll
    Column {
        id: actions
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom; margins: Theme.unit * 1.5; leftMargin: Theme.px(30); rightMargin: Theme.px(30); bottomMargin: Theme.px(24) }

        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.14) }
        Item { width: 1; height: Theme.px(8) }


        V.Button {
            width: parent.width
            kind: "outline"
            implicitHeight: Theme.px(36); font.pixelSize: Theme.px(14)
            iconName: "replay"
            text: !Engine.replayEnabled ? qsTr("Turn on replay capture") : Engine.replaySaving ? qsTr("Saving…") : qsTr("Save last 30 seconds")
            enabled: !Engine.replayEnabled || Engine.replaySeconds >= 1
            busy: Engine.replaySaving
            onTriggered: Engine.replayEnabled ? Engine.saveReplay() : Engine.replayEnabled = true
        }
        V.Label {
            visible: !Engine.replayEnabled || Engine.replaySeconds < 1
            width: parent.width
            horizontalAlignment: Text.AlignHCenter
            topPadding: Theme.px(4)
            text: !Engine.replayEnabled ? qsTr("Off by default: it costs a full picture every 15 seconds") : qsTr("Getting the replay ready…")
            font.pixelSize: Theme.px(12)
            color: Theme.textMuted
        }

        Item { width: 1; height: Theme.px(8) }

        V.Button {
            id: resumeButton
            width: parent.width
            implicitHeight: Theme.px(42)
            font.pixelSize: Theme.px(17)
            text: qsTr("Resume game")
            focus: true
            onTriggered: menu.resume()
        }

        V.Button {
            anchors.horizontalCenter: parent.horizontalCenter
            kind: "text"
            size: "sm"
            text: qsTr("Disconnect")
            font.pixelSize: Theme.px(14)
            font.weight: Theme.weightButton
            // Asks first; nothing is ended by opening or closing this menu
            onTriggered: menu.disconnectRequested()
            ink: Theme.error
        }

        Rectangle { width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.09) }

        Row {
            anchors.horizontalCenter: parent.horizontalCenter
            spacing: Theme.unit * 5
            topPadding: Theme.px(10)
            Row {
                spacing: Theme.unit * 1.5
                V.Glyph { anchors.verticalCenter: parent.verticalCenter; button: "cross"; size: Theme.px(20) }
                V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Select"); font.pixelSize: menu.smallText; color: Theme.textMuted }
            }
            Row {
                spacing: Theme.unit * 1.5
                V.Glyph { anchors.verticalCenter: parent.verticalCenter; button: "moon"; size: Theme.px(20) }
                V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Resume"); font.pixelSize: menu.smallText; color: Theme.textMuted }
            }
        }
    }
}
