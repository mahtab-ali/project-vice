// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Shapes
import ".."

// Indeterminate progress: never implies a percentage or a time estimate.
Item {
    id: spinner

    property real size: Theme.px(24)
    property color color: Theme.pink
    property real weight: 3

    implicitWidth: size
    implicitHeight: size

    Shape {
        id: arc
        width: 24
        height: 24
        anchors.centerIn: parent
        scale: spinner.size / 24
        preferredRendererType: Shape.CurveRenderer

        ShapePath {
            strokeColor: Theme.alpha(spinner.color, 0.25)
            strokeWidth: spinner.weight
            fillColor: "transparent"
            PathAngleArc { centerX: 12; centerY: 12; radiusX: 10; radiusY: 10; sweepAngle: 360 }
        }
        ShapePath {
            strokeColor: spinner.color
            strokeWidth: spinner.weight
            fillColor: "transparent"
            capStyle: ShapePath.RoundCap
            PathAngleArc { centerX: 12; centerY: 12; radiusX: 10; radiusY: 10; startAngle: -90; sweepAngle: 80 }
        }

        RotationAnimator on rotation {
            from: 0; to: 360
            duration: 1100
            loops: Animation.Infinite
            running: spinner.visible && !Theme.reducedMotion
        }
    }
}
