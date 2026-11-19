// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

// The one modal layer. Shows Vice.dialog over a navy scrim, takes focus
// while it is open and gives it back when it closes.
T.Popup {
    id: host

    // True while another window hosts the dialog (the OpenGL stream path)
    property bool suppressed: false
    // The request stays on screen while the popup fades out
    property var shown: null
    property Item restoreItem: null
    signal focusFallback()

    parent: T.Overlay.overlay
    anchors.centerIn: parent
    // A templates Popup does not size itself from its content
    width: contentItem.implicitWidth
    height: contentItem.implicitHeight
    modal: true
    dim: true
    focus: true
    padding: 0
    closePolicy: T.Popup.NoAutoClose
    visible: Vice.dialog !== null && !suppressed

    T.Overlay.modal: Rectangle { color: Theme.scrim }

    enter: Transition { NumberAnimation { property: "opacity"; from: 0; to: 1; duration: Theme.dur(Theme.fast) } }
    exit: Transition { NumberAnimation { property: "opacity"; from: 1; to: 0; duration: Theme.dur(Theme.fast) } }

    onAboutToShow: restoreItem = parent && parent.Window.window ? parent.Window.window.activeFocusItem : null
    onClosed: {
        if (restoreItem && restoreItem.visible && restoreItem.enabled)
            restoreItem.forceActiveFocus(Qt.TabFocusReason);
        else
            focusFallback();
        restoreItem = null;
    }

    Connections {
        target: Vice
        function onDialogChanged() {
            if (Vice.dialog)
                host.shown = Vice.dialog;
        }
    }
    Component.onCompleted: shown = Vice.dialog

    background: null
    contentItem: AlertDialog {
        request: host.shown
        maxHeight: host.parent ? host.parent.height - Theme.unit * 6 : Theme.px(640)
        onResolved: (which) => Vice.resolveDialog(which)
    }
}
