// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Shapes
import QtQuick.Controls

import org.streetpea.chiaking
import vice.backend

import ".."
import "../components" as V

// Pre-flight check of the link to one console. Every number on this page is
// measured by NetCheck (round trips of the console's discovery request);
// nothing is shown until it has been measured.
V.Page {
    id: page

    // { index, key, host } from Vice.consoles()
    property var entry: null
    readonly property int seconds: 30
    readonly property string name: entry ? entry.host.name : ""
    readonly property bool ps5: entry ? entry.host.ps5 !== false : true
    readonly property bool done: !check.running && check.sent > 0
    readonly property bool silent: done && check.received === 0
    // good | fair | poor, from the measurements
    readonly property string grade: {
        if (!done || silent)
            return "";
        if (check.loss <= 0.5 && check.jitter <= 5 && check.ping <= 25)
            return "good";
        if (check.loss <= 2 && check.jitter <= 15 && check.ping <= 60)
            return "fair";
        return "poor";
    }
    // Upstream's default bitrate for each resolution
    readonly property var advice: grade === "good" ? { resolution: ps5 ? "1080p" : "720p", fps: 60, mbps: ps5 ? 15 : 10 }
                                : grade === "fair" ? { resolution: "720p", fps: 60, mbps: 10 }
                                : { resolution: "540p", fps: 30, mbps: 6 }
    readonly property string linkText: check.link === "wired" ? qsTr("Wired") : check.link === "wifi" ? qsTr("Wi-Fi") : qsTr("Unknown")

    tab: "consoles"
    initialFocus: check.running ? cancelButton : nextButton
    artwork { imageX: 0.53; imageY: 0.05; atX: 0.865; atY: 0.065; zoom: 0.74; fadeLeft: 0.78; fadeBottom: 0.42 }
    onBack: {
        check.stop();
        stack.pop();
    }

    function run() {
        if (entry)
            check.start(entry.host.address, ps5, seconds);
    }
    StackView.onActivating: if (!check.running && check.sent === 0) run()
    StackView.onRemoved: check.stop()

    NetCheck {
        id: check
        onFinished: {
            if (page.entry && received > 0)
                Vice.lastCheck = { key: page.entry.key, ping: ping, jitter: jitter, loss: loss, link: link, at: Date.now() };
            page.focusFirst();
        }
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: -Theme.px(2)
        text: check.running ? qsTr("Checking your connection…")
            : page.silent ? qsTr("No answer.")
            : page.grade === "good" ? qsTr("Ready to play.")
            : page.grade === "fair" ? qsTr("Good enough to play.")
            : page.grade === "poor" ? qsTr("Expect stutter.") : qsTr("Connection check")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }
    V.Label {
        id: sub
        anchors { left: headline.left; top: headline.bottom; topMargin: -Theme.px(4) }
        font.pixelSize: Theme.textHeading
        text: check.running ? qsTr("Measuring the link to %1 for %2 seconds.").arg(page.name).arg(page.seconds)
            : page.silent ? qsTr("%1 did not reply. Check that it is on, or in rest mode, and on this network.").arg(page.name)
            : page.grade === "good" ? (check.link === "wired" ? qsTr("Your wired connection looks stable.") : qsTr("Your connection looks stable."))
            : page.grade === "fair" ? qsTr("Some delay or loss was measured. A lower resolution will hold up better.")
            : page.grade === "poor" ? qsTr("High delay or loss was measured. A wired connection would help most.") : ""
    }

    Row {
        id: chain
        anchors { left: headline.left; top: sub.bottom; topMargin: Theme.px(14) }
        spacing: Theme.unit * 2

        component Hop: Row {
            property alias iconName: hopIcon.name
            property alias text: hopLabel.text
            property bool ok: false
            spacing: Theme.unit * 1.5
            V.Icon { id: hopIcon; anchors.verticalCenter: parent.verticalCenter; size: Theme.px(38); weight: 1.8 }
            V.Label { id: hopLabel; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.textHeading }
            V.StatusIcon { anchors.verticalCenter: parent.verticalCenter; visible: parent.ok; severity: "success"; size: Theme.px(24) }
        }
        component Wire: Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(84); height: Theme.border * 1.5; color: Theme.lineStrong }

        Hop { iconName: "console"; text: page.name; ok: check.received > 0 }
        Wire { }
        Hop { iconName: check.link === "wifi" ? "wifi" : "ethernet"; text: check.link === "wired" ? qsTr("Ethernet") : check.link === "wifi" ? qsTr("Wi-Fi") : qsTr("Network"); ok: check.received > 0 }
        Wire { }
        Hop { iconName: "monitor"; text: qsTr("This computer"); ok: check.sent > 0 }
    }

    V.Panel {
        id: stats
        anchors { left: parent.left; leftMargin: Theme.px(42); top: chain.bottom; topMargin: Theme.px(14) }
        width: Theme.px(864)
        height: Theme.px(102)

        Row {
            anchors.fill: parent
            component Stat: Item {
                property alias label: statLabel.text
                property alias value: statValue.text
                property bool rule: true
                width: stats.width / 4
                height: stats.height
                Rectangle { visible: parent.rule; anchors.verticalCenter: parent.verticalCenter; width: Theme.border; height: Theme.px(60); color: Theme.alpha(Theme.text, 0.35) }
                Column {
                    x: Theme.px(46)
                    anchors.verticalCenter: parent.verticalCenter
                    V.Label { id: statLabel; font.pixelSize: Theme.textHeading }
                    V.Label { id: statValue; font.pixelSize: Theme.px(40); font.weight: Theme.weightDisplay }
                }
            }
            // A dash until there is a measurement: never a zero that was not measured
            Stat { rule: false; label: qsTr("Ping"); value: check.received ? Vice.valueText(check.ping, " ms", check.ping < 10 ? 1 : 0) : "—" }
            Stat { label: qsTr("Jitter"); value: check.received > 1 ? Vice.valueText(check.jitter, " ms", 1) : "—" }
            Stat { label: qsTr("Packet loss"); value: check.sent ? Vice.valueText(check.loss, "%", check.loss > 0 && check.loss < 10 ? 1 : 0) : "—" }
            Stat { label: qsTr("Link"); value: check.sent ? page.linkText : "—" }
        }
    }

    V.Label {
        id: chartTitle
        anchors { left: headline.left; top: stats.bottom; topMargin: Theme.px(14) }
        text: qsTr("%1-second connection check").arg(page.seconds)
        font.pixelSize: Theme.textHeading
        font.weight: Theme.weightStrong
    }

    Item {
        id: chart
        anchors { left: headline.left; top: chartTitle.bottom; topMargin: Theme.px(10) }
        width: Theme.px(920)
        height: Theme.px(92)

        readonly property real plotX: Theme.px(52)
        readonly property real plotW: width - plotX
        readonly property var replies: check.samples.filter(s => s >= 0)
        // Top of the scale: the next "nice" value above the slowest reply
        readonly property real ceiling: {
            const peak = replies.length ? Math.max.apply(null, replies) : 0;
            const steps = [4, 10, 20, 50, 100, 200, 500, 1000, 2000];
            return steps.find(s => s >= peak * 1.25) || 5000;
        }

        Repeater {
            model: [1, 0.5, 0]
            Item {
                required property real modelData
                y: (1 - modelData) * (chart.height - Theme.px(8))
                width: chart.width
                V.Label { anchors.verticalCenter: line.verticalCenter; text: qsTr("%1 ms").arg(chart.ceiling * parent.modelData); font.pixelSize: Theme.textSmall; font.weight: Theme.weightStrong }
                Rectangle { id: line; x: chart.plotX; width: chart.plotW; height: 1; color: Theme.alpha(Theme.text, parent.modelData === 0 ? 0.6 : 0.2) }
            }
        }
        Rectangle { x: chart.plotX; width: 1; height: chart.height - Theme.px(8); color: Theme.alpha(Theme.text, 0.6) }

        Shape {
            x: chart.plotX
            width: chart.plotW
            height: chart.height - Theme.px(8)
            preferredRendererType: Shape.CurveRenderer
            visible: chart.replies.length > 1

            ShapePath {
                strokeColor: Theme.pink
                strokeWidth: Math.max(2, Theme.px(2.5))
                fillColor: "transparent"
                joinStyle: ShapePath.RoundJoin
                PathPolyline {
                    // One point per reply, placed by when it was sent; lost requests leave a gap in time
                    path: {
                        const points = [];
                        const total = Math.max(check.expected, check.samples.length, 2);
                        for (let i = 0; i < check.samples.length; ++i) {
                            if (check.samples[i] >= 0)
                                points.push(Qt.point(i / (total - 1) * chart.plotW, (1 - Math.min(1, check.samples[i] / chart.ceiling)) * (chart.height - Theme.px(8))));
                        }
                        return points;
                    }
                }
            }
        }

        Repeater {
            model: [0, 0.5, 1]
            V.Label {
                required property real modelData
                x: chart.plotX + modelData * chart.plotW - (modelData === 1 ? width : modelData === 0 ? 0 : width / 2)
                y: chart.height
                text: qsTr("%1s").arg(Math.round(page.seconds * modelData))
                font.pixelSize: Theme.textSmall
                font.weight: Theme.weightStrong
            }
        }
    }

    V.Panel {
        id: advicePanel
        anchors { left: stats.left; bottom: parent.bottom; bottomMargin: Theme.px(42) }
        width: Theme.px(664)
        height: Theme.buttonMd

        Row {
            anchors { verticalCenter: parent.verticalCenter; left: parent.left; leftMargin: Theme.unit * 3 }
            spacing: Theme.unit * 2

            V.Spinner { anchors.verticalCenter: parent.verticalCenter; visible: check.running; size: Theme.px(28) }
            V.StatusIcon {
                anchors.verticalCenter: parent.verticalCenter
                visible: !check.running
                severity: page.silent ? "error" : page.grade === "good" ? "success" : page.grade ? "warning" : "info"
                size: Theme.px(30)
            }
            V.Label {
                anchors.verticalCenter: parent.verticalCenter
                font.pixelSize: Theme.textHeading
                font.weight: Theme.weightStrong
                text: check.running ? qsTr("%1 of %2 replies so far").arg(check.received).arg(check.sent)
                    : page.silent ? qsTr("Nothing to recommend without a reply")
                    : page.grade ? [qsTr("Recommended"), page.advice.resolution, qsTr("%1 fps").arg(page.advice.fps), qsTr("%1 Mbps").arg(page.advice.mbps)].join("  ·  ")
                    : qsTr("Not measured yet")
            }
        }
    }

    Row {
        anchors { left: headline.left; bottom: parent.bottom; bottomMargin: Theme.px(10) }
        spacing: Theme.unit * 1.5
        V.Icon { anchors.verticalCenter: parent.verticalCenter; name: "info"; size: Theme.px(22) }
        V.Label { anchors.verticalCenter: parent.verticalCenter; text: page.name + "  ·  " + qsTr("Local network"); font.pixelSize: Theme.textLabel }
    }

    Row {
        anchors { right: parent.right; rightMargin: Theme.margin; verticalCenter: advicePanel.verticalCenter }
        spacing: Theme.unit * 3

        V.Button {
            id: cancelButton
            anchors.verticalCenter: parent.verticalCenter
            kind: "outline"
            width: Theme.px(180)
            text: check.running ? qsTr("Cancel") : qsTr("Run again")
            onTriggered: check.running ? check.stop() : page.run()
        }
        V.Button {
            id: nextButton
            width: Theme.px(300)
            size: "lg"
            font.pixelSize: Theme.px(28)
            implicitHeight: Theme.px(58)
            text: qsTr("Choose mode")
            enabled: !check.running && page.entry && (page.entry.host.registered ? true : false)
            onTriggered: root.showChooseMode(page.entry)
        }
    }
}
