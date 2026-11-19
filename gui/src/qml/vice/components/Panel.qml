// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

// A soft navy wash behind a group of content. No outline: only a selected
// panel gets the pink edge.
Rectangle {
    property bool selected: false
    radius: Theme.radiusPanel
    color: Theme.surfaceSoft
    border.width: selected ? Math.max(2, Theme.px(3)) : 0
    border.color: Theme.pink
}
