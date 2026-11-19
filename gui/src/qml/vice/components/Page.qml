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

    // Focus must always be on something the arrows can move from. A page whose first
    // control appears late (a console found after the page opened) takes it then.
    function refocusIfLost() {
        const at = Window.activeFocusItem;
        if (active && (!at || at === page || at === Window.contentItem))
            focusFirst();
    }
    onInitialFocusChanged: Qt.callLater(refocusIfLost)

    // The header: Up from the first control on the page lands on the current tab,
    // Left and Right move along it, Down goes back to the page (see Theme.navKey)
    function focusHeader() {
        const at = Math.max(0, tabs.findIndex(t => t.id === tab));
        const item = tabRepeater.itemAt(at);
        if (!item)
            return false;
        item.forceActiveFocus(Qt.TabFocusReason);
        return true;
    }
    function headerKey(index, event) {
        // index: a tab's position, or tabs.length for the account button
        const items = [];
        for (let i = 0; i < tabRepeater.count; ++i)
            items.push(tabRepeater.itemAt(i));
        items.push(account);
        switch (event.key) {
        case Qt.Key_Left: case Qt.Key_Backtab: items[Math.max(0, index - 1)].forceActiveFocus(Qt.TabFocusReason); break;
        case Qt.Key_Right: items[Math.min(items.length - 1, index + 1)].forceActiveFocus(Qt.TabFocusReason); break;
        case Qt.Key_Down: case Qt.Key_Tab: focusFirst(); break;
        case Qt.Key_Up: break;
        case Qt.Key_Return: case Qt.Key_Enter: case Qt.Key_Space:
            if (index < tabs.length) root.showTab(tabs[index].id); else root.showAccount();
            break;
        default: return;
        }
        Theme.keyboardNav = true;
        event.accepted = true;
    }

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
        } else if ([Qt.Key_Up, Qt.Key_Down, Qt.Key_Left, Qt.Key_Right, Qt.Key_Tab, Qt.Key_Backtab].includes(event.key)) {
            // An arrow nobody took: focus was on the page itself, so put it on a control
            Theme.keyboardNav = true;
            focusFirst();
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
        anchors { top: parent.top; topMargin: Theme.topInset; left: parent.left; right: parent.right }
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
                id: tabRepeater
                model: page.tabs
                Rectangle {
                    id: navTab
                    required property var modelData
                    required property int index
                    Keys.onPressed: (event) => page.headerKey(index, event)
                    FocusRing { active: navTab.activeFocus }
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

        // Account: says whether PSN is connected, and is the way in to signing in
        Rectangle {
            id: account
            readonly property bool signedIn: Chiaki.settings.psnAuthToken ? true : false
            anchors { right: parent.right; rightMargin: Theme.margin - Theme.unit; top: parent.top; topMargin: Theme.px(20) }
            width: accountRow.implicitWidth + Theme.unit * 4
            height: Theme.px(36)
            radius: height / 2
            color: accountTap.pressed ? Theme.alpha(Theme.text, 0.26) : signedIn ? Theme.alpha(Theme.bgDeep, 0.55) : Theme.alpha(Theme.text, 0.13)
            Accessible.role: Accessible.Button
            Accessible.name: signedIn ? qsTr("PSN connected. Account options") : qsTr("Sign in to PSN")

            Row {
                id: accountRow
                anchors.centerIn: parent
                spacing: Theme.unit * 1.25
                StatusDot { anchors.verticalCenter: parent.verticalCenter; visible: account.signedIn; width: Theme.px(10); state: "on" }
                Icon { anchors.verticalCenter: parent.verticalCenter; visible: !account.signedIn; name: "user"; size: Theme.px(20); weight: 2.2 }
                Label {
                    anchors.verticalCenter: parent.verticalCenter
                    text: account.signedIn ? qsTr("PSN connected") : qsTr("Sign in")
                    font.pixelSize: Theme.textLabel
                    font.weight: Theme.weightStrong
                }
            }
            TapHandler { id: accountTap; onTapped: root.showAccount() }
            Keys.onPressed: (event) => page.headerKey(page.tabs.length, event)
            FocusRing { active: account.activeFocus }
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
                    : Theme.handheld ? qsTr("Built-in controls") : qsTr("%1 connected").arg(Vice.controllerName(Chiaki.controllers[0]))
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
