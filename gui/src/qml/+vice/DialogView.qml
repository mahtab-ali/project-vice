// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../DialogView.qml, the frame of every upstream dialog
// page (all settings, add console, PSN sign-in, button mapping, …). Same
// properties, signals and focus handling; Vice header and buttons.
import QtQuick
import QtQuick.Controls

import "vice"
import "vice/components" as V

Item {
    id: dialog
    property alias header: headerLabel.text
    property alias title: titleLabel.text
    property alias buttonText: okButton.text
    property alias buttonEnabled: okButton.enabled
    property alias buttonVisible: okButton.visible
    property Item restoreFocusItem
    default property Item mainItem: null

    signal accepted()
    signal rejected()

    function close() {
        root.closeDialog();
    }

    Keys.onEscapePressed: close()

    Keys.onMenuPressed: {
        if (okButton.enabled)
            okButton.clicked()
    }

    StackView.onDeactivating: {
        restoreFocusItem = Window.window.activeFocusItem;
    }

    StackView.onActivated: {
        if (!restoreFocusItem) {
            let item = mainItem.nextItemInFocusChain();
            if (item)
                item.forceActiveFocus(Qt.TabFocusReason);
        } else {
            restoreFocusItem.forceActiveFocus(Qt.TabFocusReason);
            restoreFocusItem = null;
        }
    }

    onMainItemChanged: {
        if (mainItem) {
            mainItem.parent = contentItem;
            mainItem.anchors.fill = contentItem;
        }
    }

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0; color: "#17153A" }
            GradientStop { position: 0.5; color: Theme.bg }
            GradientStop { position: 1; color: Theme.bgDeep }
        }
    }

    // The same strip of key art the Vice settings page carries, behind the header
    V.Artwork {
        width: parent.width
        height: Theme.px(170)
        imageX: 1; imageY: 0.36; atX: 1; atY: 0.5; zoom: 3.6
        fadeStart: 0.5; fadeLeft: 0.86; fadeBottom: 0.6
    }

    Item {
        id: toolBar
        anchors { top: parent.top; topMargin: Theme.topInset; left: parent.left; right: parent.right }
        height: Theme.px(92)

        V.Button {
            id: backButton
            anchors { left: parent.left; leftMargin: Theme.margin - Theme.unit; verticalCenter: parent.verticalCenter }
            kind: "outline"
            size: "sm"
            text: qsTr("Back")
            focusPolicy: Qt.NoFocus
            onClicked: {
                dialog.rejected();
                dialog.close();
            }
        }

        V.Label {
            id: titleLabel
            anchors { left: backButton.right; leftMargin: Theme.unit * 3; verticalCenter: parent.verticalCenter }
            font.pixelSize: Theme.px(40)
            font.weight: Theme.weightDisplay
        }

        V.Label {
            id: headerLabel
            anchors { left: titleLabel.right; leftMargin: Theme.unit * 3; right: okButton.left; rightMargin: Theme.unit * 2; verticalCenter: parent.verticalCenter }
            font.pixelSize: Theme.textSmall
            color: Theme.textMuted
            wrapMode: Text.Wrap
            maximumLineCount: 3
            elide: Text.ElideRight
        }

        V.Button {
            id: okButton
            anchors { right: parent.right; rightMargin: Theme.margin - Theme.unit; verticalCenter: parent.verticalCenter }
            size: "sm"
            implicitHeight: Theme.px(46)
            focusPolicy: Qt.NoFocus
            onClicked: dialog.accepted()

            V.Glyph {
                anchors { right: parent.left; rightMargin: Theme.unit * 1.5; verticalCenter: parent.verticalCenter }
                visible: okButton.visible
                button: "options"
            }
        }

    }

    Item {
        id: contentItem
        anchors { top: toolBar.bottom; left: parent.left; right: parent.right; bottom: parent.bottom }
    }
}
