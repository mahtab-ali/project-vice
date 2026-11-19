// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

import ".."
import "../components" as V

// Sessions recorded on this computer by Main.qml. A value that was not
// measured shows as a dash, never as zero.
V.Page {
    id: page

    tab: "sessions"
    showStatus: false
    initialFocus: Vice.history.length ? list : emptyState.primaryButton
    artwork.preset: "palms"
    onBack: root.showTab("consoles")

    property int selected: 0
    readonly property var session: Vice.history.length ? Vice.history[Math.min(selected, Vice.history.length - 1)] : null
    readonly property var resolutions: ["360p", "540p", "720p", "1080p"]

    function stability(entry) {
        if (entry.loss === null || entry.loss === undefined)
            return { state: "off", text: qsTr("No measurements") };
        return entry.loss < 1 ? { state: "on", text: qsTr("Stable connection") } : { state: "rest", text: qsTr("Unstable connection") };
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: -Theme.px(2)
        text: qsTr("Your recent sessions")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }
    V.Label {
        id: sub
        anchors { left: headline.left; top: headline.bottom; topMargin: -Theme.px(4) }
        text: qsTr("Connection history on this computer")
        font.pixelSize: Theme.textHeading
    }

    V.Panel {
        id: detail
        visible: page.session !== null
        anchors { left: parent.left; right: parent.right; leftMargin: Theme.px(44); rightMargin: Theme.px(44); top: sub.bottom; topMargin: Theme.px(22) }
        height: Theme.px(88)

        V.Icon { x: Theme.px(54); anchors.verticalCenter: parent.verticalCenter; name: page.session ? Vice.consoleIcon(page.session.type) : "console"; size: Theme.px(58) }
        Rectangle { x: Theme.px(114); anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(52); color: Theme.alpha(Theme.text, 0.5) }
        Column {
            x: Theme.px(138)
            anchors.verticalCenter: parent.verticalCenter
            V.Label { text: page.session ? page.session.console || qsTr("Console") : ""; font.pixelSize: Theme.px(30); font.weight: Theme.weightDisplay }
            V.Label { text: page.session ? Vice.dayText(page.session.started) + "  ·  " + Vice.durationText(page.session.seconds) : ""; font.pixelSize: Theme.textHeading }
        }
        Row {
            anchors { right: parent.right; rightMargin: Theme.px(32); verticalCenter: parent.verticalCenter }
            spacing: Theme.unit * 3
            V.StatusDot { anchors.verticalCenter: parent.verticalCenter; state: page.session ? page.stability(page.session).state : "off" }
            V.Label { anchors.verticalCenter: parent.verticalCenter; text: page.session ? page.stability(page.session).text : ""; font.pixelSize: Theme.textHeading; font.weight: Theme.weightStrong }
            Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(38); color: Theme.alpha(Theme.text, 0.5) }
            V.Icon { anchors.verticalCenter: parent.verticalCenter; name: "monitor"; size: Theme.px(32); weight: 1.8 }
            V.Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.textHeading
                text: page.session ? (page.resolutions[page.session.resolution - 1] || "—") + "  ·  " + (page.session.fps ? qsTr("%1 fps").arg(page.session.fps) : "—") : ""
            }
        }
    }

    readonly property var columns: [0.5, 0.18, 0.18, 0.14]
    Row {
        id: header
        visible: page.session !== null
        anchors { left: detail.left; right: detail.right; leftMargin: Theme.px(30); top: detail.bottom; topMargin: Theme.px(14) }
        Repeater {
            model: [qsTr("Console"), qsTr("Duration"), qsTr("Packet loss"), qsTr("Dropped frames")]
            V.Label { required property int index; required property string modelData; width: header.width * page.columns[index]; text: modelData; font.weight: Theme.weightStrong }
        }
    }

    ListView {
        id: list
        visible: page.session !== null
        anchors { left: detail.left; right: detail.right; top: header.bottom; topMargin: Theme.px(8); bottom: bottomRow.top; bottomMargin: Theme.px(10) }
        clip: true
        model: Vice.history
        currentIndex: page.selected
        activeFocusOnTab: true
        boundsBehavior: Flickable.StopAtBounds
        Accessible.role: Accessible.List
        Accessible.name: qsTr("Sessions")
        Keys.onUpPressed: (event) => { if (page.selected > 0) page.selected--; else Theme.navKey(list, event, false) }
        Keys.onDownPressed: (event) => { if (page.selected < count - 1) page.selected++; else Theme.navKey(list, event, false) }

        delegate: Item {
            id: row
            required property var modelData
            required property int index
            readonly property bool current: index === page.selected
            width: list.width
            height: Theme.px(50)
            Accessible.role: Accessible.ListItem
            Accessible.name: (modelData.console || "") + ", " + Vice.dayText(modelData.started) + ", " + Vice.durationText(modelData.seconds)

            Rectangle {
                anchors.fill: parent
                radius: Theme.px(10)
                color: !row.current ? "transparent" : list.activeFocus && Theme.keyboardNav ? Theme.alpha(Theme.pink, 0.26) : Theme.highlight
            }
            Rectangle { visible: !row.current; anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.divider }
            TapHandler { onTapped: { page.selected = row.index; list.forceActiveFocus() } }

            Row {
                anchors { fill: parent; leftMargin: Theme.px(30) }
                Row {
                    width: parent.width * page.columns[0]
                    height: parent.height
                    spacing: Theme.unit * 2.5
                    V.Icon { anchors.verticalCenter: parent.verticalCenter; name: Vice.consoleIcon(row.modelData.type); size: Theme.px(36) }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: row.modelData.console || qsTr("Console"); font.pixelSize: Theme.textHeading; font.weight: Theme.weightButton }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: "·  " + Vice.dayText(row.modelData.started); font.pixelSize: Theme.textHeading }
                }
                V.Label { width: parent.width * page.columns[1]; anchors.verticalCenter: parent.verticalCenter; text: Vice.durationText(row.modelData.seconds); font.pixelSize: Theme.textHeading }
                V.Label { width: parent.width * page.columns[2]; anchors.verticalCenter: parent.verticalCenter; text: Vice.valueText(row.modelData.loss, "%", row.modelData.loss > 0 && row.modelData.loss < 10 ? 1 : 0); font.pixelSize: Theme.textHeading }
                V.Label { width: parent.width * page.columns[3]; anchors.verticalCenter: parent.verticalCenter; text: Vice.valueText(row.modelData.dropped, "", 0); font.pixelSize: Theme.textHeading }
            }
        }
    }

    V.EmptyState {
        id: emptyState
        visible: page.session === null
        anchors.centerIn: parent
        anchors.verticalCenterOffset: Theme.px(30)
        iconName: "history"
        title: qsTr("No sessions yet")
        body: qsTr("Your play history will appear here after your first session.")
        primaryText: qsTr("Go to consoles")
        note: qsTr("History is saved on this computer.")
        onPrimary: root.showTab("consoles")
    }

    Item {
        id: bottomRow
        visible: page.session !== null
        anchors { left: detail.left; right: detail.right; bottom: parent.bottom; bottomMargin: Theme.px(14) }
        height: Theme.buttonMd

        Row {
            anchors.verticalCenter: parent.verticalCenter
            spacing: Theme.unit * 2
            V.Icon { anchors.verticalCenter: parent.verticalCenter; name: "folder"; size: Theme.px(26); weight: 1.8 }
            V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Saved locally on this computer") }
        }
        V.Button {
            anchors.right: parent.right
            width: Theme.px(300)
            text: qsTr("Run benchmark")
            font.pixelSize: Theme.px(26)
            onTriggered: root.showBenchmark()
        }
    }
}
