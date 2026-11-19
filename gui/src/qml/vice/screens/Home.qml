// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import org.streetpea.chiaking

import ".."
import "../components" as V

// Console picker. One console is the hero; the others wait in the list
// below it. `root` is Main.qml, which owns navigation and backend commands.
V.Page {
    id: home

    tab: "consoles"
    initialFocus: hero ? connectButton : emptyState.primaryButton
    hints: {
        const out = [{ button: "cross", text: qsTr("Select") }];
        if (focusedOther && Vice.canWake(focusedOther.host))
            out.push({ button: "pyramid", text: qsTr("Wake") });
        if (hero && (hero.host.manual || (hero.host.discovered && !hero.host.registered)))
            out.push({ button: "box", text: hero.host.manual ? qsTr("Remove") : qsTr("Hide") });
        out.push({ button: "moon", text: qsTr("Quit") });
        return out;
    }
    onBack: root.confirmQuit()

    readonly property var consoles: Vice.consoles(Chiaki.hosts)
    // The stored choice survives discovery refreshes; if that console is
    // gone for now, the first one stands in without overwriting the choice.
    readonly property var hero: consoles.find(c => c.key === Vice.selectedConsole) || consoles[0] || null
    readonly property var others: hero ? consoles.filter(c => c.key !== hero.key) : []
    property var focusedOther: null
    readonly property bool heroFailed: hero && Vice.failed && Vice.failed.key === hero.key ? true : false

    // A search the user asked for; discovery itself reports no "finished" event
    property bool searching: false
    Timer { id: searchTimer; interval: 6000; onTriggered: home.searching = false }
    function searchAgain() {
        searching = true;
        searchTimer.restart();
        Chiaki.discoveryEnabled = false;
        Chiaki.discoveryEnabled = true;
    }
    Component.onCompleted: {
        if (!consoles.length && Chiaki.discoveryEnabled) {
            searching = true;
            searchTimer.start();
        }
    }

    Keys.onNoPressed: if (hero) root.removeConsole(hero)
    Keys.onMenuPressed: root.showTab("settings")
    Keys.onPressed: (event) => {
        if (event.modifiers)
            return;
        if (event.key === Qt.Key_F1 && typeof Chiaki.createSteamShortcut === "function")
            root.showSteamShortcutDialog(false);
        else if (event.key === Qt.Key_F2)
            root.showManualHostDialog();
        else
            return;
        event.accepted = true;
    }

    Column {
        id: heroColumn
        visible: home.hero !== null
        x: Theme.margin
        y: Theme.px(38)
        width: Math.min(parent.width * 0.5, Theme.px(620))

        V.Label {
            text: qsTr("YOUR CONSOLES")
            font.pixelSize: Theme.textLabel
            font.weight: Theme.weightStrong
            font.letterSpacing: Theme.px(0.6)
        }

        Item { width: 1; height: Theme.px(6) }

        V.Label {
            width: parent.width
            text: home.hero ? home.hero.host.name : ""
            font.pixelSize: Theme.textHero
            font.weight: Theme.weightDisplay
            elide: Text.ElideRight
            opacity: home.heroFailed ? 0.75 : 1
        }

        Row {
            spacing: Theme.unit * 1.5
            topPadding: Theme.px(2)

            V.StatusDot {
                anchors.verticalCenter: parent.verticalCenter
                state: home.heroFailed ? "error" : home.hero ? Vice.stateOf(home.hero.host) : "off"
            }
            V.Label {
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (!home.hero)
                        return "";
                    const type = Vice.typeOf(home.hero.host);
                    const state = home.heroFailed ? qsTr("Unavailable") : Vice.stateText(home.hero.host);
                    return type ? type + "  ·  " + state : state;
                }
                font.pixelSize: Theme.textHeading
            }
        }

        Item { width: 1; height: Theme.px(26) }

        V.Button {
            id: connectButton
            x: -Theme.px(4)
            width: Theme.px(400)
            size: "lg"
            text: !home.hero ? "" : home.hero.host.registered || Vice.isRemote(home.hero.host) ? qsTr("Connect") : qsTr("Pair console")
            onTriggered: root.connectOrPair(home.hero)
        }

        Item { width: 1; height: Theme.px(10) }

        V.Button {
            x: Theme.unit
            kind: "text"
            iconName: "pulse"
            text: qsTr("Connection check")
            font.pixelSize: Theme.textHeading
            font.weight: Theme.weightBody
            // Needs an address on this network to measure against
            visible: home.hero && home.hero.host.address && !Vice.isRemote(home.hero.host) ? true : false
            onTriggered: root.showConnectionCheck(home.hero)
        }
    }

    ListView {
        id: otherList
        visible: home.hero !== null
        anchors { top: heroColumn.bottom; topMargin: Theme.px(22); left: parent.left; leftMargin: Theme.px(40) }
        width: Theme.px(404)
        // One card and a hint of the next when there are more
        height: Math.min(contentHeight, Math.max(Theme.px(102), addButton.y - y - Theme.unit))
        clip: true
        spacing: Theme.unit
        model: home.others
        boundsBehavior: Flickable.StopAtBounds

        delegate: V.Panel {
            id: card
            required property var modelData
            required property int index
            width: Theme.px(396)
            height: Theme.px(94)
            x: Theme.px(4)
            activeFocusOnTab: true
            color: activeFocus && Theme.keyboardNav ? Theme.highlight : Theme.surfaceSoft
            Accessible.role: Accessible.ListItem
            Accessible.name: modelData.host.name + ", " + Vice.stateText(modelData.host)

            function select() { Vice.selectedConsole = modelData.key; connectButton.forceActiveFocus(Qt.TabFocusReason) }

            onActiveFocusChanged: {
                if (activeFocus) {
                    home.focusedOther = modelData;
                    otherList.positionViewAtIndex(index, ListView.Contain);
                } else if (home.focusedOther === modelData) {
                    home.focusedOther = null;
                }
            }
            Keys.onReturnPressed: select()
            Keys.onYesPressed: if (Vice.canWake(modelData.host)) root.wake(modelData)
            Keys.onPressed: (event) => Theme.navKey(card, event, false)
            TapHandler { onTapped: card.select() }

            V.Icon { id: cardIcon; x: Theme.px(26); anchors.verticalCenter: parent.verticalCenter; name: Vice.consoleIcon(Vice.typeOf(card.modelData.host)); size: Theme.px(52) }
            Rectangle { id: cardRule; x: Theme.px(78); anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(52); color: Theme.alpha(Theme.text, 0.45) }

            Column {
                anchors { left: cardRule.right; leftMargin: Theme.unit * 2; right: wakeButton.visible ? wakeButton.left : parent.right; rightMargin: Theme.unit; verticalCenter: parent.verticalCenter }
                spacing: Theme.px(2)

                V.Label {
                    width: parent.width
                    text: card.modelData.host.name
                    font.pixelSize: Theme.px(25)
                    font.weight: Theme.weightButton
                    elide: Text.ElideRight
                }
                Row {
                    spacing: Theme.unit * 1.25
                    V.StatusDot { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(11); state: Vice.stateOf(card.modelData.host) === "on" ? "on" : "off" }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: Vice.stateText(card.modelData.host); color: Theme.textMuted }
                }
            }

            V.Button {
                id: wakeButton
                anchors { right: parent.right; rightMargin: Theme.unit * 2; verticalCenter: parent.verticalCenter }
                visible: Vice.canWake(card.modelData.host)
                kind: "outline"
                size: "sm"
                text: qsTr("Wake")
                focusPolicy: Qt.NoFocus
                onTriggered: root.wake(card.modelData)
            }
        }
    }

    V.Button {
        id: addButton
        visible: home.hero !== null
        x: Theme.margin - Theme.unit
        y: Math.min(otherList.y + (home.others.length ? Theme.px(102) : 0) + Theme.px(18), parent.height - height - Theme.unit)
        kind: "text"
        iconName: "plus"
        text: qsTr("Add console")
        font.pixelSize: Theme.textHeading
        onTriggered: root.showManualHostDialog()
    }

    // No consoles: searching, none found, or search turned off are told apart
    V.Panel {
        visible: home.hero === null
        x: Theme.margin - Theme.unit
        anchors.verticalCenter: parent.verticalCenter
        width: Theme.px(560)
        height: emptyState.implicitHeight + Theme.unit * 8

        V.EmptyState {
            id: emptyState
            anchors.centerIn: parent
            width: parent.width - Theme.unit * 8
            iconName: home.searching ? "search" : "console"
            title: home.searching ? qsTr("Looking for consoles…")
                 : Chiaki.discoveryEnabled ? qsTr("No consoles yet") : qsTr("Search is off")
            body: home.searching ? qsTr("Checking this network for consoles that are on or in rest mode.")
                : Chiaki.discoveryEnabled ? qsTr("Add your console to start playing on this computer. It must be on the same network, or added by address.")
                : qsTr("Network search is turned off, so consoles do not appear on their own.")
            primaryText: qsTr("Add console")
            secondaryText: Chiaki.discoveryEnabled ? qsTr("Search again") : qsTr("Turn on search")
            secondaryBusy: home.searching
            onPrimary: root.showManualHostDialog()
            onSecondary: home.searchAgain()
        }
    }
}
