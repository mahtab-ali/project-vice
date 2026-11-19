// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../AutoConnectView.qml: the same waiting, cancel and
// time-out behaviour, shown as a pending state with honest phases.
import QtQuick
import QtQuick.Controls

import org.streetpea.chiaking

import "vice"
import "vice/components" as V

Rectangle {
    id: view
    property bool allowClose: false
    property bool cancelling: false
    property bool timedOut: false
    readonly property string name: Vice.target ? Vice.target.name : qsTr("your console")
    color: Theme.bg

    function stop() {
        if (!allowClose)
            return;
        Chiaki.stopAutoConnect();
        root.showMainView();
    }

    // Stops the automatic connect. The wake request itself has already gone out.
    function cancel() {
        if (!allowClose || cancelling)
            return;
        cancelling = true;
        failTimer.start();
    }

    StackView.onActivated: progress.cancelButton.forceActiveFocus(Qt.TabFocusReason)
    Keys.onEscapePressed: view.cancel()

    Shortcut {
        sequence: "Ctrl+Q"
        onActivated: view.cancel()
    }

    V.Artwork { anchors.fill: parent; preset: "palms" }

    V.Panel {
        anchors.centerIn: parent
        width: progress.width + Theme.unit * 10
        height: progress.implicitHeight + Theme.unit * 8

        V.ProgressState {
            id: progress
            anchors.centerIn: parent
            title: view.timedOut ? qsTr("%1 did not wake").arg(view.name)
                 : view.cancelling ? qsTr("Cancelling…") : qsTr("Waking %1…").arg(view.name)
            body: view.timedOut ? qsTr("Timed out waiting for the console. Going back to your consoles.")
                : view.cancelling ? qsTr("The wake request was already sent, so the console may still start.")
                : qsTr("Waiting for your console to come online.")
            phases: [
                { text: qsTr("Wake request sent"), state: "done" },
                { text: qsTr("Console starting"), state: view.timedOut || view.cancelling ? "pending" : "active" },
                { text: qsTr("Connect"), state: "pending" }
            ]
            cancellable: !view.timedOut && !view.cancelling
            cancelButton.enabled: view.allowClose
            onCancelled: view.cancel()
        }
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: view.allowClose = true
    }

    Timer {
        id: failTimer
        interval: 2000
        onTriggered: view.stop()
    }

    Connections {
        target: Chiaki
        function onWakeupStartFailed() {
            view.timedOut = true;
            view.allowClose = true;
            failTimer.start();
        }
    }
}
