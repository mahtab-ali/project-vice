// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.ComboBox {
    id: control

    // Indexes of options that are listed but cannot be picked (unavailable capability)
    property var disabledIndexes: []

    implicitWidth: Theme.px(320)
    implicitHeight: Theme.controlHeight
    leftPadding: Theme.unit * 2.5
    rightPadding: Theme.unit * 5
    focusPolicy: Qt.StrongFocus
    opacity: enabled ? 1 : Theme.disabledOpacity
    font.family: Theme.family
    font.pixelSize: Theme.textBody
    font.weight: Theme.weightStrong
    Accessible.role: Accessible.ComboBox

    Keys.onReturnPressed: {
        if (popup.visible) {
            if (!disabledIndexes.includes(highlightedIndex)) {
                currentIndex = highlightedIndex;
                activated(highlightedIndex);
            }
            popup.close();
        } else {
            popup.open();
        }
    }
    Keys.onPressed: (event) => {
        if (!popup.visible)
            Theme.navKey(control, event, false);
    }

    contentItem: Label {
        text: control.displayText
        font: control.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Icon {
        x: control.width - width - Theme.unit * 1.5
        y: (control.height - height) / 2
        name: "chevronDown"
        size: Theme.px(22)
        weight: 2.4
    }

    background: Rectangle {
        radius: Theme.radiusField
        color: Theme.alpha(Theme.text, 0.13)
        border.width: control.visualFocus || control.popup.visible ? Math.max(2, Theme.px(2)) : 0
        border.color: Theme.alpha(Theme.pink, 0.7)
    }

    delegate: T.ItemDelegate {
        id: option
        required property int index
        required property var modelData
        readonly property bool unavailable: control.disabledIndexes.includes(index)
        width: ListView.view.width
        height: Theme.controlHeight
        enabled: !unavailable
        highlighted: control.highlightedIndex === index
        contentItem: Label {
            leftPadding: Theme.unit * 2
            text: typeof option.modelData === "object" && control.textRole ? option.modelData[control.textRole] : option.modelData
            verticalAlignment: Text.AlignVCenter
            font.weight: option.index === control.currentIndex ? Theme.weightStrong : Theme.weightBody
            color: option.unavailable ? Theme.textFaint : option.highlighted ? Theme.pinkInk : Theme.text
            elide: Text.ElideRight
        }
        background: Rectangle {
            radius: Theme.px(8)
            color: option.highlighted && !option.unavailable ? Theme.pink : "transparent"
        }
    }

    popup: T.Popup {
        y: control.height + Theme.unit / 2
        width: control.width
        height: Math.min(contentItem.implicitHeight + padding * 2, Theme.px(300))
        padding: Theme.unit / 2
        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: control.delegateModel
            currentIndex: control.highlightedIndex
        }
        background: Rectangle {
            radius: Theme.radiusField
            color: Theme.surfaceRaised
        }
    }
}
