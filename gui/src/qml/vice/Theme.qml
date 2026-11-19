// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
pragma Singleton
import QtQuick

// Every colour, size, radius, opacity and duration the Vice UI uses.
// Screens and components never hard-code one. Sizes are written for a
// 1280x720 window and follow `scale`, which Main.qml sets from the window.
QtObject {
    readonly property string appName: "Project Vice"

    property real scale: 1
    // Set from Vice.reduceMotion; turns every transition into a cut
    property bool reducedMotion: false
    function px(n) { return Math.round(n * scale) }
    // Accepts a colour or a "#rrggbb" string
    function alpha(c, a) {
        const k = typeof c === "string" ? Qt.darker(c, 1) : c;
        return Qt.rgba(k.r, k.g, k.b, a);
    }
    function dur(ms) { return reducedMotion ? 0 : ms }

    // Colour
    readonly property color bg: "#131229"
    readonly property color bgDeep: "#0E0D20"
    readonly property color surface: alpha("#24223F", 0.9)
    // Borderless tiles and rows sit on this: a soft navy wash, no outline
    readonly property color surfaceSoft: alpha("#16152E", 0.58)
    readonly property color highlight: alpha("#F8AEC0", 0.18)
    readonly property color divider: alpha("#FBF4EC", 0.1)
    readonly property color surfaceSolid: "#1B1A33"
    readonly property color surfaceRaised: "#26244A"
    readonly property color line: alpha("#B9A8F0", 0.28)
    readonly property color lineStrong: alpha("#C9B8FF", 0.62)
    readonly property color text: "#FBF4EC"
    readonly property color textMuted: "#BDB7D2"
    readonly property color textFaint: "#8782A0"
    readonly property color pink: "#F8AEC0"
    readonly property color pinkPressed: "#E592A8"
    readonly property color pinkInk: "#11122B"
    readonly property color dash: "#E785CD"
    readonly property color success: "#8FE39A"
    readonly property color warning: "#F6C768"
    readonly property color error: "#F2707C"
    readonly property color info: "#B8B2F7"
    readonly property color online: "#7BE783"
    readonly property color scrim: alpha("#0B0A1C", 0.72)
    readonly property real disabledOpacity: 0.45

    function severityColor(severity) {
        switch (severity) {
        case "success": return success;
        case "warning": return warning;
        case "error": return error;
        default: return info;
        }
    }

    // Type: Rubik, heavy for display, medium for reading
    readonly property FontLoader fontLoader: FontLoader { source: "fonts/Rubik.ttf" }
    readonly property string family: fontLoader.status === FontLoader.Ready ? fontLoader.font.family : Qt.application.font.family
    // The wordmark is plain text set in Bungee, an open-licensed signage face
    readonly property FontLoader wordmarkLoader: FontLoader { source: "fonts/Bungee.ttf" }
    readonly property string wordmarkFamily: wordmarkLoader.status === FontLoader.Ready ? wordmarkLoader.font.family : family
    readonly property int textHero: px(66)
    readonly property int textDisplay: px(54)
    readonly property int textHeadline: px(40)
    readonly property int textTitle: px(28)
    readonly property int textHeading: px(22)
    readonly property int textBody: px(19)
    readonly property int textLabel: px(17)
    readonly property int textSmall: px(14)
    readonly property int weightDisplay: Font.Black
    readonly property int weightButton: Font.ExtraBold
    readonly property int weightStrong: Font.Bold
    readonly property int weightBody: Font.Medium

    // Spacing is always a multiple of unit
    readonly property int unit: px(8)
    readonly property int margin: px(48)

    // Controls
    readonly property int buttonLg: px(68)
    readonly property int buttonMd: px(52)
    readonly property int buttonSm: px(40)
    readonly property int controlHeight: px(44)
    readonly property int headerHeight: px(96)
    readonly property int footerHeight: px(64)
    readonly property int radiusPanel: px(18)
    readonly property int radiusDialog: px(28)
    readonly property int radiusField: px(12)
    readonly property int border: Math.max(1, px(1.5))
    readonly property int focusWidth: Math.max(2, px(3))
    readonly property int dialogWidth: px(560)
    readonly property int toastWidth: px(420)

    // Motion, ms
    readonly property int fast: 120
    readonly property int normal: 200
    // Notifications
    readonly property int toastDuration: 6000
    readonly property int toastsVisible: 3
    readonly property int toastsVisibleInStream: 1
    readonly property int toastsQueued: 8

    // ---- Focus visibility -----------------------------------------------------
    // Focus rings are for keyboard and controller use. They appear once a
    // navigation key is pressed and go away again when the pointer moves, so
    // a mouse user never sees a stray ring on whatever happens to have focus.
    property bool keyboardNav: false
    // A handheld with built-in controls (Steam Deck): focus is always shown,
    // and effects that cost GPU time for looks alone are skipped.
    property bool handheld: false
    readonly property bool richEffects: !handheld && !reducedMotion
    // Room kept clear at the top when the app draws under the window's title bar
    property int topInset: 0

    // ---- Focus order ----------------------------------------------------------
    // Qt's own tab chain skips buttons on macOS unless a system setting is on,
    // so the D-pad order is worked out here instead: every visible, enabled
    // item that takes tab focus, in the order it is declared.

    function focusables(rootItem, out) {
        let kids = [];
        for (let i = 0; i < rootItem.children.length; ++i)
            kids.push(rootItem.children[i]);
        // A list's delegates are created in any order; read them top to bottom
        if (rootItem.parent && rootItem.parent.contentItem === rootItem)
            kids.sort((a, b) => a.y - b.y || a.x - b.x);
        for (const kid of kids) {
            if (!kid.visible || !kid.enabled)
                continue;
            if (kid.activeFocusOnTab === true)
                out.push(kid);
            else
                focusables(kid, out);
        }
        return out;
    }

    // The area focus moves within: a dialog or menu that traps focus, else the whole window
    function focusRoot(item) {
        let root = item;
        while (root.parent && root.focusTrap !== true)
            root = root.parent;
        return root;
    }

    function firstFocusable(rootItem) {
        const list = focusables(rootItem, []);
        return list.length ? list[0] : null;
    }

    // Moves focus to the previous or next control, wrapping at the ends
    function moveFocus(item, forward) {
        const list = focusables(focusRoot(item), []);
        if (!list.length)
            return false;
        let at = list.indexOf(item);
        if (at < 0)
            at = list.findIndex(candidate => candidate.activeFocus);
        const next = list[(at + (forward ? 1 : -1) + list.length) % list.length];
        next.forceActiveFocus(Qt.TabFocusReason);
        return true;
    }

    // Arrow keys for a control. Controls that use left/right themselves
    // (sliders, segmented controls) pass ownsHorizontal.
    function navKey(item, event, ownsHorizontal) {
        let forward;
        switch (event.key) {
        case Qt.Key_Up: forward = false; break;
        case Qt.Key_Down: forward = true; break;
        case Qt.Key_Left: if (ownsHorizontal) return; forward = false; break;
        case Qt.Key_Right: if (ownsHorizontal) return; forward = true; break;
        // Tab follows the same order, so it also stays inside a dialog
        case Qt.Key_Tab: forward = true; break;
        case Qt.Key_Backtab: forward = false; break;
        default: return;
        }
        keyboardNav = true;
        moveFocus(item, forward);
        event.accepted = true;
    }
}
