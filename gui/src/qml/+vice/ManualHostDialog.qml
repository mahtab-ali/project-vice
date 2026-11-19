// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../ManualHostDialog.qml: add a console by address.
import QtQuick

import org.streetpea.chiaking

import "vice"
import "vice/components" as V

V.Page {
    id: page

    tab: "consoles"
    showStatus: false
    initialFocus: hostField
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
            text: qsTr("For a console that does not show up on its own, for example on another network.")
        }

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
                text: qsTr("Back")
                onTriggered: page.back()
            }
        }
    }
}
