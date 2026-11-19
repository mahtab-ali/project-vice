// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtCore

import ".."
import "../components" as V

// Before/after comparison. The numbers come from two measured sessions the app
// runs itself (Main.qml, startBenchmark); until one has been run there are none to show.
V.Page {
    id: page

    tab: "sessions"
    initialFocus: results ? saveButton : unavailable.primaryButton

    readonly property var target: root.benchmarkConsole()
    function run() {
        if (!root.startBenchmark())
            Vice.notify({ key: "benchmark", severity: "warning", title: qsTr("Nothing to measure against"), body: qsTr("A paired console has to be visible on this network.") });
    }
    artwork.preset: "palms"
    onBack: stack.pop()

    readonly property var results: Vice.benchmark

    function saveImage() {
        const folder = StandardPaths.writableLocation(StandardPaths.PicturesLocation);
        const file = folder + "/project-vice-comparison-" + Qt.formatDateTime(new Date(), "yyyyMMdd-HHmmss") + ".png";
        const path = String(file).replace(/^file:\/\//, "");
        panel.grabToImage((image) => {
            // Success is reported only once the file is really written
            if (image.saveToFile(path))
                Vice.notify({ key: "comparison-saved", severity: "success", title: qsTr("Comparison saved"), body: path, actionText: qsTr("Open folder"), action: () => Qt.openUrlExternally(folder) });
            else
                Vice.notify({ key: "comparison-failed", severity: "error", title: qsTr("Could not save the comparison"), body: path, sticky: true });
        });
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: Theme.px(2)
        text: qsTr("See the difference.")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }
    Rectangle {
        visible: page.results && page.results.example === true
        anchors { left: headline.right; leftMargin: Theme.unit * 2.5; verticalCenter: headline.verticalCenter; verticalCenterOffset: Theme.px(4) }
        width: exampleLabel.implicitWidth + Theme.unit * 5
        height: Theme.px(36)
        radius: height / 2
        color: Theme.alpha(Theme.text, 0.13)
        V.Label { id: exampleLabel; anchors.centerIn: parent; text: qsTr("Example results"); font.weight: Theme.weightStrong }
    }
    V.Label {
        id: sub
        anchors { left: headline.left; top: headline.bottom; topMargin: -Theme.px(4) }
        text: page.results && page.results.console
            ? qsTr("30-second comparison  ·  %1  ·  %2").arg(page.results.console).arg(Qt.formatDateTime(new Date(page.results.at), "d MMM, HH:mm"))
            : qsTr("30-second comparison  ·  Same computer, console and network")
        font.pixelSize: Theme.textHeading
    }

    V.Panel {
        id: panel
        visible: page.results !== null
        anchors { left: parent.left; leftMargin: Theme.px(40); top: sub.bottom; topMargin: Theme.px(20) }
        width: Theme.px(950)
        height: legend.height + rowsColumn.height + Theme.px(106)
        color: Theme.alpha(Theme.surfaceSolid, 0.92)

        Row {
            id: legend
            x: Theme.px(34)
            y: Theme.px(18)
            spacing: Theme.unit * 5
            Repeater {
                model: [{ color: Theme.info, text: qsTr("Stock settings") }, { color: Theme.pink, text: Theme.appName }]
                Row {
                    required property var modelData
                    spacing: Theme.unit * 2
                    Rectangle { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(26); height: Theme.px(22); radius: Theme.px(5); color: Theme.alpha(modelData.color, modelData.color === Theme.info ? 0.75 : 1) }
                    V.Label { anchors.verticalCenter: parent.verticalCenter; text: modelData.text; font.pixelSize: Theme.textHeading }
                }
            }
        }

        Column {
            id: rowsColumn
            anchors { left: legend.left; right: parent.right; rightMargin: Theme.px(34); top: legend.bottom; topMargin: Theme.px(18) }
            spacing: Theme.px(14)

            Repeater {
                model: page.results ? page.results.rows : []
                Item {
                    id: metric
                    required property var modelData
                    // Every bar with the same unit shares one scale, so lengths compare honestly
                    readonly property real peak: Math.max(0.0001, ...page.results.rows.filter(r => r.unit === modelData.unit).map(r => Math.max(r.stock, r.vice)))
                    readonly property real room: width - Theme.px(296) - Theme.px(110)
                    width: rowsColumn.width
                    height: Theme.px(60)

                    V.Label { anchors.verticalCenter: parent.verticalCenter; width: Theme.px(280); text: metric.modelData.label; font.pixelSize: Theme.px(23); font.weight: Theme.weightStrong; wrapMode: Text.Wrap }
                    Repeater {
                        model: [{ value: metric.modelData.stock, color: Theme.alpha(Theme.info, 0.75) }, { value: metric.modelData.vice, color: Theme.pink }]
                        Row {
                            required property var modelData
                            required property int index
                            x: Theme.px(296)
                            y: index * Theme.px(30) + Theme.px(4)
                            spacing: Theme.unit * 1.5
                            Rectangle { width: Math.max(Theme.px(6), metric.room * modelData.value / metric.peak); height: Theme.px(22); radius: Theme.px(6); color: modelData.color }
                            V.Label { anchors.verticalCenter: parent.verticalCenter; text: modelData.value + (metric.modelData.unit ? " " + metric.modelData.unit : ""); font.pixelSize: Theme.textHeading; font.weight: Theme.weightStrong }
                        }
                    }
                }
            }
        }

        Rectangle { anchors { left: legend.left; right: rowsColumn.right; bottom: footnote.top; bottomMargin: Theme.px(12) } height: 1; color: Theme.alpha(Theme.pink, 0.5) }
        V.Label {
            id: footnote
            anchors { left: legend.left; bottom: parent.bottom; bottomMargin: Theme.px(18) }
            // Client receive-to-present time; it is not end-to-end latency
            text: qsTr("Lower is better. Client timing excludes console encoding and the network. One run each, so small gaps are noise.")
        }
    }

    V.Panel {
        visible: page.results === null
        anchors { left: parent.left; leftMargin: Theme.px(40); top: sub.bottom; topMargin: Theme.px(20) }
        width: Theme.px(680)
        height: unavailable.implicitHeight + Theme.unit * 7

        V.EmptyState {
            id: unavailable
            anchors.centerIn: parent
            width: parent.width - Theme.unit * 8
            iconName: "signal"
            title: page.target ? qsTr("Measure this setup") : qsTr("No console to measure against")
            body: page.target
                ? qsTr("Two 30-second sessions on %1, one after the other: first with this app's speed tuning off, then with it on. It takes about a minute and a half, and the picture is on screen while it runs. Nothing here is estimated.").arg(page.target.host.name)
                : qsTr("A paired console has to be visible on this network. The comparison runs two short sessions on it.")
            primaryText: page.target ? qsTr("Run the benchmark") : qsTr("Back to sessions")
            onPrimary: page.target ? page.run() : page.back()
        }
    }

    Row {
        visible: page.results !== null
        anchors { left: panel.left; leftMargin: Theme.px(22); verticalCenter: runButton.verticalCenter }
        spacing: Theme.unit * 2
        V.Icon { anchors.verticalCenter: parent.verticalCenter; name: "monitor"; size: Theme.px(30); weight: 1.8 }
        V.Label { anchors.verticalCenter: parent.verticalCenter; text: page.results ? page.results.link || "" : ""; font.pixelSize: Theme.textHeading }
    }

    V.Button {
        id: runButton
        visible: page.results !== null
        anchors { right: saveButton.left; rightMargin: Theme.unit * 3; verticalCenter: saveButton.verticalCenter }
        kind: "outline"
        width: Theme.px(226)
        text: qsTr("Run again")
        onTriggered: page.run()
    }
    V.Button {
        id: saveButton
        visible: page.results !== null
        anchors { right: panel.right; bottom: parent.bottom; bottomMargin: Theme.px(22) }
        width: Theme.px(274)
        text: qsTr("Save comparison")
        onTriggered: page.saveImage()
    }
}
