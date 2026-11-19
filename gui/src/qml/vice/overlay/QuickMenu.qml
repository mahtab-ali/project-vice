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

    component MenuRow: Item {
        property alias iconName: rowIcon.name
        property alias label: rowLabel.text
        property string caption
        default property alias control: rowSlot.data
        width: column.width
        height: Theme.px(caption ? 50 : 39)
        Rectangle { width: parent.width; height: Theme.border; color: Theme.alpha(Theme.text, 0.14) }
        V.Icon { id: rowIcon; y: Theme.px(7); size: Theme.px(24); weight: 1.8 }
        V.Label { id: rowLabel; x: Theme.px(40); y: Theme.px(7); font.pixelSize: Theme.px(20); font.weight: Theme.weightButton }
        V.Label { x: Theme.px(40); y: Theme.px(31); visible: parent.caption; text: parent.caption; font.pixelSize: Theme.px(12); color: Theme.textMuted }
        Row { id: rowSlot; anchors { right: parent.right; top: parent.top; topMargin: Theme.px(2) } height: Theme.px(34); spacing: Theme.unit * 1.5 }
    }

    Flickable {
        id: flick
        anchors { fill: parent; margins: Theme.unit * 1.5; leftMargin: Theme.px(38); rightMargin: Theme.px(38); topMargin: Theme.px(24); bottomMargin: Theme.px(16) }
        contentHeight: column.implicitHeight
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: column
            width: flick.width

            V.Label { text: qsTr("Quick menu"); font.pixelSize: Theme.px(36); font.weight: Theme.weightDisplay }
            Row {
                spacing: Theme.unit * 1.5
                bottomPadding: Theme.px(8)
                V.StatusDot { anchors.verticalCenter: parent.verticalCenter; state: menu.session && menu.session.connected ? "on" : "rest" }
                V.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.textHeading
                    text: (menu.target ? menu.target.name : Chiaki.settings.streamerMode || !menu.session ? qsTr("Console") : menu.session.host)
                          + "  ·  " + (menu.session && menu.session.connected ? qsTr("Connected") : qsTr("Connecting"))
                }
            }

            MenuRow {
                iconName: "gamepad"
                label: qsTr("Mode")
                caption: menu.mode === "custom" ? qsTr("A custom picture preset is in use") : ""
                V.Segmented {
                    width: Theme.px(210)
                    implicitHeight: Theme.px(36)
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
                    implicitHeight: Theme.px(36)
                    text: qsTr("Built-in") + "   ›"
                    // RTX Video is not part of this build; the built-in scalers have their own page
                    onTriggered: Chiaki.window.videoPreset === 5 ? menu.placeboSettingsRequested() : menu.displaySettingsRequested()
                    Accessible.name: qsTr("Upscaler and picture settings")
                }
            }
            MenuRow {
                iconName: "signal"
                label: qsTr("Bitrate")
                caption: menu.hasPending ? qsTr("Reconnect to apply. The stream is still at %1 Mbps.").arg(menu.savedBitrate) : qsTr("A change needs a reconnect")
                V.Slider {
                    width: Theme.px(150)
                    implicitHeight: Theme.px(36)
                    from: 2; to: 100; stepSize: 1
                    value: menu.pendingBitrate
                    onMoved: menu.pendingBitrate = Math.round(value)
                    Accessible.name: qsTr("Bitrate")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(76); horizontalAlignment: Text.AlignRight; text: qsTr("%1 Mbps").arg(menu.pendingBitrate) }
            }
            MenuRow {
                iconName: "volume"
                label: qsTr("Volume")
                V.Slider {
                    width: Theme.px(150)
                    implicitHeight: Theme.px(36)
                    from: 0; to: 128; stepSize: 1
                    value: Chiaki.settings.audioVolume
                    onMoved: Chiaki.settings.audioVolume = value
                    Accessible.name: qsTr("Volume")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(76); horizontalAlignment: Text.AlignRight; text: Math.round(Chiaki.settings.audioVolume / 128 * 100) + "%" }
            }
            MenuRow {
                iconName: "mic"
                label: qsTr("Microphone")
                V.Toggle {
                    implicitHeight: Theme.px(36)
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
                    width: Theme.px(236)
                    implicitHeight: Theme.px(36)
                    model: [qsTr("Fit"), qsTr("Zoom"), qsTr("Stretch")]
                    currentIndex: modes.indexOf(Chiaki.window.videoMode)
                    onActivated: (index) => Chiaki.window.videoMode = modes[index]
                    Accessible.name: qsTr("Picture size")
                }
            }
            MenuRow {
                iconName: "pulse"
                label: qsTr("Latency overlay")
                V.Toggle {
                    implicitHeight: Theme.px(36)
                    checked: Chiaki.settings.showStreamStats
                    onToggled: Chiaki.settings.showStreamStats = checked
                    Accessible.name: qsTr("Latency overlay")
                }
            }
            MenuRow {
                iconName: "image"
                label: qsTr("Clean view")
                caption: qsTr("Nothing over the picture: no readout, hints or notices")
                V.Toggle {
                    implicitHeight: Theme.px(34)
                    checked: Vice.cleanView
                    onToggled: Vice.cleanView = checked
                    Accessible.name: qsTr("Clean view")
                }
            }
            MenuRow {
                iconName: "monitor"
                // The stream's own size and the window it is scaled to are different things
                label: ""
                V.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    width: column.width - Theme.px(40)
                    font.pixelSize: Theme.textSmall
                    elide: Text.ElideRight
                    text: {
                        const names = ["360p", "540p", "720p", "1080p"];
                        const stream = names[Chiaki.settings["resolution" + menu.streamId] - 1] || "—";
                        return qsTr("%1 stream, shown at %2 × %3").arg(stream).arg(Math.round(menu.width > 0 ? Screen.devicePixelRatio * menu.Window.width : 0)).arg(Math.round(Screen.devicePixelRatio * menu.Window.height));
                    }
                }
            }

            Item { width: 1; height: Theme.px(8) }

            V.Button {
                width: parent.width
                kind: "outline"
                implicitHeight: Theme.px(44)
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

            Item { width: 1; height: Theme.px(6) }

            V.Button {
                id: resumeButton
                width: parent.width
                implicitHeight: Theme.px(52)
                font.pixelSize: Theme.px(26)
                text: qsTr("Resume game")
                focus: true
                onTriggered: menu.resume()
            }

            V.Button {
                anchors.horizontalCenter: parent.horizontalCenter
                kind: "text"
                size: "sm"
                text: qsTr("Disconnect")
                font.pixelSize: Theme.px(22)
                font.weight: Theme.weightButton
                // Asks first; nothing is ended by opening or closing this menu
                onTriggered: menu.disconnectRequested()
                ink: Theme.error
            }

            Rectangle { width: parent.width; height: Theme.border; color: Theme.alpha(Theme.text, 0.14) }

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.unit * 5
                topPadding: Theme.px(8)
                Row {
                    spacing: Theme.unit * 1.5
                    V.Glyph { anchors.verticalCenter: parent.verticalCenter; button: "cross"; size: Theme.px(24) }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Select"); font.pixelSize: Theme.textLabel }
                }
                Row {
                    spacing: Theme.unit * 1.5
                    V.Glyph { anchors.verticalCenter: parent.verticalCenter; button: "moon"; size: Theme.px(24) }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Resume"); font.pixelSize: Theme.textLabel }
                }
            }
        }
    }
}
