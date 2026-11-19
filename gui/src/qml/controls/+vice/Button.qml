// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice look for the button upstream's dialogs use. Behaviour is upstream's
// ../Button.qml unchanged: focus-chain navigation with up/down, Return to press.
import QtQuick
import QtQuick.Controls
import QtQuick.Controls.Material

Button {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    // vice: pill shape, pink when focused, with dark text on the pink
    Material.roundedScale: Material.FullScale
    Material.background: visualFocus ? Material.accent : undefined
    Material.foreground: visualFocus ? "#11122B" : undefined
    font.bold: true

    Component.onDestruction: {
        if (visualFocus) {
            let item = nextItemInFocusChain();
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
        }
    }

    Keys.onPressed: (event) => {
        switch (event.key) {
        case Qt.Key_Up:
            if (!firstInFocusChain) {
                let item = nextItemInFocusChain(false);
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Down:
            if (!lastInFocusChain) {
                let item = nextItemInFocusChain();
                if (item)
                    item.forceActiveFocus(Qt.TabFocusReason);
                if(!sendOutput)
                    event.accepted = true;
            }
            break;
        case Qt.Key_Return:
            if (visualFocus) {
                clicked();
            }
            event.accepted = true;
            break;
        }
    }
}
