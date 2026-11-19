// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Effects

import org.streetpea.chiaking

import ".."
import "../components" as V

// Game or Quality before a session starts. A mode is one of upstream's
// renderer presets; a preset outside those two is kept as "your own".
V.Page {
    id: page

    // { index, key, host } from Vice.consoles()
    property var entry: null
    readonly property string savedMode: Vice.modeOf(Chiaki.settings.videoPreset)
    property string mode: savedMode === "custom" ? "custom" : savedMode
    property bool starting: false

    // The game the console says it is running, when it says so
    readonly property string titleId: entry && entry.host.titleId ? entry.host.titleId : ""
    readonly property string gameName: entry && entry.host.app ? entry.host.app : ""
    readonly property string profileName: Chiaki.settings.currentProfile || "default"
    readonly property bool gameLinked: titleId !== "" && Vice.gameProfiles[titleId] !== undefined && Vice.gameProfiles[titleId].profile === profileName

    function linkGame(on) {
        const next = Object.assign({}, Vice.gameProfiles);
        if (on)
            next[titleId] = { profile: profileName, name: gameName };
        else
            delete next[titleId];
        Vice.gameProfiles = next;
    }
    Component.onCompleted: {
        // A game with its own profile switches to it
        const linked = titleId ? Vice.gameProfiles[titleId] : undefined;
        if (linked && linked.profile !== profileName && Chiaki.settings.profiles.includes(linked.profile)) {
            Chiaki.settings.currentProfile = linked.profile === "default" ? "" : linked.profile;
            Vice.notify({ key: "game-profile", severity: "info", title: qsTr("Profile: %1").arg(linked.profile), body: qsTr("Chosen for %1.").arg(gameName || titleId) });
        }
    }

    tab: "consoles"
    initialFocus: startButton
    artwork.preset: "palms"
    onBack: stack.pop()

    function start() {
        if (starting || !entry)
            return;
        if (mode !== "custom") {
            const preset = Vice.presetFor(mode);
            Chiaki.settings.videoPreset = preset;
            Chiaki.window.videoPreset = preset;
        }
        starting = true;
        if (!root.startPlaying(entry.key)) {
            starting = false;
            Vice.notify({ key: "gone:" + entry.key, severity: "warning", title: qsTr("Console not found"), body: qsTr("%1 is not visible on this network right now.").arg(entry.host.name) });
        }
    }
    // A failed attempt brings its own dialog; this page just stops waiting
    Connections {
        target: Vice
        function onFailedChanged() { if (Vice.failed) page.starting = false }
    }

    // A mode card: the picture fills the whole card, edge to edge, and a
    // gradient darkens the lower half so the words read cleanly over it. The
    // card is masked to its rounded shape.
    component ModeCard: Item {
        id: card
        property string modeId
        property string title
        property string summary
        property var points: []
        property string iconName
        property alias art: cardArt
        readonly property bool selected: page.mode === modeId
        readonly property real radius: Theme.radiusPanel

        width: Theme.px(544)
        height: Theme.px(314)
        activeFocusOnTab: true
        Accessible.role: Accessible.RadioButton
        Accessible.name: title + ", " + summary
        Accessible.checked: selected

        Keys.onReturnPressed: page.mode = modeId
        Keys.onPressed: (event) => Theme.navKey(card, event, false)
        TapHandler { onTapped: { card.forceActiveFocus(); page.mode = card.modeId } }

        Item {
            id: picture
            anchors.fill: parent
            // The rounded mask is for looks alone, so a handheld goes without it
            layer.enabled: Theme.richEffects
            layer.effect: MultiEffect {
                maskEnabled: true
                maskSource: pictureMask
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1
            }

            Rectangle { anchors.fill: parent; radius: Theme.richEffects ? 0 : card.radius; color: Theme.surfaceSolid }

            V.Artwork {
                id: cardArt
                // Without the mask, the picture is inset a little so the card's corners stay round
                anchors.fill: parent
                anchors.margins: Theme.richEffects ? 0 : Theme.px(8)
                fadeLeft: 0
                opacity: card.selected ? 1 : 0.78
                Behavior on opacity { NumberAnimation { duration: Theme.dur(Theme.fast) } }
            }
            Rectangle {
                anchors.fill: parent
                gradient: Gradient {
                    GradientStop { position: 0; color: Theme.alpha(Theme.surfaceSolid, 0) }
                    GradientStop { position: 0.3; color: Theme.alpha(Theme.surfaceSolid, 0.05) }
                    GradientStop { position: 0.58; color: Theme.alpha(Theme.surfaceSolid, 0.88) }
                    GradientStop { position: 1; color: Theme.alpha(Theme.surfaceSolid, 0.98) }
                }
            }
        }
        Rectangle {
            id: pictureMask
            anchors.fill: picture
            radius: card.radius
            visible: false
            layer.enabled: true
        }

        // Selected: a pink edge and a tick. Nothing else changes, so the cards stay balanced.
        Rectangle {
            anchors.fill: parent
            radius: card.radius
            color: "transparent"
            border.width: card.selected ? Math.max(2, Theme.px(3)) : 0
            border.color: Theme.pink
        }
        V.FocusRing { active: card.activeFocus; radius: card.radius + Theme.focusWidth * 2 }

        V.StatusIcon {
            visible: card.selected
            anchors { top: parent.top; right: parent.right; margins: Theme.px(16) }
            severity: "success"
            color: Theme.pink
            size: Theme.px(32)
            Accessible.name: qsTr("Selected")
        }

        Column {
            anchors { left: parent.left; right: parent.right; top: parent.top; topMargin: Theme.px(176); leftMargin: Theme.px(28); rightMargin: Theme.px(28) }
            spacing: Theme.px(2)

            Row {
                spacing: Theme.unit * 2
                V.Label { text: card.title; font.pixelSize: Theme.px(40); font.weight: Theme.weightDisplay; color: card.selected ? Theme.pink : Theme.text }
                V.Icon { anchors.verticalCenter: parent.verticalCenter; name: card.iconName; size: Theme.px(30); weight: 1.8; color: Theme.textMuted }
            }
            V.Label { text: card.summary; font.pixelSize: Theme.textHeading; font.weight: Theme.weightStrong }
            Item { width: 1; height: Theme.px(6) }
            V.Label {
                width: parent.width
                text: card.points.join("   ·   ")
                font.pixelSize: Theme.px(15)
                color: Theme.textMuted
                wrapMode: Text.Wrap
            }
        }
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: -Theme.px(4)
        text: qsTr("How do you want to play?")
        font.pixelSize: Theme.px(48)
        font.weight: Theme.weightDisplay
    }
    V.Label {
        id: sub
        anchors { left: headline.left; top: headline.bottom }
        text: page.savedMode === "custom" && page.mode === "custom"
            ? qsTr("You are using your own picture settings. Pick a mode to replace them, or start as you are.")
            : qsTr("Choose a mode. You can change it during a session.")
    }

    Row {
        id: cards
        anchors { top: sub.bottom; topMargin: Theme.px(26); horizontalCenter: parent.horizontalCenter }
        spacing: Theme.px(22)

        ModeCard {
            modeId: "game"
            title: qsTr("Game")
            summary: qsTr("Fast response")
            iconName: "gamepad"
            points: [qsTr("Fastest processing"), qsTr("Least added delay"), qsTr("Adapts bitrate itself")]
            art { imageX: 0.53; imageY: 0.13; atX: 0.5; atY: 0.26; zoom: 1.75 }
        }
        ModeCard {
            modeId: "quality"
            title: qsTr("Quality")
            summary: qsTr("Sharper picture")
            iconName: "image"
            points: [qsTr("Sharper scaling"), qsTr("Cleaner gradients"), qsTr("Asks before adapting")]
            art { imageX: 0.17; imageY: 0.3; atX: 0.42; atY: 0.28; zoom: 2.5 }
        }
    }

    Row {
        id: summaryRow
        anchors { top: cards.bottom; topMargin: Theme.px(18); left: cards.left }
        spacing: Theme.unit * 2.5

        V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Game profile"); font.pixelSize: Theme.textHeading; font.weight: Theme.weightButton }
        V.Dropdown {
            id: profileBox
            width: Theme.px(260)
            // Upstream lists a "create new profile" entry; new profiles are made on the profiles page
            model: Chiaki.settings.profiles.filter(p => p !== "create new profile")
            currentIndex: Math.max(0, model.indexOf(Chiaki.settings.currentProfile || "default"))
            onActivated: (index) => Chiaki.settings.currentProfile = model[index] === "default" ? "" : model[index]
            Accessible.name: qsTr("Game profile")
        }
        V.Toggle {
            anchors.verticalCenter: parent.verticalCenter
            visible: page.titleId !== ""
            text: qsTr("Always for %1").arg(page.gameName || qsTr("this game"))
            checked: page.gameLinked
            onToggled: page.linkGame(checked)
        }
        Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(32); color: Theme.alpha(Theme.text, 0.5) }
        V.StatusDot { anchors.verticalCenter: parent.verticalCenter; state: page.entry ? Vice.stateOf(page.entry.host) : "off" }
        V.Label {
            anchors.verticalCenter: parent.verticalCenter
            text: page.entry ? [page.entry.host.name, Vice.typeOf(page.entry.host), root.streamSummary.replace("  ·  ", " / ")].filter(t => t).join("  ·  ") : ""
        }
    }

    V.Button {
        x: Theme.margin
        anchors { bottom: parent.bottom; bottomMargin: Theme.px(14) }
        kind: "outline"
        width: Theme.px(186)
        text: qsTr("Back")
        onTriggered: page.back()
    }

    V.Button {
        id: startButton
        anchors { right: parent.right; rightMargin: Theme.margin; bottom: parent.bottom; bottomMargin: Theme.px(12) }
        width: Theme.px(348)
        size: "lg"
        font.pixelSize: Theme.px(30)
        text: page.starting ? qsTr("Connecting…") : qsTr("Start playing")
        busy: page.starting
        onTriggered: page.start()
    }
}
