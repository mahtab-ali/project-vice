// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// One crop of the key art, faded into the navy page. Shows nothing when the
// artwork file is absent (see ../artwork/SOURCE.md), leaving the plain page.
Item {
    id: art

    // Point of the image (0..1) that lands on a point of this item (0..1)
    property real imageX: 0.53
    property real imageY: 0.30
    property real atX: 0.73
    property real atY: 0.37
    // 1 = image height matches this item's height
    property real zoom: 1.08
    // Where the fade from navy ends, as a fraction of this item; 0 = no fade
    property real fadeLeft: 0.62
    // Everything left of this fraction is plain navy; the fade starts here
    property real fadeStart: 0
    property real fadeBottom: 0
    property real fadeTop: 0
    // Extra navy wash over the whole crop, for dense pages
    property real dim: 0
    property color fadeColor: Theme.bg

    readonly property bool available: image.status === Image.Ready
    clip: true

    Image {
        id: image
        source: "../artwork/key-art.jpg"
        asynchronous: true
        height: art.height * art.zoom
        width: height * 16 / 9
        x: art.width * art.atX - width * art.imageX
        y: Math.min(0, Math.max(art.height - height, art.height * art.atY - height * art.imageY))
        sourceSize.height: Math.min(1440, Math.round(height))
        smooth: true
        mipmap: true
    }

    Rectangle {
        anchors.fill: parent
        visible: art.available && art.dim > 0
        color: Theme.alpha(art.fadeColor, art.dim)
    }

    Rectangle {
        visible: art.available && art.fadeLeft > 0
        width: fade.x + 1
        height: parent.height
        color: art.fadeColor
    }

    Rectangle {
        id: fade
        visible: art.available && art.fadeLeft > 0
        x: Math.max(0, image.x, art.width * art.fadeStart)
        width: Math.max(0, art.width * art.fadeLeft - x)
        height: parent.height
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0; color: art.fadeColor }
            GradientStop { position: 0.35; color: Theme.alpha(art.fadeColor, 0.86) }
            GradientStop { position: 1; color: Theme.alpha(art.fadeColor, 0) }
        }
    }

    Rectangle {
        visible: art.available && art.fadeBottom > 0
        anchors.bottom: parent.bottom
        width: parent.width
        height: parent.height * art.fadeBottom
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(art.fadeColor, 0) }
            GradientStop { position: 0.8; color: art.fadeColor }
            GradientStop { position: 1; color: art.fadeColor }
        }
    }

    Rectangle {
        visible: art.available && art.fadeTop > 0
        width: parent.width
        height: parent.height * art.fadeTop
        gradient: Gradient {
            GradientStop { position: 0; color: Theme.alpha(art.fadeColor, 0.75) }
            GradientStop { position: 1; color: Theme.alpha(art.fadeColor, 0) }
        }
    }
}
