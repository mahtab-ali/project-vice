#!/bin/bash
# Builds Project Vice.app with every library inside and packs it into a DMG.
# Usage, from anywhere: scripts/build-macos-dmg.sh
# Needs the Homebrew packages and the configured build folder from VICE.md.
# Writes dist/ProjectVice-<version>-<arch>.dmg. The app is signed ad hoc (no Apple
# account), so macOS asks before the first run; scripts/macos-sign.sh is upstream's
# Developer ID signing for a notarized build and has not been run for this fork.
set -euo pipefail
cd "$(dirname "$0")/.."

brew="$(brew --prefix)"
qtlib="$brew/opt/qt/lib"
[ -f build/CMakeCache.txt ] || { echo "Configure the build first: see macOS under 'Building' in VICE.md" >&2; exit 1; }
CPATH="$brew/opt/ffmpeg/include" cmake --build build --target chiaki

work="$(mktemp -d)"
trap 'rm -rf "$work"' EXIT
mkdir "$work/dmg"
app="$work/dmg/Project Vice.app"
exe="$app/Contents/MacOS/Project Vice"
frameworks="$app/Contents/Frameworks"
cp -a "build/gui/Project Vice.app" "$app"
ln -s /Applications "$work/dmg/Applications"

# Every Mach-O file in the app, and the libraries one loads (without its own name)
binaries() { find "$app" -type f \( -perm +111 -o -name '*.dylib' \) -exec sh -c 'file -b "$1" | grep -q Mach-O && echo "$1"' _ {} \; ; }
deps() { otool -L "$1" | sed 1d | awk '{print $1}' | grep -vxF "$(otool -D "$1" | sed -n 2p)" || true; }

# Homebrew's Qt plugins name Qt as @rpath/..., which macdeployqt only follows through
# a search path the app itself uses. Make the app name Qt the same way.
deps "$exe" | grep "^$qtlib/" | while read -r lib; do
    install_name_tool -change "$lib" "@rpath/${lib#"$qtlib"/}" "$exe"
done

# Copies Qt, its plugins and QML modules, and every Homebrew library the app links,
# and points the app at the copies. MoltenVK is already in Resources (gui/CMakeLists.txt).
"$brew/opt/qt/bin/macdeployqt" "$app" -qmldir="$PWD/gui/src/qml" -libpath="$brew/lib"

# The sign-in page's helper process looks for the frameworks inside its own bundle
helper="$frameworks/QtWebEngineCore.framework/Helpers/QtWebEngineProcess.app/Contents"
[ ! -d "$helper" ] || [ -e "$helper/Frameworks" ] || ln -s ../../../../../../../Frameworks "$helper/Frameworks"

# macdeployqt skips a library that another one names as @rpath/... (libjxl_cms, under FFmpeg).
# ponytail: one level deep; the check below fails the build if a copied library needs more
binaries | while read -r f; do deps "$f"; done | sed -n 's|^@rpath/\(lib[^/]*\.dylib\)$|\1|p' | sort -u | while read -r lib; do
    [ ! -e "$frameworks/$lib" ] || continue
    cp "$brew/lib/$lib" "$frameworks/$lib"
    chmod u+w "$frameworks/$lib"
    install_name_tool -id "@executable_path/../Frameworks/$lib" "$frameworks/$lib" 2>/dev/null
    deps "$frameworks/$lib" | grep "^$brew/" | while read -r dep; do
        install_name_tool -change "$dep" "@executable_path/../Frameworks/$(basename "$dep")" "$frameworks/$lib" 2>/dev/null
    done
done

# The check: every library a file in the app loads is macOS's own or inside the app.
# The patterns open with a bracket for macOS's bash 3.2, which misreads a bare ")" inside \$( ).
outside="$(binaries | while read -r f; do deps "$f" | while read -r dep; do
    case "$dep" in
        (/System/*|/usr/lib/*|@loader_path/*) ;;
        (@executable_path/../Frameworks/*) [ -e "$frameworks/${dep#@executable_path/../Frameworks/}" ] || echo "$dep, for $f" ;;
        (@rpath/*) [ -e "$frameworks/${dep#@rpath/}" ] || echo "$dep, for $f" ;;
        (*) echo "$dep, for $f" ;;
    esac
done; done)"
[ -z "$outside" ] || { echo "Libraries the app needs that are not inside it:" >&2; echo "$outside" >&2; exit 1; }
[ -f "$frameworks/libvulkan.1.dylib" ] || { echo "The Vulkan loader was not bundled" >&2; exit 1; }

codesign --force --deep --sign - --entitlements gui/entitlements.xml "$app"
codesign --verify --deep --strict "$app"

version="$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' "$app/Contents/Info.plist")"
mkdir -p dist
dmg="dist/ProjectVice-$version-$(uname -m).dmg"
hdiutil create -volname "Project Vice" -srcfolder "$work/dmg" -ov -format UDZO "$dmg" >/dev/null
echo "$dmg"
