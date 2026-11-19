// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Shapes
import ".."

// Line icons drawn on a 24-unit grid, so they stay sharp at any scale and
// take any colour. Add a path here rather than shipping an image.
Item {
    id: icon

    property string name
    property color color: Theme.text
    property real size: Theme.px(24)
    property real weight: 2

    readonly property var solid: ({ "console": true, "console4": true, "dot": true })
    readonly property var paths: ({
        "gamepad": "M6 11h4 M8 9v4 M15 12h.01 M18 10h.01 M17.32 5H6.68a4 4 0 0 0-3.98 3.59C2.6 9.42 2 14.46 2 16a3 3 0 0 0 3 3c1 0 1.5-.5 2-1l1.41-1.41A2 2 0 0 1 9.83 16h4.34a2 2 0 0 1 1.42.59L17 18c.5.5 1 1 2 1a3 3 0 0 0 3-3c0-1.54-.6-6.58-.7-7.41A4 4 0 0 0 17.32 5z",
        "wifi": "M5 12.55a11 11 0 0 1 14.08 0 M1.42 9a16 16 0 0 1 21.16 0 M8.53 16.11a6 6 0 0 1 6.95 0 M12 20h.01",
        "monitor": "M4 3h16a2 2 0 0 1 2 2v10a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M8 21h8 M12 17v4",
        "pulse": "M22 12h-4l-3 9L9 3l-3 9H2",
        "plus": "M12 5v14 M5 12h14",
        "check": "M20 6L9 17l-5-5",
        "close": "M18 6L6 18 M6 6l12 12",
        "minus": "M5 12h14",
        "square": "M6 6h12v12H6z",
        "bang": "M12 7v6 M12 17h.01",
        "question": "M9.1 9a3 3 0 0 1 5.8 1c0 2-3 3-3 3 M12 17h.01",
        "i": "M12 11v6 M12 7h.01",
        "chevronRight": "M9 18l6-6-6-6",
        "chevronDown": "M6 9l6 6 6-6",
        "arrowRight": "M5 12h14 M13 6l6 6-6 6",
        "user": "M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2 M12 3a4 4 0 1 0 0 8 4 4 0 0 0 0-8z",
        "image": "M5 3h14a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2z M8.5 7a1.5 1.5 0 1 0 0 3 1.5 1.5 0 0 0 0-3z M21 15l-5-5L5 21",
        "folder": "M22 19a2 2 0 0 1-2 2H4a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h5l2 3h9a2 2 0 0 1 2 2z",
        "volume": "M11 5L6 9H2v6h4l5 4V5z M15.54 8.46a5 5 0 0 1 0 7.07 M19.07 4.93a10 10 0 0 1 0 14.14",
        "mic": "M12 1a3 3 0 0 0-3 3v8a3 3 0 0 0 6 0V4a3 3 0 0 0-3-3z M19 10v2a7 7 0 0 1-14 0v-2 M12 19v4",
        "sliders": "M3 6h10 M17 6h4 M3 12h4 M11 12h10 M3 18h12 M19 18h2 M15 4v4 M9 10v4 M17 16v4",
        "replay": "M1 4v6h6 M3.51 15a9 9 0 1 0 2.13-9.36L1 10",
        "signal": "M5 20v-3 M10 20v-7 M15 20V9 M20 20V4",
        "ethernet": "M4 6h16a1 1 0 0 1 1 1v9a1 1 0 0 1-1 1h-3v2H7v-2H4a1 1 0 0 1-1-1V7a1 1 0 0 1 1-1z M8 6v4 M12 6v4 M16 6v4",
        "info": "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z M12 11v5 M12 7.500h.01",
        "clock": "M12 2a10 10 0 1 0 0 20 10 10 0 0 0 0-20z M12 6v6l4 2",
        "history": "M3 3v5h5 M3.05 13A9 9 0 1 0 6 5.3L3 8 M12 7v5l4 2",
        "search": "M11 3a8 8 0 1 0 0 16 8 8 0 0 0 0-16z M21 21l-4.35-4.35",
        "linkOff": "M18.84 12.25l1.72-1.71a5 5 0 0 0-7.07-7.07l-1.72 1.71 M5.17 11.75l-1.71 1.71a5 5 0 0 0 7.07 7.07l1.71-1.71 M8 2v3 M2 8h3 M16 19v3 M19 16h3",
        "plugOff": "M9 2v4 M15 2v2.5 M6 8h12v3a6 6 0 0 1-2.3 4.7 M12 17v5 M8.2 15.800A6 6 0 0 1 6 11V8 M3 3l18 18",
        "power": "M18.36 6.64a9 9 0 1 1-12.73 0 M12 2v10",
        // PS5: the two tall white plates around a dark core. PS4: the slanted two-tier slab.
        "console": "M10.3 21.6 8.800 21.200C8.500 15 8 8.200 7 2.500 6.900 1.800 7.600 1.400 8.100 1.800L10.300 3.600Z M13.700 21.600 15.200 21.200C15.500 15 16 8.200 17 2.500 17.100 1.800 16.400 1.400 15.900 1.800L13.700 3.600Z M11.200 4.200H12.800V21H11.200Z M8.600 22.100H15.400V22.900H8.600Z",
        "console4": "M2.500 8.500H18.500L21.500 11.700H5.500Z M2.500 12.600H18.500L21.500 15.800H5.500Z",
        "dot": "M12 6a6 6 0 1 0 0 12 6 6 0 0 0 0-12z"
    })

    implicitWidth: size
    implicitHeight: size

    Shape {
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: icon.size / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            readonly property bool solid: icon.solid[icon.name] === true
            strokeColor: solid ? "transparent" : icon.color
            strokeWidth: icon.weight
            fillColor: solid ? icon.color : "transparent"
            capStyle: ShapePath.RoundCap
            joinStyle: ShapePath.RoundJoin
            PathSvg { path: icon.paths[icon.name] || "" }
        }
    }
}
