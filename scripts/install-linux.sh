#!/bin/bash
# Installs Project Vice on a Steam Deck (Desktop Mode) or a 64-bit Linux PC, or updates it.
# Run it by opening ProjectVice-Install.desktop, or with:
#   curl -fsSL https://raw.githubusercontent.com/mahtab-ali/project-vice/main/scripts/install-linux.sh | bash
# Downloads the newest AppImage from Releases to ~/Applications/ProjectVice.AppImage, adds
# Project Vice to the application menu and the desktop, and opens it. Nothing needs a password.
set -euo pipefail

repo=mahtab-ali/project-vice
app="$HOME/Applications/ProjectVice.AppImage"
icon="$HOME/.local/share/icons/project-vice.png"
entry="$HOME/.local/share/applications/project-vice.desktop"

echo "Looking for the newest Project Vice..."
# Releases are listed newest first; take the first AppImage among them
url="$(curl -fsSL "https://api.github.com/repos/$repo/releases" | grep -m1 -o 'https://[^"]*x86_64\.AppImage' || true)"
[ -n "$url" ] || { echo "No download found. Get the AppImage by hand from https://github.com/$repo/releases" >&2; exit 1; }

mkdir -p "$(dirname "$app")" "$(dirname "$icon")" "$(dirname "$entry")"
echo "Downloading $(basename "$url") (about 165 MB)..."
# Downloaded beside the old copy and swapped in whole, so a failed download leaves that copy working
curl -fL --progress-bar -o "$app.part" "$url"
chmod +x "$app.part"
mv -f "$app.part" "$app"
curl -fsSL -o "$icon" "https://raw.githubusercontent.com/$repo/main/gui/src/qml/vice/images/icon.png" || true

cat > "$entry" <<EOF
[Desktop Entry]
Type=Application
Name=Project Vice
Comment=Remote Play client for PC
Exec="$app"
Icon=$icon
Categories=Game;Network;RemoteAccess;
EOF
chmod +x "$entry"
desktop="$(xdg-user-dir DESKTOP 2>/dev/null || echo "$HOME/Desktop")"
[ ! -d "$desktop" ] || cp -f "$entry" "$desktop/"

echo
echo "Project Vice is installed. Open it from the desktop icon or the application menu."
echo "On a Steam Deck: once it is open, press L3 on its Home screen to add it to Steam."
[ -z "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] || setsid "$app" >/dev/null 2>&1 &
sleep 5
