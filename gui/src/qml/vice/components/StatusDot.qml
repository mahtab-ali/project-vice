// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import ".."

Rectangle {
    // on | rest | off | error
    property string state: "off"
    width: Theme.px(14)
    height: width
    radius: width / 2
    color: state === "on" ? Theme.online : state === "error" ? Theme.error : state === "rest" ? Theme.warning : Theme.textFaint
}
