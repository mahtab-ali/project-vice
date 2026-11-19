// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
// Vice replacement for ../PSNLoginDialog.qml (same properties): sign in to
// read the account ID, or look it up by username.
import vice.screens as Screens

Screens.PsnSignIn {
    property bool login: true
    mode: login ? "account" : "lookup"
}
