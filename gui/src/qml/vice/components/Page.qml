// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Controls

import org.streetpea.chiaking

import ".."

// The frame every ordinary screen shares: navy page, key-art crop, wordmark,
// Consoles / Sessions / Settings, account button and the contextual footer.
// `root` is Main.qml, which owns navigation.
FocusScope {
    id: page

    // consoles | sessions | settings
    property string tab: "consoles"
    property alias artwork: art
    // 0 = the artwork fills the page; otherwise a strip of this height along the top
    property real artworkHeight: 0
    // Footer, left: controller, last measured ping, configured stream. Off on pages that say it themselves.
    property bool showStatus: true
    // Footer, right: [{ button, text }]
    property var hints: [{ button: "cross", text: qsTr("Select") }, { button: "moon", text: qsTr("Back") }]
    property Item initialFocus: null
    default property alias content: body.data
    property alias footerExtra: footerSlot.data
    signal back()

    readonly property bool active: StackView.status === StackView.Active
    readonly property var tabs: [
        { id: "consoles", text: qsTr("Consoles") },
        { id: "sessions", text: qsTr("Sessions") },
        { id: "settings", text: qsTr("Settings") }
    ]

    function focusFirst() {
        if (initialFocus && initialFocus.visible && initialFocus.enabled) {
            initialFocus.forceActiveFocus(Qt.TabFocusReason);
            return;
        }
        forceActiveFocus(Qt.TabFocusReason);
        const first = Theme.firstFocusable(body);
        if (first)
            first.forceActiveFocus(Qt.TabFocusReason);
    }

    StackView.onActivated: focusFirst()

    Keys.onEscapePressed: back()
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return;
        const at = tabs.findIndex(t => t.id === tab);
        if (event.key === Qt.Key_PageUp || event.key === Qt.Key_PageDown) {
            const next = at + (event.key === Qt.Key_PageDown ? 1 : -1);
            if (next >= 0 && next < tabs.length)
                root.showTab(tabs[next].id);
            event.accepted = true;
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#17153A" }
            GradientStop { position: 0.55; color: Theme.bg }
            GradientStop { position: 1; color: Theme.bgDeep }
        }
    }

    Artwork {
        id: art
        width: parent.width
        height: page.artworkHeight > 0 ? page.artworkHeight : parent.height
    }

    Item {
        id: header
        anchors { top: parent.top; left: parent.left; right: parent.right }
        height: Theme.headerHeight

        Wordmark {
            x: Theme.margin
            y: Theme.px(22)
        }

        Row {
            x: Theme.px(280)
            y: Theme.px(21)
            spacing: Theme.unit

            Repeater {
                model: page.tabs
                Rectangle {
                    id: navTab
                    required property var modelData
                    readonly property bool current: modelData.id === page.tab
                    width: navLabel.implicitWidth + Theme.unit * 5
                    height: Theme.px(36)
                    radius: height / 2
                    color: current ? Theme.pink : navTap.pressed ? Theme.alpha(Theme.text, 0.12) : "transparent"
                    Accessible.role: Accessible.PageTab
                    Accessible.name: modelData.text
                    Accessible.selected: current

                    Label {
                        id: navLabel
                        anchors.centerIn: parent
                        text: navTab.modelData.text
                        font.weight: Theme.weightStrong
                        color: navTab.current ? Theme.pinkInk : Theme.text
                    }
                    TapHandler { id: navTap; onTapped: root.showTab(navTab.modelData.id) }
                }
            }
        }

        Rectangle {
            anchors { right: parent.right; rightMargin: Theme.margin - Theme.unit; top: parent.top; topMargin: Theme.px(18) }
            width: Theme.px(40)
            height: width
            radius: width / 2
            color: accountTap.pressed ? Theme.alpha(Theme.text, 0.2) : Theme.alpha(Theme.bgDeep, 0.6)
            border.width: Math.max(2, Theme.px(2))
            border.color: Theme.text
            Accessible.role: Accessible.Button
            Accessible.name: Chiaki.settings.psnAccountId ? qsTr("PSN account, signed in") : qsTr("Sign in to PSN")

            Icon { anchors.centerIn: parent; name: "user"; size: Theme.px(24); weight: 2.2 }
            Rectangle {
                visible: Chiaki.settings.psnAccountId ? true : false
                anchors { right: parent.right; bottom: parent.bottom }
                width: Theme.px(12); height: width; radius: width / 2
                color: Theme.online
                border.width: Theme.px(2); border.color: Theme.bg
            }
            TapHandler { id: accountTap; onTapped: root.showAccount() }
        }
    }

    Item {
        id: body
        anchors { top: header.bottom; left: parent.left; right: parent.right; bottom: footer.top }
    }

    Rectangle {
        id: footer
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: Theme.footerHeight
        color: Theme.alpha(Theme.bg, 0.9)

        Rectangle { width: parent.width; height: Theme.border; color: Theme.alpha(Theme.text, 0.08) }

        Row {
            anchors { left: parent.left; leftMargin: Theme.margin; verticalCenter: parent.verticalCenter }
            visible: page.showStatus
            spacing: Theme.unit * 3

            component StatusItem: Row {
                property alias iconName: statusIcon.name
                property alias text: statusLabel.text
                spacing: Theme.unit * 1.5
                Icon { id: statusIcon; anchors.verticalCenter: parent.verticalCenter; size: Theme.px(26); weight: 1.8 }
                Label { id: statusLabel; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.textLabel }
            }
            component Divider: Rectangle {
                anchors.verticalCenter: parent.verticalCenter
                width: Theme.border; height: Theme.px(26)
                color: Theme.alpha(Theme.text, 0.3)
            }

            StatusItem {
                iconName: "gamepad"
                text: !Chiaki.controllers.length ? qsTr("No controller")
                    : Chiaki.controllers.some(c => c.dualSense) ? qsTr("DualSense connected") : qsTr("Controller connected")
            }
            Divider { visible: pingItem.visible }
            StatusItem {
                id: pingItem
                // Only a real measurement is shown here
                visible: Vice.failed !== null || (Vice.lastCheck !== null && Vice.lastCheck.ping !== null)
                iconName: "wifi"
                text: Vice.failed ? qsTr("Disconnected") : Vice.lastCheck ? qsTr("%1 ms ping").arg(Vice.valueText(Vice.lastCheck.ping, "", Vice.lastCheck.ping < 10 ? 1 : 0)) : ""
            }
            Divider { }
            StatusItem {
                iconName: "monitor"
                text: root.streamSummary
            }
        }

        Row {
            id: footerSlot
            anchors { right: hintRow.left; rightMargin: Theme.unit * 4; verticalCenter: parent.verticalCenter }
            spacing: Theme.unit * 2
        }

        Row {
            id: hintRow
            anchors { right: parent.right; rightMargin: Theme.margin; verticalCenter: parent.verticalCenter }
            spacing: Theme.unit * 4

            Repeater {
                model: page.hints
                Row {
                    required property var modelData
                    spacing: Theme.unit * 1.5
                    Glyph { anchors.verticalCenter: parent.verticalCenter; button: modelData.button }
                    Label { anchors.verticalCenter: parent.verticalCenter; text: modelData.text; font.pixelSize: Theme.textLabel }
                }
            }
        }
    }
}
