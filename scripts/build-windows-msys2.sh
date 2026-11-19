#!/usr/bin/env bash
# Builds Project Vice on Windows. Run it from the "MSYS2 MINGW64" shell (https://www.msys2.org):
#   git clone --recursive <this repository> && cd project-vice && scripts/build-windows-msys2.sh
# The steps are upstream's (.github/workflows/build-msys2.yml), in one place.
# ponytail: written from that recipe and not yet run for this fork; fix it here when it is.
set -euo pipefail
cd "$(dirname "$0")/.."
[ "${MSYSTEM:-}" = MINGW64 ] || { echo "Run this from the MSYS2 MINGW64 shell, not ${MSYSTEM:-another shell}." >&2; exit 1; }

git config core.autocrlf false
git submodule update --init --recursive

pacman -S --needed --noconfirm git diffutils make unzip zip pactoys
pacboy -S --needed --noconfirm ca-certificates:p cc:p cmake:p curl:p fast_float:p fftw:p json-c:p \
	libevent:p lcms2:p libdovi:p meson:p miniupnpc:p gcc:p nasm:p ninja:p openssl:p opus:p pkgconf:p \
	protobuf:p python:p python-psutil:p python-glad:p python-jinja:p python-pip:p qt6-base:p \
	qt6-declarative:p qt6-svg:p shaderc:p speexdsp:p spirv-cross:p vulkan:p vulkan-headers:p
pip install protobuf || pip install --break-system-packages protobuf

# Dependencies upstream builds or downloads itself; each is skipped once it is in /mingw64
deps=build-deps
mkdir -p "$deps"
if [ ! -f /mingw64/lib/pkgconfig/libplacebo.pc ]; then
	LIBPLACEBO_VERSION="${LIBPLACEBO_VERSION:-3be579e6c7f6b421d9ac3ab4860edc437c50b3eb}" scripts/build-libplacebo-windows.sh "$deps"
fi
if [ ! -f /mingw64/include/libavformat/avformat.h ]; then
	ffmpeg=ffmpeg-n9.0-latest-win64-gpl-shared-9.0
	( cd "$deps" && curl -LO "https://github.com/streetpea/FFmpeg-Builds/releases/download/latest/$ffmpeg.zip" && unzip -q -o "$ffmpeg.zip" )
	cp -a "$deps/$ffmpeg/bin/." /mingw64/bin
	cp -a "$deps/$ffmpeg/include/." /mingw64/include
	cp -a "$deps/$ffmpeg/lib/." /mingw64/lib
fi
if [ ! -f /mingw64/lib/pkgconfig/sdl2.pc ]; then
	INSTALL_PREFIX=/mingw64 scripts/build-sdl2-compat.sh "$deps"
	INSTALL_PREFIX=/mingw64 scripts/build-hidapi.sh "$deps"
	cp /mingw64/lib/pkgconfig/sdl2-compat.pc /mingw64/lib/pkgconfig/sdl2.pc
fi

cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release -DCHIAKI_ENABLE_CLI=OFF
cmake --build build --target chiaki

# A folder that runs outside this shell, with the DLLs and QML it needs beside the program
scripts/deploy-windows-msys2.sh ProjectVice-Win build/gui/ProjectVice.exe "$PWD/build/third-party/cpp-steam-tools" /mingw64 gui/src/qml
echo
echo "Built. Run ProjectVice-Win/ProjectVice.exe, or build/gui/ProjectVice.exe from this shell."
