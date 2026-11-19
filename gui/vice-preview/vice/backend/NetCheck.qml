// SPDX-License-Identifier: LicenseRef-AGPL-3.0-only-OpenSSL
import QtQuick

// Preview stand-in for the C++ ViceNetCheck, with the same properties.
// `fixture` picks a canned run; the app measures instead.
QtObject {
    id: check

    // good | wifi | silent | slow (stays running until stopped)
    property string fixture: "good"

    property bool running: false
    property int expected: 60
    property int sent: 0
    property int received: 0
    property var samples: []
    property real ping: NaN
    property real jitter: NaN
    property real loss: NaN
    property string link: "unknown"
    signal finished()

    function start(host, ps5, seconds) {
        expected = seconds * 2;
        link = fixture === "wifi" ? "wifi" : "wired";
        if (fixture === "slow") {
            sent = 14; received = 13; ping = 2.1; jitter = 0.4; loss = 100 / 14;
            samples = [2.1, 2.0, 2.2, 2.1, 2.0, -1, 2.3, 2.1, 2.0, 2.2, 2.1, 2.0, 2.1, 2.2];
            running = true;
            return;
        }
        const list = [];
        for (let i = 0; i < expected; ++i) {
            if (fixture === "silent")
                list.push(-1);
            else if (fixture === "wifi")
                list.push(i % 17 === 9 ? -1 : 9 + 6 * Math.abs(Math.sin(i * 1.7)) + (i % 11 === 0 ? 22 : 0));
            else
                list.push(2 + 0.12 * Math.sin(i * 0.9));
        }
        samples = list;
        sent = expected;
        const replies = list.filter(s => s >= 0);
        received = replies.length;
        loss = (sent - received) / sent * 100;
        if (replies.length) {
            const sorted = replies.slice().sort((a, b) => a - b);
            ping = sorted[Math.floor(sorted.length / 2)];
            let total = 0;
            for (let i = 1; i < replies.length; ++i)
                total += Math.abs(replies[i] - replies[i - 1]);
            jitter = replies.length > 1 ? total / (replies.length - 1) : 0;
        } else {
            ping = NaN;
            jitter = NaN;
        }
        running = false;
        finished();
    }
    function stop() { running = false }
}
