// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../PSNTokenDialog.qml (same properties): PSN sign-in
// for remote play and PIN-less pairing.
import "vice/screens" as Screens

Screens.PsnSignIn {
    property var psnurl
    mode: "token"
}
