// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Hint for a controller button. Uses the app's glyphs for the connected
// controller; falls back to a letter badge when those are not available.
Item {
    id: glyph

    // cross | moon | box | pyramid | l1 | r1 | l3 | r3 | options
    property string button: "cross"
    property real size: Theme.px(26)

    readonly property var letters: Vice.controllerStyle === "ps"
        ? ({ "cross": "✕", "moon": "○", "box": "□", "pyramid": "△", "l1": "L1", "r1": "R1", "l3": "L3", "r3": "R3", "options": "≡" })
        : ({ "cross": "A", "moon": "B", "box": "X", "pyramid": "Y", "l1": "L1", "r1": "R1", "l3": "L3", "r3": "R3", "options": "≡" })
    readonly property bool faceButton: ["cross", "moon", "box", "pyramid"].includes(button)

    implicitWidth: size
    implicitHeight: size

    Image {
        id: image
        anchors.fill: parent
        sourceSize: Qt.size(width, height)
        source: typeof root === "undefined" || !root.controllerButton ? ""
              : glyph.faceButton ? root.controllerButton(glyph.button) : "qrc:/icons/" + glyph.button + ".svg"
        visible: status === Image.Ready
    }

    Rectangle {
        anchors.fill: parent
        visible: !image.visible
        radius: height / 2
        color: Theme.text

        Label {
            anchors.centerIn: parent
            text: glyph.letters[glyph.button] || ""
            color: Theme.pinkInk
            font.pixelSize: glyph.size * (text.length > 1 ? 0.42 : 0.6)
            font.weight: Theme.weightButton
        }
    }
}
