# Project Vice

Project Vice is a fork of [chiaki-ng](https://github.com/streetpea/chiaki-ng) with its own UI and, later, latency, network and upscaling work. The licence is unchanged: AGPL-3.0-only with the OpenSSL exception.

This file covers what the fork adds and how to work on it. Everything else is in upstream's `README.md` and `docs/`.

## What is implemented

Every screen below is real QML bound to the existing backend (`Chiaki`, its settings, the stream session). Where the backend cannot do something yet, the screen says so instead of showing numbers.

| Screen | In the app |
| --- | --- |
| Home | Console discovery, on / rest / not-found states, connect, pair, wake, add, hide or remove. The chosen console is remembered across discovery refreshes. Empty, searching and search-off states. |
| PSN sign-in | Replaces upstream's two sign-in dialogs with one page: sign in through your browser, sign in inside the app where Qt WebEngine is present, or look the account ID up by username. The calls into the backend are upstream's. |
| Add console, console login PIN | Vice pages over the same backend calls. |
| Play from anywhere | A guide with the actions beside each step: PSN sign-in, or port forwarding with the ports upstream documents, then adding the console by address. Reached from Settings, Network and from the account button. |
| Shortcuts | A Settings page listing the keyboard and controller shortcuts the app really has. |
| Pair console | Replaces upstream's register dialog and calls the same `registerHost`. PSN sign-in and lookup reuse upstream's pages. 8-digit code entry with paste, backspace and controller entry. Success is reported only when the console accepts the code. |
| Connection check | Real measurements: ping, jitter, packet loss and a 30-second chart, from round trips of the console's discovery request. Link type comes from the operating system and reads "Unknown" where it cannot tell (macOS). |
| Choose mode | Game and Quality are upstream's Fast and High Quality renderer presets. A custom preset is kept unless a mode is picked. The profile selector uses upstream's settings profiles. |
| Stream | Upstream's stream view, patched: quick menu on the right, stream readout, disconnect question. Both renderer paths are kept (QML over the video with Vulkan, separate windows with OpenGL). |
| Quick menu | Mode, picture settings, bitrate (kept pending, applied by a confirmed reconnect), volume, microphone, picture size, overlay toggle, resume, disconnect. |
| Settings | Video, Network, Input, Audio, Advanced. Edits are a draft until Save, with a prompt on leaving unsaved. "All settings" under Advanced opens upstream's full settings. |
| Game profiles | Select, create and delete upstream settings profiles; mode per profile; button mapping. |
| Sessions | History recorded on this computer: duration, average packet loss, dropped frames. Missing values show as a dash. |
| Alerts | One notification host and one dialog coordinator (`vice/Vice.qml`): connection lost with retry, disconnect confirmation, reconnect to apply, console linked, connection unstable, controller disconnected, settings saved, unsaved changes, waking, pairing errors, empty states. |

Five upstream pages are not rewritten: all settings, display settings, placebo settings, button mapping and the Steam shortcut. They get the Vice frame and wallpaper (`+vice/DialogView.qml`), Vice buttons, drop-downs, toggles, sliders, radio buttons and text fields (`controls/+vice/`), and the Vice palette and font. The arrangement of their options is still upstream's, and a few controls they declare directly (tab bars, some check boxes) are Material controls in Vice colours.

Screenshots of every screen, rendered from the preview, are in [`screenshots/`](screenshots/).

## Window, full screen and handhelds

- **Title bar.** On Windows and macOS with Qt 6.9 or newer the app draws under the window's title bar, so the system's own buttons sit on the page's gradient. It is a setting (Settings, Advanced) and does nothing on Linux, where the window manager draws the frame.
- **Full screen without a frame.** F11, or the toggle in Settings, Advanced.
- **Clean view.** A quick-menu toggle that removes the readout, hints and notices from over the picture.
- **Steam Deck and other handhelds.** Detected from the built-in controls. Focus is always shown, text fields ask for the on-screen keyboard, the artwork is decoded smaller and the looks-only mask on the mode cards is skipped. The layout is checked at 1280×800 in the preview (`SIZE=1280x800 ./shots.sh deck deck-mode`); it has not been run on a Deck.

## Not available yet

These need backend work that does not exist. The UI for them is complete in the preview and shows an honest unavailable state in the app.

- **RTX Video upscaling and HDR conversion.** Listed in Settings as unavailable; the built-in scalers stay usable.
- **Replay capture.** "Save last 30 seconds" is disabled with a reason.
- **Benchmark.** The page explains that this build cannot time the stream pipeline. No numbers are shown.
- **Stick deadzones and response curves.** Disabled on the profiles page. Button mapping works.
- **Frame rate, ping, decode and upscale time during a stream.** The overlay shows what the client does measure: received bitrate, packet loss, frame wait and dropped frames.
- **Discovery failure.** The backend does not report it, so Home tells apart only searching, nothing found and search turned off.
- **Stream readout and notifications over the video with the OpenGL renderer.** QML cannot be drawn over the video there. Dialogs and the quick menu use separate windows; the readout falls back to upstream's.
- The PSN remote-connection progress page and the in-stream login-PIN prompt are upstream's with the Vice backdrop and colours.

## Layout

```
gui/src/qml/vice/
    Theme.qml        every colour, size, radius and duration; screens hard-code none
    Vice.qml         notification queue, dialog coordinator, session history, preferences
    components/      buttons, form controls, dialog, toast, empty and progress states, page shell
    screens/         Home, Pair, ConnectionCheck, ChooseMode, Settings, Profiles, Sessions, Benchmark
    overlay/         QuickMenu, LatencyOverlay
    artwork/         background artwork, under its own terms (see SOURCE.md)
    fonts/           Rubik and Bungee (SIL OFL)
gui/src/qml/+vice/   replacements for upstream files of the same name
gui/src/qml/controls/+vice/
gui/src/vice/, gui/include/vice/   C++: the connection check
gui/vice-preview/    the whole UI against a mock backend, screenshots, tests
```

## How it plugs into upstream

One CMake option, `CHIAKI_ENABLE_VICE_UI`, on by default. `-DCHIAKI_ENABLE_VICE_UI=OFF` builds stock chiaki-ng. The Vice UI needs Qt 6.6 or newer.

When it is on, a Qt file selector named `vice` is active: a file in a `+vice/` folder is loaded wherever upstream asks for the file of the same name beside that folder. No upstream QML file is edited. Imports inside a `+vice/` file resolve as if it were the file it replaces.

Three replacements are copies of upstream files and need care when merging upstream:

- `+vice/Main.qml` keeps upstream's `root` API. Blocks marked `upstream` are copied unchanged.
- `+vice/StreamView.qml` is upstream's file with changes marked `vice:`.
- `+vice/DialogView.qml` and `controls/+vice/Button.qml` keep upstream's properties and focus handling.

Edits to upstream files are marked `vice hook` (or `# vice` in `.gitignore`):

```
git grep -n "vice hook"
git fetch upstream && git merge upstream/main
```

## Artwork and wordmark

The screens sit on `gui/src/qml/vice/artwork/key-art.jpg`, which CMake bundles when it is present. It is Rockstar's "Jason and Lucia 01" wallpaper, unchanged, and is not covered by the source-code licence; `SOURCE.md` beside it records where it came from. Replace that file to use other artwork. Without it every screen falls back to the plain navy background.

The wordmark is ordinary text set in Bungee, an open-licensed font, with the pink dash drawn beside it.

## Building

Clone with submodules, or run `git submodule update --init --recursive` afterwards.

**macOS** (checked on Apple silicon with Homebrew Qt 6.9):

```
brew install qt ffmpeg pkgconf opus openssl@3 cmake ninja nasm protobuf speexdsp libplacebo json-c miniupnpc libevent sdl2
B=$(brew --prefix)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCHIAKI_ENABLE_CLI=OFF -DCHIAKI_ENABLE_TESTS=OFF -DCHIAKI_ENABLE_STEAMDECK_NATIVE=OFF \
  -DOPENSSL_ROOT_DIR="$B/opt/openssl@3" \
  -DCMAKE_PREFIX_PATH="$B/opt/openssl@3;$B/opt/qt;$B/opt/protobuf"
CPATH="$B/opt/ffmpeg/include" cmake --build build --target chiaki
open build/gui/chiaki.app
```

If linking fails with `framework 'AGL' not found` (Qt 6.9.0 on a recent macOS SDK), add `"-DWrapOpenGL_AGL=-framework OpenGL"` to the configure line. Without MoltenVK the app falls back from Vulkan to OpenGL.

**Windows and Linux** use upstream's recipes: `.github/workflows/build-windows-x86.yml` (MSVC) or `build-msys2.yml` list the steps, and `scripts/run-podman-build-appimage.sh` builds an AppImage. Neither has been built for this fork yet. Nothing builds on GitHub: Actions is turned off for the repository, and release builds will be published separately.

## Preview, screenshots and tests

The preview runs the real UI, including `+vice/Main.qml`, against the mock backend in `gui/vice-preview/`. Nothing in that folder ships, and nothing it shows is measured.

```
cd gui/vice-preview
QT_FILE_SELECTORS=vice QT_QUICK_CONTROLS_STYLE=Material qml -I . preview.qml -- home
./shots.sh            # every scene to shots/<scene>.png
./shots.sh mode pair  # only these
./test.sh             # behaviour tests (needs qmltestrunner)
```

The scene name picks a state; the full list is the `scenes` table in `preview.qml`. Groups: `home*`, `pair*`, `psn*`, `add-console`, `console-pin`, `check*`, `mode*`, `settings*`, `profiles*`, `sessions*`, `benchmark*`, `stream*`, `waking`, `dialog-*`, `toast*`. Add a size as a second argument, for example `-- home 1920x1080`.

Controller glyphs come from the app's resources, so the preview shows letter badges in their place.
