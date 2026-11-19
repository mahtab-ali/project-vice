// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Behaviour of the Vice coordinators and controls, without a backend.
//   cd gui/vice-preview && ./test.sh
import QtQuick
import QtTest
import "../../src/qml/vice"
import "../../src/qml/vice/components" as V

Item {
    id: scene
    width: 800
    height: 700

    V.AlertDialog {
        id: dialog
        request: Vice.dialog
        onResolved: (which) => Vice.resolveDialog(which)
    }
    V.Button { id: button; y: 660; text: "Submit" }
    V.PinEntry { id: pin; x: 300; y: 600 }
    SignalSpy { id: triggered; target: button; signalName: "triggered" }

    TestCase {
        name: "Vice"
        when: windowShown

        function init() {
            Vice.persist = false;
            Vice.toasts = [];
            Vice.dialog = null;
            Vice.dialogQueue = [];
            button.busy = false;
            triggered.clear();
            pin.clear();
        }

        // ---- Notifications ----------------------------------------------------

        function test_sameEventUpdatesInPlace() {
            Vice.notify({ key: "unstable:a", severity: "warning", title: "Connection unstable", body: "first" });
            Vice.notify({ key: "unstable:a", severity: "warning", title: "Connection unstable", body: "second" });
            Vice.notify({ key: "unstable:b", severity: "warning", title: "Connection unstable", body: "other console" });
            compare(Vice.toasts.length, 2);
            compare(Vice.toasts.find(t => t.key === "unstable:a").body, "second");
        }

        function test_actionableFailuresComeFirstAndStay() {
            Vice.notify({ key: "saved", severity: "success", title: "Settings saved" });
            Vice.notify({ key: "pad", severity: "error", title: "Controller disconnected", actionText: "Controller settings", action: () => { } });
            Vice.notify({ key: "info", severity: "info", title: "Wake request sent" });
            compare(Vice.toasts[0].key, "pad");
            compare(Vice.toasts[0].sticky, true);
            compare(Vice.toasts.find(t => t.key === "saved").sticky, false);
            compare(Vice.toasts[Vice.toasts.length - 1].key, "saved");
        }

        function test_queueIsBounded() {
            for (let i = 0; i < 40; ++i)
                Vice.notify({ key: "n" + i, severity: "info", title: "Notice " + i });
            compare(Vice.toasts.length, Theme.toastsVisible + Theme.toastsQueued);
            // An urgent one still gets in, ahead of the routine ones
            Vice.notify({ key: "lost", severity: "error", title: "Connection lost", actionText: "Try again", action: () => { } });
            compare(Vice.toasts[0].key, "lost");
            compare(Vice.toasts.length, Theme.toastsVisible + Theme.toastsQueued);
        }

        function test_dismissRemovesOnlyThatNotice() {
            Vice.notify({ key: "a", severity: "info", title: "A" });
            Vice.notify({ key: "b", severity: "info", title: "B" });
            Vice.dismissToast("a");
            compare(Vice.toasts.length, 1);
            compare(Vice.toasts[0].key, "b");
        }

        // ---- Dialog coordinator -----------------------------------------------

        function test_oneModalAtATimeQueuesTheRest() {
            Vice.ask({ key: "first", title: "First", primary: { text: "OK" } });
            Vice.ask({ key: "second", title: "Second", primary: { text: "OK" } });
            Vice.ask({ key: "second", title: "Second", primary: { text: "OK" } });
            compare(Vice.dialog.key, "first");
            compare(Vice.dialogQueue.length, 1);
            Vice.resolveDialog("primary");
            compare(Vice.dialog.key, "second");
            Vice.resolveDialog("primary");
            compare(Vice.dialog, null);
        }

        function test_urgentFailureReplacesAndCancelsTheOlderDialog() {
            let quit = 0, stayed = 0;
            Vice.ask({ key: "quit", severity: "question", title: "Quit?", primary: { text: "Stay", run: () => stayed++ }, secondary: { text: "Quit", run: () => quit++ }, cancel: "primary" });
            Vice.ask({ key: "connection-lost", severity: "error", priority: 3, title: "Connection lost", primary: { text: "Try again" }, secondary: { text: "Back" }, cancel: "secondary" });
            compare(Vice.dialog.key, "connection-lost");
            compare(stayed, 1);   // the replaced dialog was answered with its cancel path
            compare(quit, 0);
            compare(Vice.dialogQueue.length, 0);
        }

        function test_cancelTakesTheSafeAnswer() {
            let disconnected = 0, kept = 0;
            Vice.ask({ key: "disconnect", title: "End remote play?", primary: { text: "Keep playing", run: () => kept++ }, secondary: { text: "Disconnect", run: () => disconnected++ }, cancel: "primary" });
            Vice.resolveDialog("cancel");
            compare(kept, 1);
            compare(disconnected, 0);
            compare(Vice.dialog, null);
        }

        function test_pendingActionKeepsTheDialogAndShowsFailure() {
            let tries = 0;
            Vice.ask({ key: "connection-lost", severity: "error", title: "Connection lost", primary: { text: "Try again", keepOpen: true, run: () => { tries++; Vice.updateDialog("connection-lost", { busy: true }); } }, secondary: { text: "Back" }, cancel: "secondary" });
            Vice.resolveDialog("primary");
            verify(Vice.dialog !== null);
            compare(Vice.dialog.busy, true);
            Vice.updateDialog("connection-lost", { busy: false, error: "Still unreachable" });
            compare(Vice.dialog.error, "Still unreachable");
            compare(tries, 1);
        }

        // ---- Operation identity -----------------------------------------------

        function test_lateResultAfterCancelIsStale() {
            const first = Vice.beginOp("pair");
            verify(Vice.isCurrent("pair", first));
            Vice.cancelOp("pair");
            verify(!Vice.isCurrent("pair", first));
            const second = Vice.beginOp("pair");
            verify(Vice.isCurrent("pair", second));
            verify(!Vice.isCurrent("pair", first));
        }

        // ---- Controls -----------------------------------------------------------

        function test_dialogFocusStaysInsideAndEscapeCancels() {
            let kept = 0;
            Vice.ask({ key: "disconnect", title: "End remote play?", primary: { text: "Keep playing", run: () => kept++ }, secondary: { text: "Disconnect", danger: true }, cancel: "primary" });
            dialog.forceActiveFocus();
            wait(20);   // the dialog focuses its default action once the request has landed
            const first = scene.Window.activeFocusItem;
            verify(first.text === "Keep playing", "the safe action has focus by default");
            keyClick(Qt.Key_Down);
            compare(scene.Window.activeFocusItem.text, "Disconnect");
            keyClick(Qt.Key_Down);
            compare(scene.Window.activeFocusItem.text, "Keep playing");   // wraps, never leaves
            keyClick(Qt.Key_Tab);
            compare(scene.Window.activeFocusItem.text, "Disconnect");
            keyClick(Qt.Key_Escape);
            compare(kept, 1);
            compare(Vice.dialog, null);
        }

        function test_busyButtonSubmitsOnce() {
            button.forceActiveFocus();
            keyClick(Qt.Key_Return);
            compare(triggered.count, 1);
            button.busy = true;
            keyClick(Qt.Key_Return);
            mouseClick(button);
            compare(triggered.count, 1);
        }

        // ---- Automatic stream decisions -----------------------------------------

        function test_adaptiveStepWalksDownAndStops() {
            compare(Vice.adaptiveStep(15, 4), { mbps: 10, resolution: 4 });
            compare(Vice.adaptiveStep(10, 4), { mbps: 7, resolution: 4 });
            compare(Vice.adaptiveStep(7, 4), { mbps: 6, resolution: 4 });
            // At 6 Mbps a 1080p stream gives up resolution, not more bitrate
            compare(Vice.adaptiveStep(6, 4), { mbps: 8, resolution: 3 });
            compare(Vice.adaptiveStep(6, 3), { mbps: 3, resolution: 3 });
            compare(Vice.adaptiveStep(3, 3), null);
        }

        function test_bufferFollowsJitterAndNeedsAMeasurement() {
            compare(Vice.bufferFor(undefined, true), null);
            compare(Vice.bufferFor(NaN, true), null);
            compare(Vice.bufferFor(1, true), 3);
            compare(Vice.bufferFor(1, false), 4);
            compare(Vice.bufferFor(20, true), 9);
            compare(Vice.bufferFor(20, false), 10);
        }

        function test_sticksAreKeptPerProfile() {
            compare(Vice.sticksFor("").left, 0);
            Vice.setSticksFor("GTA VI", { preset: "driving", left: 8, right: 6, curve: 1 });
            compare(Vice.sticksFor("GTA VI").left, 8);
            compare(Vice.sticksFor("").left, 0);
        }

        function test_pinTakesEightDigitsOnly() {
            pin.forceActiveFocus();
            for (const key of "48a21 07x36999")
                keyClick(key);
            compare(pin.text, "48210736");
            verify(pin.complete);
            keyClick(Qt.Key_Backspace);
            compare(pin.text, "4821073");
            verify(!pin.complete);
        }
    }
}
