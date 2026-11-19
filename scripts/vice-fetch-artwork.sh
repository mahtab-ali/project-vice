#!/bin/sh
# Downloads the key art the Vice UI is designed around into the place the
# build looks for it. The artwork is copyright Rockstar Games / Take-Two
# Interactive and is not part of this repository: this fetches it from their
# own wallpaper page for your local build. Do not redistribute it.
# See gui/src/qml/vice/artwork/SOURCE.md.
set -e
page="https://www.rockstargames.com/VI/media/artwork-wallpapers"
out="$(dirname "$0")/../gui/src/qml/vice/artwork/key-art.jpg"
agent="Mozilla/5.0"
path=$(curl -fsSL -A "$agent" "$page" | grep -o '/VI/_next/static/media/Jason_and_Lucia_01_landscape\.[A-Za-z0-9_~]*\.jpg' | head -1)
if [ -z "$path" ]; then
    echo "Could not find the wallpaper on $page. Save any 16:9 image as $out instead." >&2
    exit 1
fi
curl -fsSL -A "$agent" "https://www.rockstargames.com${path}?akim=1&imdensity=1&imwidth=2560" -o "$out"
echo "Saved $out. Re-run cmake so the build picks it up."
