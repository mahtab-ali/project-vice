// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking

import ".."
import "../components" as V

// How to reach a console away from home, with each step one press from the
// setting it needs. The ports are the ones upstream documents in
// docs/setup/remoteconnection.md; keep the two in step.
V.Page {
    id: page

    tab: "settings"
    showStatus: false
    initialFocus: signedIn ? addButton : signInButton
    artwork { imageX: 1; imageY: 0.36; atX: 1; atY: 0.44; zoom: 1.6; fadeStart: 0.62; fadeLeft: 0.9 }
    onBack: stack.pop()

    readonly property bool signedIn: Chiaki.settings.psnAuthToken ? true : false
    property bool ps5: true
    readonly property var ports: ps5 ? [["9295", qsTr("TCP and UDP")], ["9296", "UDP"], ["9297", "UDP"], ["9302", "UDP"]]
                                     : [["987", "UDP"], ["9295", qsTr("TCP and UDP")], ["9296", "UDP"], ["9297", "UDP"]]

    component Step: Row {
        property int number
        property alias text: stepText.text
        property real textWidth: Theme.px(440)
        spacing: Theme.unit * 1.5
        Rectangle {
            width: Theme.px(28); height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(2, Theme.px(2)); border.color: Theme.pink
            V.Label { anchors.centerIn: parent; text: parent.parent.number; font.weight: Theme.weightStrong; font.pixelSize: Theme.textSmall }
        }
        V.Label { id: stepText; width: parent.textWidth; wrapMode: Text.Wrap; topPadding: Theme.px(2) }
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: -Theme.px(4)
        text: qsTr("Play from anywhere")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }
    V.Label {
        id: sub
        anchors { left: headline.left; top: headline.bottom; topMargin: -Theme.px(4) }
        text: qsTr("Two ways to reach your console away from home. Try the first; use the second if it does not connect.")
        font.pixelSize: Theme.textHeading
        width: parent.width - Theme.margin * 2
        wrapMode: Text.Wrap
    }

    Row {
        anchors { left: parent.left; leftMargin: Theme.px(40); top: sub.bottom; topMargin: Theme.px(18); bottom: parent.bottom; bottomMargin: Theme.px(16) }
        spacing: Theme.px(18)

        // ---- Through PSN --------------------------------------------------------
        V.Panel {
            width: Theme.px(470)
            height: parent.height

            Column {
                anchors { fill: parent; margins: Theme.px(26) }
                spacing: Theme.px(12)

                Row {
                    spacing: Theme.unit * 1.5
                    V.Label { text: qsTr("Through PSN"); font.pixelSize: Theme.px(30); font.weight: Theme.weightDisplay }
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        width: easy.implicitWidth + Theme.unit * 2.5; height: Theme.px(24); radius: height / 2
                        color: Theme.pink
                        V.Label { id: easy; anchors.centerIn: parent; text: qsTr("Easiest"); color: Theme.pinkInk; font.pixelSize: Theme.textSmall; font.weight: Theme.weightStrong }
                    }
                }
                V.Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    text: qsTr("No router changes. PlayStation Network introduces this computer and your console, then they connect directly. Works on most networks.")
                }
                Row {
                    spacing: Theme.unit * 1.5
                    V.StatusIcon { anchors.verticalCenter: parent.verticalCenter; severity: page.signedIn ? "success" : "info"; size: Theme.px(26) }
                    V.Label {
                        anchors.verticalCenter: parent.verticalCenter
                        font.weight: Theme.weightStrong
                        text: page.signedIn ? qsTr("Signed in to PSN") : qsTr("Not signed in yet")
                    }
                }
                V.Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.textMuted
                    font.pixelSize: Theme.textLabel
                    text: page.signedIn ? qsTr("Consoles on your account show on the home screen as \"Away, through PSN\" when you are not on their network.")
                                        : qsTr("Sign in once. Your consoles then show on the home screen wherever you are.")
                }
                V.Button {
                    id: signInButton
                    width: parent.width
                    text: page.signedIn ? qsTr("Sign in again") : qsTr("Sign in to PSN")
                    kind: page.signedIn ? "outline" : "primary"
                    onTriggered: root.showPSNTokenDialog(false)
                }
                V.Button {
                    width: parent.width
                    kind: "outline"
                    implicitHeight: Theme.px(44)
                    text: qsTr("Refresh my consoles")
                    visible: page.signedIn
                    onTriggered: { Chiaki.refreshPsnToken(); Vice.notify({ key: "psn-refresh", severity: "info", title: qsTr("Refreshing consoles"), body: qsTr("Asking PlayStation Network for the consoles on your account.") }) }
                }
            }
        }

        // ---- Port forwarding ------------------------------------------------------
        V.Panel {
            width: Theme.px(560)
            height: parent.height

            Column {
                anchors { fill: parent; margins: Theme.px(26) }
                spacing: Theme.px(10)

                V.Label { text: qsTr("Port forwarding"); font.pixelSize: Theme.px(30); font.weight: Theme.weightDisplay }

                Step { number: 1; text: qsTr("In your router, give the console a fixed address, so the rules below keep pointing at it.") }
                Step { number: 2; text: qsTr("Forward these ports to that address:") }

                Row {
                    x: Theme.px(40)
                    spacing: Theme.unit * 3
                    V.Segmented {
                        width: Theme.px(150)
                        implicitHeight: Theme.px(34)
                        model: ["PS5", "PS4"]
                        currentIndex: page.ps5 ? 0 : 1
                        onActivated: (index) => page.ps5 = index === 0
                        Accessible.name: qsTr("Console type")
                    }
                    Column {
                        Repeater {
                            model: page.ports
                            Row {
                                required property var modelData
                                spacing: Theme.unit * 2
                                V.Label { width: Theme.px(56); text: modelData[0]; font.weight: Theme.weightButton }
                                V.Label { text: modelData[1]; color: Theme.textMuted }
                            }
                        }
                    }
                }

                Step { number: 3; text: qsTr("Away from home, add the console by your home's public address.") }

                V.Button {
                    id: addButton
                    x: Theme.px(40)
                    width: Theme.px(300)
                    implicitHeight: Theme.px(44)
                    text: qsTr("Add console by address")
                    onTriggered: root.showManualHostDialog()
                }

                V.Label {
                    width: parent.width
                    wrapMode: Text.Wrap
                    color: Theme.textMuted
                    font.pixelSize: Theme.textSmall
                    text: qsTr("IPv4 only. If your provider puts you behind a shared address (CGNAT), forwarding cannot work: use PSN instead.")
                }
            }
        }
    }

    footerExtra: V.Button {
        kind: "outline"
        implicitHeight: Theme.px(44)
        text: qsTr("Stream quality away from home")
        onTriggered: root.showTab("settings", { category: "video", stream: "RemotePS5" })
    }
}
