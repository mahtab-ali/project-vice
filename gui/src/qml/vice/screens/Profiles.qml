// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Shapes

import org.streetpea.chiaking

import ".."
import "../components" as V

// Game profiles are upstream's settings profiles: each one is a full set of
// settings. Switching here switches all of them; nothing is detected per game.
V.Page {
    id: page

    tab: "settings"
    showStatus: false
    initialFocus: profileBox
    artwork.preset: "palms"
    hints: [{ button: "cross", text: qsTr("Select") }, { button: "moon", text: qsTr("Back") }]
    onBack: stack.pop()

    readonly property var profiles: Chiaki.settings.profiles.filter(p => p !== "create new profile")
    readonly property string currentName: Chiaki.settings.currentProfile || "default"
    readonly property string savedMode: Vice.modeOf(Chiaki.settings.videoPreset)
    property string mode: savedMode
    onSavedModeChanged: mode = savedMode
    readonly property bool dirty: mode !== savedMode
    property bool naming: false
    // Stick tuning belongs to the settings profile in use
    readonly property var sticks: Vice.sticksFor(Chiaki.settings.currentProfile)
    function setSticks(change) {
        Vice.setSticksFor(Chiaki.settings.currentProfile, Object.assign({}, sticks, change));
    }
    readonly property var pad: Chiaki.controllers.length ? Chiaki.controllers[0] : null

    function saveProfile() {
        const preset = Vice.presetFor(mode);
        Chiaki.settings.videoPreset = preset;
        if (Chiaki.settings.videoPreset === preset)
            Vice.notify({ key: "profile-saved", severity: "success", title: qsTr("Profile saved"), body: qsTr("%1 now starts in %2 mode.").arg(currentName).arg(Vice.modeText(mode)) });
        else
            Vice.notify({ key: "profile-failed", severity: "error", title: qsTr("Profile not saved"), body: qsTr("The picture preset kept its old value."), sticky: true });
    }
    function createProfile() {
        const name = nameField.text.trim();
        if (!name || profiles.includes(name))
            return;
        Chiaki.settings.currentProfile = name;
        naming = false;
        nameField.text = "";
        profileBox.forceActiveFocus(Qt.TabFocusReason);
    }
    function deleteProfile() {
        const name = currentName;
        Vice.ask({
            key: "delete-profile",
            severity: "question",
            title: qsTr("Delete %1?").arg(name),
            body: qsTr("Its settings are removed. Paired consoles are kept."),
            primary: { text: qsTr("Keep profile") },
            secondary: { text: qsTr("Delete"), danger: true, run: () => { Chiaki.settings.currentProfile = ""; Chiaki.settings.deleteProfile(name); } },
            cancel: "primary"
        });
    }

    V.Label {
        id: headline
        x: Theme.margin
        y: -Theme.px(4)
        text: qsTr("Game profiles")
        font.pixelSize: Theme.textDisplay
        font.weight: Theme.weightDisplay
    }

    Row {
        id: profileRow
        anchors { left: headline.left; top: headline.bottom; topMargin: Theme.px(2) }
        spacing: Theme.unit * 2.5

        V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Profile"); font.pixelSize: Theme.textHeading; font.weight: Theme.weightStrong }
        V.Dropdown {
            id: profileBox
            width: Theme.px(290)
            model: page.profiles
            currentIndex: Math.max(0, page.profiles.indexOf(page.currentName))
            onActivated: (index) => Chiaki.settings.currentProfile = model[index] === "default" ? "" : model[index]
            Accessible.name: qsTr("Profile")
        }
        V.Button {
            visible: !page.naming
            kind: "text"
            iconName: "plus"
            text: qsTr("New profile")
            onTriggered: { page.naming = true; nameField.forceActiveFocus(Qt.TabFocusReason) }
        }
        V.TextInput {
            id: nameField
            visible: page.naming
            width: Theme.px(220)
            implicitHeight: Theme.controlHeight
            font.pixelSize: Theme.textBody
            placeholderText: qsTr("Profile name")
            invalid: page.profiles.includes(text.trim())
            Keys.onReturnPressed: page.createProfile()
            Keys.onEscapePressed: page.naming = false
            Accessible.name: placeholderText
        }
        V.Button {
            visible: page.naming
            size: "sm"
            anchors.verticalCenter: parent.verticalCenter
            text: qsTr("Create")
            enabled: nameField.text.trim().length > 0 && !nameField.invalid
            onTriggered: page.createProfile()
        }
        V.Button {
            visible: !page.naming && page.currentName !== "default"
            kind: "text"
            text: qsTr("Delete")
            onTriggered: page.deleteProfile()
        }
    }

    V.Panel {
        id: controls
        anchors { left: parent.left; leftMargin: Theme.px(44); top: profileRow.bottom; topMargin: Theme.px(18); bottom: parent.bottom; bottomMargin: Theme.px(30) }
        width: Theme.px(730)

        component FormRow: Item {
            property alias label: rowLabel.text
            default property alias control: rowSlot.data
            width: controls.width - Theme.px(68)
            height: Theme.px(41)
            V.Label { id: rowLabel; anchors.verticalCenter: parent.verticalCenter; font.pixelSize: Theme.textHeading; font.weight: Theme.weightStrong }
            Row { id: rowSlot; x: Theme.px(256); anchors.verticalCenter: parent.verticalCenter; spacing: Theme.unit * 3 }
        }

        Column {
            x: Theme.px(34)
            y: Theme.px(12)
            spacing: Theme.px(2)

            V.Label { text: qsTr("Controls"); font.pixelSize: Theme.px(34); font.weight: Theme.weightDisplay }

            FormRow {
                label: qsTr("Mode")
                V.Segmented {
                    width: Theme.px(346)
                    implicitHeight: Theme.px(36)
                    model: [qsTr("Game"), qsTr("Quality")]
                    // Neither is lit while a custom picture preset is in use
                    currentIndex: page.mode === "game" ? 0 : page.mode === "quality" ? 1 : -1
                    onActivated: (index) => page.mode = index === 0 ? "game" : "quality"
                    Accessible.name: qsTr("Mode")
                }
            }
            FormRow {
                label: qsTr("Stick preset")
                V.Dropdown {
                    width: Theme.px(346); implicitHeight: Theme.px(36)
                    model: Vice.stickPresets.map(p => p.text)
                    currentIndex: Math.max(0, Vice.stickPresets.findIndex(p => p.id === page.sticks.preset))
                    onActivated: (index) => {
                        const preset = Vice.stickPresets[index];
                        // "Custom" keeps the values that are there; the others bring their own
                        page.setSticks(preset.id === "custom" ? { preset: "custom" } : { preset: preset.id, left: preset.left, right: preset.right, curve: preset.curve });
                    }
                    Accessible.name: qsTr("Stick preset")
                }
            }
            FormRow {
                label: qsTr("Left stick deadzone")
                V.Slider {
                    width: Theme.px(346); implicitHeight: Theme.px(36)
                    from: 0; to: 50; stepSize: 1
                    value: page.sticks.left
                    onMoved: page.setSticks({ preset: "custom", left: Math.round(value) })
                    Accessible.name: qsTr("Left stick deadzone")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; text: page.sticks.left + "%"; font.weight: Theme.weightStrong }
            }
            FormRow {
                label: qsTr("Right stick deadzone")
                V.Slider {
                    width: Theme.px(346); implicitHeight: Theme.px(36)
                    from: 0; to: 50; stepSize: 1
                    value: page.sticks.right
                    onMoved: page.setSticks({ preset: "custom", right: Math.round(value) })
                    Accessible.name: qsTr("Right stick deadzone")
                }
                V.Label { anchors.verticalCenter: parent.verticalCenter; text: page.sticks.right + "%"; font.weight: Theme.weightStrong }
            }
            FormRow {
                label: qsTr("Response curve")
                V.Dropdown {
                    width: Theme.px(346); implicitHeight: Theme.px(36)
                    model: [qsTr("Linear"), qsTr("Smooth"), qsTr("Precise")]
                    currentIndex: page.sticks.curve
                    onActivated: (index) => page.setSticks({ preset: "custom", curve: index })
                    Accessible.name: qsTr("Response curve")
                }
            }
        }

        // What the chosen deadzone and curve do to stick travel, drawn from the same formula the app applies
        Item {
            id: curve
            anchors { left: parent.left; leftMargin: Theme.px(200); right: parent.right; rightMargin: Theme.px(90); bottom: parent.bottom; bottomMargin: Theme.px(34) }
            height: Theme.px(66)
            readonly property real deadzone: page.sticks.left / 100
            readonly property real exponent: page.sticks.curve === 1 ? 1.5 : page.sticks.curve === 2 ? 2.0 : 1.0

            V.Label { anchors { right: parent.left; rightMargin: Theme.unit; verticalCenter: parent.verticalCenter } text: qsTr("Response"); font.pixelSize: Theme.textSmall; color: Theme.textMuted }
            V.Label { anchors { top: parent.bottom; topMargin: Theme.px(4); horizontalCenter: parent.horizontalCenter } text: qsTr("Left stick input"); font.pixelSize: Theme.textSmall; color: Theme.textMuted }
            Rectangle { width: 1; height: parent.height; color: Theme.alpha(Theme.text, 0.6) }
            Rectangle { anchors.bottom: parent.bottom; width: parent.width; height: 1; color: Theme.alpha(Theme.text, 0.6) }
            Shape {
                anchors.fill: parent
                preferredRendererType: Shape.CurveRenderer
                ShapePath {
                    strokeColor: Theme.dash
                    strokeWidth: Math.max(2, Theme.px(2.5))
                    fillColor: "transparent"
                    joinStyle: ShapePath.RoundJoin
                    PathPolyline {
                        path: {
                            const points = [];
                            for (let i = 0; i <= 40; ++i) {
                                const input = i / 40;
                                const output = input <= curve.deadzone ? 0 : Math.pow((input - curve.deadzone) / (1 - curve.deadzone), curve.exponent);
                                points.push(Qt.point(input * curve.width, (1 - output) * curve.height));
                            }
                            return points;
                        }
                    }
                }
            }
        }
    }

    V.Panel {
        anchors { left: controls.right; leftMargin: Theme.px(16); top: controls.top; bottom: controls.bottom }
        width: Theme.px(390)

        Column {
            anchors { fill: parent; margins: Theme.px(24) }
            spacing: Theme.px(10)

            Row {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: Theme.unit * 1.5
                V.StatusDot { anchors.verticalCenter: parent.verticalCenter; state: page.pad ? "on" : "off" }
                V.Label {
                    anchors.verticalCenter: parent.verticalCenter
                    font.pixelSize: Theme.textHeading
                    font.weight: Theme.weightStrong
                    text: !page.pad ? qsTr("No controller connected")
                        : (page.pad.dualSenseEdge ? "DualSense Edge" : page.pad.dualSense ? "DualSense" : page.pad.handheld ? qsTr("Built-in controls") : qsTr("Controller")) + "  ·  " + qsTr("Connected")
                }
            }

            V.Icon {
                anchors.horizontalCenter: parent.horizontalCenter
                name: "gamepad"
                size: Math.min(parent.width, parent.height - Theme.px(190))
                weight: 0.7
                color: page.pad ? Theme.text : Theme.textFaint
            }

            V.Button {
                width: parent.width
                text: qsTr("Button mapping")
                font.pixelSize: Theme.px(26)
                onTriggered: root.showControllerMappingDialog()
            }
            V.Button {
                width: parent.width
                kind: "outline"
                implicitHeight: Theme.px(44)
                text: qsTr("Restore defaults")
                // The default picture preset; mapping has its own reset in its dialog
                onTriggered: page.mode = Vice.modeOf(1)
            }
        }
    }

    Row {
        parent: page
        anchors { left: parent.left; leftMargin: Theme.margin; bottom: parent.bottom; bottomMargin: (Theme.footerHeight - height) / 2 }
        spacing: Theme.unit * 1.5
        V.Icon { anchors.verticalCenter: parent.verticalCenter; name: "gamepad"; size: Theme.px(26); weight: 1.8 }
        V.Label { anchors.verticalCenter: parent.verticalCenter; text: qsTr("Applies when this profile is selected"); font.pixelSize: Theme.textLabel }
    }

    footerExtra: V.Button {
        width: Theme.px(230)
        implicitHeight: Theme.px(44)
        text: qsTr("Save profile")
        enabled: page.dirty && page.mode !== "custom"
        onTriggered: page.saveProfile()
    }
}
