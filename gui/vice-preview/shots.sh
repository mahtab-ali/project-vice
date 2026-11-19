#!/bin/sh
# Renders every preview scene to shots/<scene>.png (and a few at other sizes).
# Usage: ./shots.sh [scene ...]
# Warnings from upstream's own dialogs (they expect the full backend, not this
# mock) and from app-only resources are filtered out; Vice files are not.
cd "$(dirname "$0")" || exit 1
mkdir -p shots
scenes="$*"
[ -n "$scenes" ] || scenes=$(sed -n 's/^        "\([a-z0-9-]*\)": .*/\1/p' preview.qml)
for scene in $scenes; do
    # A scene that cannot draw (display asleep, screen locked) would wait forever
    ( sleep 30; pkill -9 -f "preview.qml -- $scene " ) 2>/dev/null &
    watchdog=$!
    QT_FILE_SELECTORS=vice QT_QUICK_CONTROLS_STYLE=Material qml -I . preview.qml -- "$scene" "${SIZE:-1280x720}" "$PWD/shots/$scene.png" 2>&1 \
        | grep -v "Invalid image provider\|Failed to get image from provider\|^qml: \|^$\|qrc:/icons/\|QML Shortcut\|ChiakiWindow_QMLTYPE\|/src/qml/[A-Z][A-Za-z]*\.qml" | sed "s/^/[$scene] /"
    kill $watchdog 2>/dev/null
    wait $watchdog 2>/dev/null
done
