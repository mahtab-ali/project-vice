// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Templates as T
import ".."

T.TextField {
    id: control

    property bool invalid: false

    implicitWidth: Theme.px(420)
    implicitHeight: Theme.buttonMd
    leftPadding: Theme.unit * 2.5
    rightPadding: Theme.unit * 2.5
    verticalAlignment: TextInput.AlignVCenter
    color: Theme.text
    selectionColor: Theme.pink
    selectedTextColor: Theme.pinkInk
    placeholderTextColor: Theme.textFaint
    font.family: Theme.family
    font.pixelSize: Theme.textHeading
    font.weight: Theme.weightBody
    opacity: enabled ? 1 : Theme.disabledOpacity

    // On a handheld there is no keyboard until the on-screen one is asked for
    onActiveFocusChanged: if (activeFocus && !readOnly && Theme.handheld) Qt.inputMethod.show()

    Keys.onUpPressed: (event) => Theme.navKey(control, event, true)
    Keys.onDownPressed: (event) => Theme.navKey(control, event, true)
    Keys.onTabPressed: (event) => Theme.navKey(control, event, true)
    Keys.onBacktabPressed: (event) => Theme.navKey(control, event, true)

    Label {
        anchors.fill: parent
        leftPadding: control.leftPadding
        verticalAlignment: Text.AlignVCenter
        visible: !control.text && !control.preeditText
        text: control.placeholderText
        font: control.font
        color: control.placeholderTextColor
    }

    background: Rectangle {
        radius: Theme.radiusField
        color: Theme.alpha(Theme.bgDeep, 0.6)
        border.width: control.invalid || control.activeFocus ? Math.max(2, Theme.px(2)) : Theme.border
        border.color: control.invalid ? Theme.error : control.activeFocus ? Theme.pink : Theme.alpha(Theme.text, 0.4)
    }
}
