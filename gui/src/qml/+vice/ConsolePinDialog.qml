// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../ConsolePinDialog.qml: the console's 4-digit login PIN.
import QtQuick

import org.streetpea.chiaking

import vice
import vice.components as V

V.Page {
    id: page

    property var consoleIndex

    tab: "consoles"
    showStatus: false
    initialFocus: pin
    artwork.fadeLeft: 0.7
    onBack: stack.pop()

    function save() {
        if (!pin.complete)
            return;
        Chiaki.setConsolePin(consoleIndex, pin.text);
        Vice.notify({ key: "console-pin", severity: "success", title: qsTr("Login PIN saved"), body: qsTr("It is sent when this console asks for it.") });
        stack.pop();
    }

    Column {
        x: Theme.margin
        y: Theme.px(4)
        width: Math.min(parent.width * 0.5, Theme.px(600))
        spacing: Theme.px(8)

        V.Label {
            width: parent.width
            text: qsTr("Console login PIN")
            font.pixelSize: Theme.textDisplay
            font.weight: Theme.weightDisplay
            wrapMode: Text.Wrap
        }
        V.Label {
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.textHeading
            text: qsTr("The 4-digit PIN your console asks for when you log in to it. This is not the pairing code.")
        }

        Item { width: 1; height: Theme.px(18) }

        V.PinEntry {
            id: pin
            digits: 4
            masked: true
            onSubmitted: page.save()
        }

        Item { width: 1; height: Theme.px(22) }

        Row {
            spacing: Theme.unit * 3
            V.Button {
                width: Theme.px(280)
                size: "lg"
                font.pixelSize: Theme.px(28)
                implicitHeight: Theme.px(60)
                text: qsTr("Save PIN")
                enabled: pin.complete
                onTriggered: page.save()
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
