// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// One-of-few choice. Left/right pick; up/down move on.
FocusScope {
    id: control

    property var model: []
    property int currentIndex: 0
    property int textSize: Theme.textLabel
    signal activated(int index)

    implicitWidth: Theme.px(360)
    implicitHeight: Theme.controlHeight
    activeFocusOnTab: true
    opacity: enabled ? 1 : Theme.disabledOpacity
    Accessible.role: Accessible.PageTabList

    function pick(index) {
        if (index < 0 || index >= model.length || index === currentIndex)
            return;
        currentIndex = index;
        activated(index);
    }

    Keys.onLeftPressed: pick(currentIndex - 1)
    Keys.onRightPressed: pick(currentIndex + 1)
    Keys.onPressed: (event) => Theme.navKey(control, event, true)

    Rectangle {
        id: frame
        anchors.fill: parent
        radius: height / 2
        color: Theme.alpha(Theme.text, 0.13)
        border.width: control.activeFocus && (Theme.keyboardNav || Theme.handheld) ? Math.max(2, Theme.px(2)) : 0
        border.color: Theme.alpha(Theme.pink, 0.7)
        clip: true

        Row {
            anchors.fill: parent
            Repeater {
                model: control.model
                Item {
                    id: segment
                    required property int index
                    required property string modelData
                    readonly property bool current: index === control.currentIndex
                    width: frame.width / control.model.length
                    height: frame.height

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: frame.border.width
                        radius: height / 2
                        color: segment.current ? Theme.pink : "transparent"
                    }

                    Label {
                        anchors.centerIn: parent
                        text: segment.modelData
                        font.weight: Theme.weightStrong
                        font.pixelSize: control.textSize
                        color: segment.current ? Theme.pinkInk : Theme.text
                        Accessible.role: Accessible.PageTab
                        Accessible.name: text
                    }

                    TapHandler {
                        onTapped: {
                            control.forceActiveFocus();
                            control.pick(segment.index);
                        }
                    }
                }
            }
        }
    }
}
