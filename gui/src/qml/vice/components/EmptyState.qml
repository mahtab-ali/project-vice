// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// Nothing to show yet: say why and offer the next step.
Column {
    id: empty

    property string iconName: "console"
    property color iconColor: Theme.pink
    property string title
    property string body
    property string note
    property string primaryText
    property string secondaryText
    property bool secondaryBusy: false
    property alias primaryButton: primary
    signal primary()
    signal secondary()

    spacing: Theme.unit * 1.5
    width: Theme.px(520)

    Icon {
        anchors.horizontalCenter: parent.horizontalCenter
        name: empty.iconName
        size: Theme.px(88)
        weight: 1.4
        color: empty.iconColor
    }

    Label {
        width: parent.width
        text: empty.title
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
        font.pixelSize: Theme.textHeadline
        font.weight: Theme.weightDisplay
    }

    Label {
        width: parent.width
        visible: text
        text: empty.body
        horizontalAlignment: Text.AlignHCenter
        wrapMode: Text.Wrap
    }

    Item { width: 1; height: Theme.unit }

    Button {
        id: primary
        anchors.horizontalCenter: parent.horizontalCenter
        visible: empty.primaryText
        width: Theme.px(400)
        text: empty.primaryText
        onTriggered: empty.primary()
    }

    Button {
        anchors.horizontalCenter: parent.horizontalCenter
        visible: empty.secondaryText
        kind: "text"
        text: empty.secondaryText
        busy: empty.secondaryBusy
        onTriggered: empty.secondary()
    }

    Label {
        width: parent.width
        visible: text
        text: empty.note
        horizontalAlignment: Text.AlignHCenter
        font.pixelSize: Theme.textLabel
        color: Theme.textMuted
    }
}
