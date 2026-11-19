// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../ManualHostDialog.qml: add a console by address.
import QtQuick

import org.streetpea.chiaking

import vice
import vice.components as V

V.Page {
    id: page

    tab: "consoles"
    showStatus: false
    initialFocus: manual ? hostField : null
    artwork.fadeLeft: 0.7
    onBack: root.closeDialog()

    // As upstream: an already-paired console, or "pair when first connecting"
    readonly property var choices: {
        const out = [];
        const hosts = Chiaki.settings.registeredHosts;
        for (let i = 0; i < hosts.length; ++i)
            out.push({ name: qsTr("%1, already paired").arg(hosts[i].name) + (Chiaki.settings.streamerMode ? "" : "  (" + hosts[i].mac + ")"), index: i });
        out.push({ name: qsTr("A new console: pair on first connection"), index: hosts.length });
        return out;
    }
    readonly property bool valid: hostField.text.trim().length > 0

    // Consoles discovery has found, with their addresses. Shown first: picking
    // one needs no typing. Typing an address is for a console on another network.
    property var found: []
    property string foundSignature
    property bool manual: false
    function refreshFound() {
        const list = Vice.found(Chiaki.hosts);
        const signature = list.map(f => f.address + f.name + f.registered + f.hidden).join("|");
        if (signature === foundSignature)
            return;
        foundSignature = signature;
        found = list;
    }
    Component.onCompleted: { refreshFound(); manual = found.length === 0 }
    Connections { target: Chiaki; function onHostsChanged() { page.refreshFound() } }

    function use(console_) {
        if (console_.hidden && console_.mac)
            Chiaki.unhideHost(console_.mac);
        Vice.selectedConsole = console_.key;
        root.closeDialog();
        if (!console_.registered) {
            // Straight on to pairing, with the address already known
            const entry = Vice.consoles(Chiaki.hosts).find(c => c.key === console_.key);
            if (entry)
                root.connectOrPair(entry);
        }
    }

    function add() {
        if (!valid)
            return;
        Chiaki.addManualHost(choices[consoleBox.currentIndex].index, hostField.text.trim());
        root.closeDialog();
    }

    Column {
        x: Theme.margin
        y: Theme.px(4)
        width: Math.min(parent.width * 0.5, Theme.px(600))
        spacing: Theme.px(8)

        V.Label {
            width: parent.width
            text: qsTr("Add a console")
            font.pixelSize: Theme.textDisplay
            font.weight: Theme.weightDisplay
            wrapMode: Text.Wrap
        }
        V.Label {
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.textHeading
            text: page.manual ? qsTr("For a console that does not show up on its own, for example on another network.")
                : qsTr("Found on this network. Pick one: its address is already known.")
        }

        // ---- Found automatically ---------------------------------------------------
        Column {
            visible: !page.manual
            width: parent.width
            spacing: Theme.px(6)
            topPadding: Theme.px(10)

            Repeater {
                model: page.found
                V.Panel {
                    id: row
                    required property var modelData
                    width: Theme.px(520)
                    height: Theme.px(68)
                    activeFocusOnTab: true
                    color: activeFocus && Theme.keyboardNav ? Theme.highlight : Theme.surfaceSoft
                    Accessible.role: Accessible.Button
                    Accessible.name: modelData.name

                    Keys.onReturnPressed: page.use(modelData)
                    Keys.onPressed: (event) => Theme.navKey(row, event, false)
                    TapHandler { onTapped: page.use(row.modelData) }
                    V.FocusRing { active: row.activeFocus }

                    V.Icon { x: Theme.px(22); anchors.verticalCenter: parent.verticalCenter; name: Vice.consoleIcon(row.modelData.ps5 ? "PS5" : "PS4"); size: Theme.px(38) }
                    Column {
                        x: Theme.px(74)
                        anchors.verticalCenter: parent.verticalCenter
                        V.Label { text: row.modelData.name; font.pixelSize: Theme.textHeading; font.weight: Theme.weightButton }
                        V.Label {
                            font.pixelSize: Theme.textLabel
                            color: Theme.textMuted
                            text: [row.modelData.ps5 ? "PS5" : "PS4", Chiaki.settings.streamerMode ? "" : row.modelData.address,
                                   row.modelData.hidden ? qsTr("Hidden") : row.modelData.registered ? qsTr("Paired") : qsTr("Not paired yet")].filter(t => t).join("  ·  ")
                        }
                    }
                    V.Label {
                        anchors { right: parent.right; rightMargin: Theme.px(22); verticalCenter: parent.verticalCenter }
                        text: row.modelData.hidden ? qsTr("Show") : row.modelData.registered ? qsTr("Select") : qsTr("Pair")
                        font.weight: Theme.weightStrong
                        color: Theme.pink
                    }
                }
            }

            Item { width: 1; height: Theme.px(10) }

            Row {
                spacing: Theme.unit * 2
                V.Button {
                    kind: "outline"
                    text: qsTr("Enter an address instead")
                    onTriggered: { page.manual = true; hostField.forceActiveFocus(Qt.TabFocusReason) }
                }
                V.Button {
                    kind: "outline"
                    width: Theme.px(150)
                    text: qsTr("Back")
                    onTriggered: page.back()
                }
            }
        }

        // ---- By address --------------------------------------------------------------
        Column {
            visible: page.manual
            width: parent.width
            spacing: Theme.px(8)

        Item { width: 1; height: Theme.px(14) }

        V.Label { text: qsTr("Console address"); font.weight: Theme.weightStrong }
        V.TextInput {
            id: hostField
            width: Theme.px(460)
            placeholderText: qsTr("IP address or host name")
            echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
            Keys.onReturnPressed: page.add()
            Accessible.name: qsTr("Console address")
        }

        Item { width: 1; height: Theme.px(8) }

        V.Label { text: qsTr("Which console is it?"); font.weight: Theme.weightStrong }
        V.Dropdown {
            id: consoleBox
            width: Theme.px(460)
            textRole: "name"
            model: page.choices
            currentIndex: page.choices.length - 1
            Accessible.name: qsTr("Which console is it?")
        }

        Item { width: 1; height: Theme.px(22) }

        Row {
            spacing: Theme.unit * 3
            V.Button {
                width: Theme.px(320)
                size: "lg"
                font.pixelSize: Theme.px(28)
                implicitHeight: Theme.px(60)
                text: qsTr("Add console")
                enabled: page.valid
                onTriggered: page.add()
            }
            V.Button {
                anchors.verticalCenter: parent.verticalCenter
                kind: "outline"
                width: Theme.px(150)
                text: page.found.length ? qsTr("Found consoles") : qsTr("Back")
                onTriggered: page.found.length ? page.manual = false : page.back()
            }
        }
        }
    }
}
