// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// The one place notifications are shown. Vice.qml decides which and in what order.
Column {
    id: host

    property bool inStream: false
    readonly property int limit: inStream ? Theme.toastsVisibleInStream : Theme.toastsVisible
    // Asked for when a focused toast goes away
    signal focusFallback()

    spacing: Theme.unit * 1.5

    Repeater {
        model: Vice.toasts.slice(0, host.limit)

        Toast {
            id: toast
            required property var modelData
            note: modelData
            compact: host.inStream
            width: host.inStream ? Math.min(implicitWidth, Theme.px(360)) : implicitWidth

            function leave() {
                const hadFocus = toast.focused;
                Vice.dismissToast(modelData.key);
                if (hadFocus)
                    host.focusFallback();
            }

            onAction: {
                const run = modelData.action;
                const hadFocus = toast.focused;
                Vice.dismissToast(modelData.key);
                if (hadFocus)
                    host.focusFallback();
                if (run)
                    run();
            }
            onDismissed: leave()

            Timer {
                // Routine notices leave on their own; actionable failures stay
                interval: Theme.toastDuration
                running: !toast.modelData.sticky && !toast.held
                onTriggered: Vice.dismissToast(toast.modelData.key)
            }

            Component.onCompleted: {
                if (typeof toast.Accessible.announce === "function")
                    toast.Accessible.announce((modelData.title || "") + ". " + (modelData.body || ""));
            }
        }
    }
}
