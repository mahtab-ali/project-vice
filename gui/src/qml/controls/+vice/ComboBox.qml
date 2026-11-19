// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The drop-down upstream's pages use, drawn as a Vice drop-down.
import QtQuick
import QtQuick.Templates
import vice
import vice.components as V

V.Dropdown {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false

    // As upstream: as wide as its longest option, so its dense grids still fit
    implicitContentWidthPolicy: ComboBox.WidestText
    implicitWidth: Math.max(Theme.px(170), implicitContentWidth + leftPadding + rightPadding)
}
