// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick
import QtQuick.Controls

import org.streetpea.chiaking

import ".."
import "../components" as V

// PSN sign-in, in three shapes that share one page:
//   token    signs in for remote play and PIN-less pairing (was PSNTokenDialog)
//   account  signs in only to read the account ID (was PSNLoginDialog, login)
//   lookup   finds the account ID from a public username (was PSNLoginDialog, lookup)
// The calls into the backend are upstream's; only the page is new.
V.Page {
    id: page

    property string mode: "token"
    property bool expired: false
    // account and lookup hand the ID back through this
    property var callback: null

    // Upstream opens the system browser on macOS and Linux and signs in inside the app elsewhere
    property bool embedded: Qt.platform.os !== "linux" && Qt.platform.os !== "osx"
    property Item web: null
    property bool closing: false
    property string link
    property bool busy: false
    property string status
    property string failure
    readonly property bool signedIn: Chiaki.settings.psnAuthToken ? true : false

    tab: "consoles"
    showStatus: false
    initialFocus: mode === "lookup" ? usernameField : embedded && web ? browserButton : openButton
    artwork.fadeLeft: 0.7
    onBack: close()

    function close() {
        Vice.cancelOp("psn");
        // As upstream: leave the embedded browser's cache clean before going
        if (web) {
            closing = true;
            if (Chiaki.settings.remotePlayAsk)
                Chiaki.clearCookies(web.profile);
            web.profile.clearHttpCache();
        } else {
            root.closeDialog();
        }
    }

    function openLink() {
        link = Chiaki.openPsnLink() || "";
        copyLink();
        urlField.forceActiveFocus(Qt.TabFocusReason);
    }
    function copyLink() {
        if (!link)
            return;
        clipboard.text = link;
        clipboard.selectAll();
        clipboard.copy();
    }

    function submit(redirect) {
        if (busy || !String(redirect).trim())
            return;
        const id = Vice.beginOp("psn");
        busy = true;
        failure = "";
        status = qsTr("Checking with PlayStation Network…");
        if (mode === "account") {
            Chiaki.handlePsnLoginRedirect(redirect);   // answers through psnLoginAccountIdDone / Error
            return;
        }
        Chiaki.initPsnAuth(redirect, function(msg, ok, done) {
            if (!Vice.isCurrent("psn", id))
                return;
            if (ok)
                Chiaki.settings.remotePlayAsk = false;
            if (!done) {
                page.status = msg;
                return;
            }
            page.busy = false;
            // Signed in only when the backend actually holds a token
            if (ok || page.signedIn) {
                Vice.notify({ key: "psn-signed-in", severity: "success", iconName: "user", title: qsTr("Signed in to PSN"), body: qsTr("Consoles on your account now pair without a PIN.") });
                root.showMainView();
            } else {
                page.failure = msg || qsTr("PlayStation Network did not accept that address.");
            }
        });
    }

    function lookup() {
        const username = usernameField.text.trim();
        if (!username || busy)
            return;
        const id = Vice.beginOp("psn");
        busy = true;
        failure = "";
        const request = new XMLHttpRequest();
        request.onreadystatechange = function() {
            if (request.readyState !== XMLHttpRequest.DONE || !Vice.isCurrent("psn", id))
                return;
            page.busy = false;
            let response = null;
            try { response = JSON.parse(request.response); } catch (e) { }
            if (response && response["encoded_id"]) {
                if (page.callback)
                    page.callback(response["encoded_id"]);
                root.closeDialog();
            } else {
                page.failure = response && response["error"] ? qsTr("Lookup failed: %1").arg(response["error"]) : qsTr("The lookup service did not answer. Try signing in instead.");
            }
        };
        request.open("GET", "https://psn.flipscreen.games/search.php?username=%1".arg(encodeURIComponent(username)));
        request.send();
    }

    StackView.onActivated: {
        if (mode === "token")
            Chiaki.settings.remotePlayAsk = true;
        if (mode !== "lookup" && embedded)
            createBrowser();
    }

    // The embedded browser needs Qt WebEngine, which some builds do not have
    function createBrowser() {
        if (web)
            return;
        try {
            web = Qt.createQmlObject("
                import QtWebEngine
                import org.streetpea.chiaking
                WebEngineView {
                    profile {
                        offTheRecord: false
                        storageName: page.mode === 'token' ? 'psn-token' : 'psn-login'
                        onClearHttpCacheCompleted: {
                            if (page.closing)
                                root.closeDialog();
                            else
                                page.web.reload();
                        }
                    }
                    settings {
                        touchIconsEnabled: true
                        localContentCanAccessRemoteUrls: true
                    }
                    onContextMenuRequested: (request) => request.accepted = true;
                    onNavigationRequested: (request) => {
                        if (Chiaki.checkPsnRedirectURL(request.url)) {
                            page.submit(request.url);
                            request.reject();
                        } else {
                            request.accept();
                        }
                    }
                    onCertificateError: console.error(error.description);
                }", browser, "browser");
            Chiaki.setWebEngineHints(web.profile);
            web.url = Chiaki.psnLoginUrl();
            web.anchors.fill = browser;
        } catch (error) {
            console.warn("Sign-in inside the app is not available:", error);
            web = null;
            embedded = false;
        }
    }

    Connections {
        target: Chiaki
        enabled: page.mode === "account"
        function onPsnLoginAccountIdDone(accountId) {
            page.busy = false;
            if (page.callback)
                page.callback(accountId);
            page.close();
        }
        function onPsnLoginAccountIdError(error) {
            page.busy = false;
            page.failure = error;
        }
    }

    TextEdit { id: clipboard; visible: false }

    component Step: Row {
        property int number
        property alias text: stepText.text
        default property alias extra: stepExtra.data
        spacing: Theme.unit * 2

        Rectangle {
            width: Theme.px(34); height: width; radius: width / 2
            color: "transparent"
            border.width: Math.max(2, Theme.px(2)); border.color: Theme.pink
            V.Label { anchors.centerIn: parent; text: parent.parent.number; font.weight: Theme.weightStrong; font.pixelSize: Theme.textLabel }
        }
        Column {
            width: steps.width - Theme.px(34) - Theme.unit * 2
            spacing: Theme.px(10)
            V.Label { id: stepText; width: parent.width; wrapMode: Text.Wrap; font.pixelSize: Theme.textHeading; topPadding: Theme.px(3) }
            Row { id: stepExtra; spacing: Theme.unit * 2 }
        }
    }

    Column {
        id: intro
        x: Theme.margin
        y: Theme.px(4)
        width: Math.min(parent.width * 0.52, Theme.px(640))
        spacing: Theme.px(6)

        V.Label {
            width: parent.width
            text: page.mode === "lookup" ? qsTr("Find your account ID") : page.expired ? qsTr("Sign in again") : qsTr("Sign in to PSN")
            font.pixelSize: Theme.textDisplay
            font.weight: Theme.weightDisplay
            wrapMode: Text.Wrap
            lineHeight: 0.95
        }
        V.Label {
            width: parent.width
            wrapMode: Text.Wrap
            font.pixelSize: Theme.textHeading
            text: page.mode === "lookup" ? qsTr("Enter your PSN username. Your profile must allow anyone to find you in search.")
                : page.mode === "account" ? qsTr("Pairing needs your account ID. Signing in reads it for you.")
                : page.expired ? qsTr("Your PSN sign-in has expired. Sign in again to keep playing away from home.")
                : qsTr("Pair consoles without a PIN and play away from home.")
        }
    }

    // ---- In your own browser ---------------------------------------------------
    Column {
        id: steps
        visible: page.mode !== "lookup" && !(page.embedded && page.web)
        anchors { left: intro.left; top: intro.bottom; topMargin: Theme.px(24) }
        width: intro.width
        spacing: Theme.px(18)

        Step {
            number: 1
            text: qsTr("Open the PlayStation sign-in page in your browser.")
            V.Button {
                id: openButton
                text: page.link ? qsTr("Open it again") : qsTr("Open sign-in page")
                onTriggered: page.openLink()
            }
            V.Button {
                anchors.verticalCenter: parent.verticalCenter
                visible: page.link
                kind: "text"
                text: qsTr("Copy the link")
                onTriggered: page.copyLink()
            }
        }
        Step {
            number: 2
            text: qsTr("Sign in. You end on a page that looks blank or broken: that is expected.")
        }
        Step {
            number: 3
            text: qsTr("Copy that page's address and paste it here.")
            V.TextInput {
                id: urlField
                width: Theme.px(380)
                implicitHeight: Theme.controlHeight
                font.pixelSize: Theme.textBody
                placeholderText: qsTr("Address of the last page")
                echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
                invalid: page.failure !== ""
                onTextEdited: page.failure = ""
                Keys.onReturnPressed: page.submit(text)
                Accessible.name: placeholderText
            }
            V.Button {
                kind: "outline"
                size: "sm"
                implicitHeight: Theme.controlHeight
                text: qsTr("Paste")
                onTriggered: { urlField.clear(); urlField.paste() }
            }
        }
    }

    // ---- By username -------------------------------------------------------------
    Column {
        visible: page.mode === "lookup"
        anchors { left: intro.left; top: intro.bottom; topMargin: Theme.px(28) }
        width: intro.width
        spacing: Theme.px(10)

        V.Label { text: qsTr("PSN username"); font.weight: Theme.weightStrong }
        V.TextInput {
            id: usernameField
            width: Theme.px(420)
            placeholderText: qsTr("Username")
            echoMode: Chiaki.settings.streamerMode ? TextInput.Password : TextInput.Normal
            invalid: page.failure !== ""
            onTextEdited: page.failure = ""
            Keys.onReturnPressed: page.lookup()
            Accessible.name: qsTr("PSN username")
        }
        V.Label {
            width: parent.width
            wrapMode: Text.Wrap
            text: qsTr("The lookup is done by psn.flipscreen.games, a public service outside PlayStation.")
            font.pixelSize: Theme.textSmall
            color: Theme.textMuted
        }
    }

    // ---- Inside the app ----------------------------------------------------------
    V.Panel {
        visible: page.mode !== "lookup" && page.embedded && page.web !== null
        anchors { left: intro.left; right: parent.right; rightMargin: Theme.margin; top: intro.bottom; topMargin: Theme.px(14); bottom: actions.top; bottomMargin: Theme.px(14) }
        color: Theme.surfaceSolid
        clip: true

        Item { id: browser; anchors { fill: parent; margins: Theme.px(6) } }
    }

    Column {
        id: actions
        anchors { left: intro.left; bottom: parent.bottom; bottomMargin: Theme.px(14) }
        width: Math.min(parent.width - Theme.margin * 2, Theme.px(860))
        spacing: Theme.px(12)

        V.InlineAlert {
            width: parent.width
            visible: page.failure !== "" || page.busy
            severity: page.failure ? "error" : "info"
            text: page.failure || page.status
        }

        Row {
            spacing: Theme.unit * 2

            V.Button {
                visible: page.mode !== "lookup" && !(page.embedded && page.web)
                width: Theme.px(340)
                size: "lg"
                font.pixelSize: Theme.px(28)
                implicitHeight: Theme.px(60)
                text: page.busy ? qsTr("Signing in…") : qsTr("Finish sign-in")
                enabled: urlField.text.trim().length > 0
                busy: page.busy
                onTriggered: page.submit(urlField.text.trim())
            }
            V.Button {
                visible: page.mode === "lookup"
                width: Theme.px(340)
                size: "lg"
                font.pixelSize: Theme.px(28)
                implicitHeight: Theme.px(60)
                text: page.busy ? qsTr("Looking up…") : qsTr("Find account ID")
                enabled: usernameField.text.trim().length > 0
                busy: page.busy
                onTriggered: page.lookup()
            }
            V.Button {
                id: browserButton
                anchors.verticalCenter: parent.verticalCenter
                visible: page.mode !== "lookup" && page.embedded && page.web !== null
                kind: "outline"
                text: qsTr("Use my browser instead")
                onTriggered: { page.embedded = false; page.openLink() }
            }
            V.Button {
                anchors.verticalCenter: parent.verticalCenter
                visible: page.mode !== "lookup" && page.embedded && page.web !== null
                kind: "text"
                text: qsTr("Start over")
                onTriggered: { Chiaki.clearCookies(page.web.profile); page.web.profile.clearHttpCache() }
            }
            V.Button {
                anchors.verticalCenter: parent.verticalCenter
                kind: "outline"
                width: Theme.px(150)
                text: page.busy ? qsTr("Cancel") : qsTr("Back")
                onTriggered: page.back()
            }
        }
    }
}
