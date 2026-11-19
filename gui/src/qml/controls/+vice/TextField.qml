// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The text field upstream's pages use, drawn as a Vice field. Upstream's
// behaviour is kept: read-only until Return or a click, so a controller can
// move past it, and Escape or Return ends editing.
import QtQuick
import vice
import vice.components as V

V.TextInput {
    id: field
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    implicitHeight: Theme.controlHeight
    font.pixelSize: Theme.textBody
    readOnly: true
    onActiveFocusChanged: {
        if (!activeFocus)
            readOnly = true;
    }

    Keys.onReturnPressed: {
        if (readOnly) {
            readOnly = false;
            Qt.inputMethod.show();
        } else {
            readOnly = true;
        }
    }
    Keys.onEscapePressed: (event) => {
        if (readOnly) {
            event.accepted = false;
            return;
        }
        readOnly = true;
        editingFinished();
    }

    MouseArea {
        anchors.fill: parent
        enabled: parent.readOnly
        onClicked: {
            parent.forceActiveFocus(Qt.TabFocusReason);
            parent.readOnly = false;
            Qt.inputMethod.show();
        }
    }
}
