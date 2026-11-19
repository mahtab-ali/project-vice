// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Eight boxes over one hidden text field, so typing, backspace, whole-code
// paste and input methods all behave like an ordinary field. With a
// controller: up/down change the current digit, left/right move between boxes.
FocusScope {
    id: entry

    property int digits: 8
    property alias text: field.text
    property bool invalid: false
    property bool masked: false
    readonly property bool complete: field.text.length === digits
    signal submitted()

    implicitWidth: row.implicitWidth
    implicitHeight: row.implicitHeight
    activeFocusOnTab: true
    opacity: enabled ? 1 : Theme.disabledOpacity
    Accessible.role: Accessible.EditableText
    Accessible.name: qsTr("%1-digit code").arg(digits)

    function clear() { field.text = "" }
    function setDigit(position, digit) {
        const chars = field.text.padEnd(position + 1, "0").split("");
        chars[position] = digit;
        field.text = chars.join("").slice(0, digits);
        field.cursorPosition = Math.min(position + 1, field.text.length);
    }
    function nudge(delta) {
        const position = Math.min(field.cursorPosition, digits - 1);
        const current = position < field.text.length ? parseInt(field.text[position]) : (delta > 0 ? -1 : 0);
        setDigit(position, String((current + delta + 10) % 10));
        field.cursorPosition = position;
    }

    TextInput {
        id: field
        // Present for input and accessibility, drawn by the boxes below
        anchors.fill: parent
        opacity: 0
        focus: true
        maximumLength: entry.digits
        inputMethodHints: Qt.ImhDigitsOnly | Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
        validator: RegularExpressionValidator { regularExpression: /[0-9]*/ }
        onTextEdited: entry.invalid = false
        // Whole-code paste: keep only ASCII digits from whatever was copied
        Keys.onPressed: (event) => {
            if (event.matches(StandardKey.Paste)) {
                field.text = "";
                field.paste();
                event.accepted = true;
            } else if (event.key === Qt.Key_Tab || event.key === Qt.Key_Backtab) {
                Theme.navKey(entry, event, true);
            } else if (event.key === Qt.Key_Up) {
                entry.nudge(1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Down) {
                entry.nudge(-1);
                event.accepted = true;
            } else if (event.key === Qt.Key_Right && cursorPosition >= Math.min(text.length, entry.digits - 1) && text.length >= entry.digits) {
                Theme.navKey(entry, event, false);
            } else if (event.key === Qt.Key_Left && cursorPosition === 0) {
                Theme.navKey(entry, event, false);
            }
        }
        Keys.onReturnPressed: if (entry.complete) entry.submitted(); else if (text.length < entry.digits) cursorPosition = text.length
    }

    Row {
        id: row
        spacing: Theme.unit * 1.25

        Repeater {
            model: entry.digits
            Rectangle {
                id: box
                required property int index
                readonly property bool current: entry.activeFocus && index === Math.min(field.cursorPosition, entry.digits - 1)
                width: Theme.px(66)
                height: Theme.px(68)
                radius: Theme.radiusField
                color: Theme.alpha(Theme.bgDeep, 0.6)
                border.width: current || entry.invalid ? Math.max(2, Theme.px(3)) : Theme.border
                border.color: entry.invalid ? Theme.error : current ? Theme.pink : Theme.alpha(Theme.text, 0.4)

                Label {
                    anchors.centerIn: parent
                    text: box.index < field.text.length ? (entry.masked ? "•" : field.text[box.index]) : ""
                    font.pixelSize: Theme.px(38)
                    font.weight: Theme.weightButton
                }

                TapHandler {
                    onTapped: {
                        entry.forceActiveFocus();
                        field.cursorPosition = Math.min(box.index, field.text.length);
                    }
                }
            }
        }
    }
}
