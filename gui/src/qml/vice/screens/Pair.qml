// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking

import ".."
import "../components" as V
import "../.." as Upstream

// Pairing: account, 8-digit code, done. Replaces upstream RegistDialog.qml
// and calls the same Chiaki.registerHost().
V.Page {
    id: pair

    property string host
    property bool ps5: true

    // idle | pairing | failed | done
    property string phase: "idle"
    property string failure
    property string accountId: Chiaki.settings.psnAccountId
    readonly property bool usesOnlineId: typeBox.target === 800
    readonly property bool hasAccount: usesOnlineId ? onlineIdField.text.trim().length > 0 : accountId.trim().length > 0
    readonly property bool valid: hostField.text.trim().length > 0 && pin.complete && hasAccount && loginPin.acceptableInput
    property int op: 0

    tab: "consoles"
    initialFocus: hasAccount ? pin : signInButton
    artwork.fadeLeft: 0.66
    onBack: {
        Vice.cancelOp("pair");   // a late answer from the console is ignored
        stack.pop();
    }

    function submit() {
        if (!valid || phase === "pairing")
            return;
        const address = hostField.text.trim();
        const id = Vice.beginOp("pair");
        op = id;
        failure = "";
        phase = "pairing";
        let lastLine = "";
        const accepted = Chiaki.registerHost(address, usesOnlineId ? onlineIdField.text.trim() : accountId.trim(), pin.text,
                                             loginPin.text.trim(), address === "255.255.255.255", typeBox.target,
                                             function(msg, ok, done) {
            if (!Vice.isCurrent("pair", id))
                return;
            if (!done) {
                lastLine = msg;
                return;
            }
            if (ok) {
                pair.phase = "done";
                pair.linked(address);
            } else {
                pair.phase = "failed";
                // The console does not say whether the code was wrong or too old
                pair.failure = qsTr("The console did not accept this code. Codes expire after a few minutes: get a new one on the console and enter it here.")
                             + (lastLine ? "\n" + lastLine : "");
                pin.clear();
                pin.invalid = true;
                pin.forceActiveFocus(Qt.TabFocusReason);
            }
        });
        if (!accepted) {
            phase = "failed";
            failure = qsTr("Those details could not be sent. Check the account ID and the code.");
        }
    }

    function linked(address) {
        const entry = Vice.consoles(Chiaki.hosts).find(c => c.host.address === address);
        const name = entry ? entry.host.name : address;
        stack.pop();
        Vice.ask({
            key: "linked:" + address,
            severity: "success",
            title: qsTr("Console linked"),
            body: qsTr("%1 is ready to play.").arg(name),
            console: { name: name, type: pair.ps5 ? "PS5" : "PS4" },
            primary: {
                text: qsTr("Connect"),
                run: () => {
                    const found = Vice.consoles(Chiaki.hosts).find(c => c.host.address === address);
                    if (found) {
                        Vice.selectedConsole = found.key;
                        root.connectOrPair(found);
                    }
                }
            },
            secondary: { text: qsTr("Back to consoles") },
            cancel: "secondary"
        });
    }

    Component { id: psnLoginComponent; Upstream.PSNLoginDialog { } }
    function signIn() { stack.push(psnLoginComponent, { login: true, callback: (id) => pair.accountId = id }) }
    function lookUp() { stack.push(psnLoginComponent, { login: false, callback: (id) => pair.accountId = id }) }

    Flickable {
        anchors { fill: parent; leftMargin: Theme.margin; rightMargin: Theme.margin }
        contentHeight: form.implicitHeight + Theme.unit * 2
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        Column {
            id: form
            width: Math.min(parent.width, Theme.px(640))
            spacing: Theme.px(10)

            V.Stepper {
                steps: [qsTr("Account"), qsTr("Link console"), qsTr("Ready")]
                current: pair.phase === "done" ? 2 : pair.hasAccount ? 1 : 0
            }

            V.Label {
                width: parent.width
                text: qsTr("Link your console")
                font.pixelSize: Theme.textDisplay
                font.weight: Theme.weightDisplay
                wrapMode: Text.Wrap
                lineHeight: 0.95
            }

            Row {
                visible: !pair.usesOnlineId && Chiaki.settings.psnAccountId
                spacing: Theme.unit * 1.5
                V.StatusIcon { anchors.verticalCenter: parent.verticalCenter; severity: "success"; size: Theme.px(28) }
                V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("PSN account connected"); font.pixelSize: Theme.textHeading }
            }

            // No account yet: sign in, look it up, or type the ID
            Row {
                visible: !pair.usesOnlineId && !Chiaki.settings.psnAccountId
                spacing: Theme.unit * 1.5

                V.TextInput {
                    id: accountField
                    width: Theme.px(250)
                    implicitHeight: Theme.controlHeight
                    font.pixelSize: Theme.textBody
                    placeholderText: qsTr("PSN account ID")
                    echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                    text: pair.accountId
                    onTextEdited: pair.accountId = text
                    Accessible.name: placeholderText
                }
                V.Button {
                    id: signInButton
                    size: "sm"
                    text: qsTr("Sign in to PSN")
                    onTriggered: pair.signIn()
                }
                V.Button {
                    size: "sm"
                    kind: "outline"
                    text: qsTr("Look up")
                    onTriggered: pair.lookUp()
                }
            }

            V.TextInput {
                id: onlineIdField
                visible: pair.usesOnlineId
                width: Theme.px(420)
                implicitHeight: Theme.controlHeight
                font.pixelSize: Theme.textBody
                placeholderText: qsTr("PSN online ID (username, case-sensitive)")
                echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                Accessible.name: placeholderText
            }

            V.Label { text: qsTr("Enter the 8-digit code shown on your console."); topPadding: Theme.px(4) }

            V.PinEntry {
                id: pin
                masked: Chiaki.settings.streamerMode
                enabled: pair.phase !== "pairing"
                onSubmitted: pair.submit()
            }

            V.Label {
                text: pair.ps5 ? qsTr("Settings  →  System  →  Remote Play  →  Link Device")
                               : qsTr("Settings  →  Remote Play Connection Settings  →  Add Device")
                font.pixelSize: Theme.textLabel
                color: Theme.textMuted
            }

            V.InlineAlert {
                width: parent.width
                visible: pair.phase === "failed"
                severity: "error"
                text: pair.failure
            }

            Row {
                spacing: Theme.unit * 2
                topPadding: Theme.px(4)

                component Field: Column {
                    property alias label: fieldLabel.text
                    default property alias control: slot.data
                    spacing: Theme.px(4)
                    V.Label { id: fieldLabel; font.pixelSize: Theme.textSmall; font.weight: Theme.weightStrong }
                    Row { id: slot }
                }

                Field {
                    label: qsTr("Console address")
                    V.TextInput {
                        id: hostField
                        width: Theme.px(230)
                        implicitHeight: Theme.controlHeight
                        font.pixelSize: Theme.textBody
                        text: pair.host
                        echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                        Accessible.name: qsTr("Console address")
                    }
                }
                Field {
                    label: qsTr("Console")
                    V.Dropdown {
                        id: typeBox
                        readonly property var targets: [1000100, 1000, 900, 800]
                        readonly property int target: targets[currentIndex]
                        width: Theme.px(220)
                        model: [qsTr("PS5"), qsTr("PS4, system 8.0 or later"), qsTr("PS4, system 7.0 to 7.5"), qsTr("PS4, before 7.0")]
                        currentIndex: pair.ps5 ? 0 : 1
                        font.pixelSize: Theme.textLabel
                        Accessible.name: qsTr("Console type")
                    }
                }
                Field {
                    label: qsTr("Login PIN, if set")
                    V.TextInput {
                        id: loginPin
                        width: Theme.px(150)
                        implicitHeight: Theme.controlHeight
                        font.pixelSize: Theme.textBody
                        echoMode: TextInput.Password
                        inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhSensitiveData
                        validator: RegularExpressionValidator { regularExpression: /^$|[0-9]{4}/ }
                        invalid: !acceptableInput
                        Accessible.name: qsTr("Console login PIN, optional")
                    }
                }
            }

            Row {
                spacing: Theme.unit * 3
                topPadding: Theme.px(8)

                V.Button {
                    width: Theme.px(440)
                    size: "lg"
                    text: pair.phase === "pairing" ? qsTr("Pairing…") : qsTr("Pair console")
                    enabled: pair.valid
                    busy: pair.phase === "pairing"
                    onTriggered: pair.submit()
                }
                V.Button {
                    anchors.verticalCenter: parent.verticalCenter
                    kind: "outline"
                    width: Theme.px(150)
                    text: pair.phase === "pairing" ? qsTr("Cancel") : qsTr("Back")
                    onTriggered: pair.back()
                }
            }

            V.Label {
                text: qsTr("Use your own PSN account and console.")
                font.pixelSize: Theme.textLabel
                color: Theme.textMuted
            }
        }
    }
}
