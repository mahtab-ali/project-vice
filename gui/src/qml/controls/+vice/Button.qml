// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// The button upstream's pages use, drawn as a Vice button. Upstream's extra
// properties are kept so its pages load unchanged; focus moves in Vice's
// own order (Theme.navKey), which also works where Qt's tab chain skips buttons.
import QtQuick
import "../vice/components" as V

V.Button {
    property bool firstInFocusChain: false
    property bool lastInFocusChain: false
    property bool sendOutput: false

    kind: "outline"
    size: "sm"
}
