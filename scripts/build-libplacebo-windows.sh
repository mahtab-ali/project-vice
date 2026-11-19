#!/bin/bash

SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"
cd $(dirname "${BASH_SOURCE[0]}")/..
cd "./$1"
shift
ROOT="`pwd`"

TAG="${LIBPLACEBO_VERSION:-v7.387.0}"
if [ ! -d "libplacebo" ]; then
git clone --recursive https://github.com/haasn/libplacebo.git || exit 1
fi
cd libplacebo || exit 1
git checkout $TAG || exit 1
# vice: ask for an opaque swapchain first. libplacebo prefers a see-through one where the
# driver offers it, and the desktop then shows through the window wherever alpha is below 1
# (always, with tools that extend the window frame). The app never wants a see-through window.
python - <<'PATCH' || exit 1
p = "src/vulkan/swapchain.c"; s = open(p, newline="").read()
opaque = "        {VK_COMPOSITE_ALPHA_OPAQUE_BIT_KHR,          PL_ALPHA_UNKNOWN}," + chr(10)
head = "                        } alphaModes[] = {" + chr(10)
if opaque in s and not s.split(head)[1].startswith(opaque):
    s = s.replace(opaque, "", 1).replace(head, head + opaque, 1); open(p, "w", newline="").write(s)
assert s.split(head)[1].startswith(opaque), "libplacebo alpha mode table changed; update this patch"
PATCH
DIR=./build || exit 1
meson setup --prefix /mingw64 -Dxxhash=disabled $DIR || exit 1
ninja -C$DIR || exit 1
ninja -Cbuild install || exit 1
