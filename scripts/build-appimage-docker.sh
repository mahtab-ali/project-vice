#!/bin/bash
# Builds the x86-64 AppImage (Steam Deck and Linux PCs) in upstream's builder container,
# from any machine with Docker or Podman, an Apple silicon Mac included.
# Usage, from anywhere: scripts/build-appimage-docker.sh
# Writes dist/ProjectVice-<version>-x86_64.AppImage. The source folder is mounted
# read-only and copied inside the container, so nothing is written into this checkout.
set -euo pipefail
cd "$(dirname "$0")/.."

engine="$(command -v docker || command -v podman)"
version="$(sed -n 's/^set(CHIAKI_VERSION_[A-Z]* \([0-9]*\))/\1/p' CMakeLists.txt | paste -sd. -)"
mkdir -p dist

"$engine" run --rm --platform linux/amd64 -e APPIMAGE_EXTRACT_AND_RUN=1 \
    -v "$PWD:/src:ro" -v "$PWD/dist:/out" \
    docker.io/streetpea/chiaki-ng-builder:qt6.9.3 bash -ec '
sudo mkdir -p /build/chiaki
sudo chown "$(id -u):$(id -g)" /build/chiaki
tar -C /src --exclude=./build --exclude=./dist --exclude=./build_appimage --exclude=./appimage \
    --exclude=./ProjectVice-Win --exclude=./gui/vice-preview/shots -cf - . | tar -C /build/chiaki -xf -
sudo git config --system --add safe.directory "*"

# On a machine that emulates x86-64 (an Apple silicon Mac), Linux refuses to start an AppImage
# because of three marker bytes in its header. Blank them in the two build tools as they are
# downloaded. The AppImage that is built is not touched.
real_curl="$(command -v curl)"
printf "%s\n" "#!/bin/bash" \
    "$real_curl \"\$@\"; rc=\$?" \
    "for f in *.AppImage; do" \
    "    [ -f \"\$f\" ] && [ \"\$(dd if=\"\$f\" bs=1 skip=8 count=2 2>/dev/null)\" = AI ] && printf \"\\0\\0\\0\" | dd of=\"\$f\" bs=1 seek=8 conv=notrunc 2>/dev/null" \
    "done" \
    "exit \$rc" | sudo tee /usr/local/bin/curl >/dev/null
sudo chmod +x /usr/local/bin/curl

cd /build/chiaki
sudo -E scripts/build-appimage.sh /build/appdir
cp appimage/ProjectVice.AppImage "/out/ProjectVice-'"$version"'-x86_64.AppImage"
'
echo "dist/ProjectVice-$version-x86_64.AppImage"
