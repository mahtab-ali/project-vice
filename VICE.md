# Project Vice

Developer notes for Project Vice: what is built, how it is laid out, how to build and preview it, and how it stays mergeable with the upstream project it is built on. The licence is AGPL-3.0-only with the OpenSSL exception.

"Upstream" below means that project (credited in `README.md`). Its name survives in code identifiers, file names and copyright notices, and nowhere the app shows.

## What is implemented

Every screen below is real QML bound to the existing backend (`Chiaki`, its settings, the stream session). Where the backend cannot do something yet, the screen says so instead of showing numbers.

| Screen | In the app |
| --- | --- |
| Home | Console discovery, on / rest / not-found states, connect, pair, wake, add, hide or remove. The chosen console is remembered across discovery refreshes. Empty, searching and search-off states. |
| PSN sign-in | Replaces upstream's two sign-in dialogs with one page: sign in through your browser, sign in inside the app where Qt WebEngine is present, or look the account ID up by username. The calls into the backend are upstream's. |
| Add console, console login PIN | Vice pages over the same backend calls. Add console lists what discovery found on the network, addresses included, so the usual case is a pick, not typing; an address can still be entered for a console on another network. Pairing takes its console and address the same way. |
| Play from anywhere | A guide with the actions beside each step: PSN sign-in, or port forwarding with the ports upstream documents, then adding the console by address. Reached from Settings, Network and from the account button. |
| Shortcuts | A Settings page listing the keyboard and controller shortcuts the app really has. |
| Pair console | Replaces upstream's register dialog and calls the same `registerHost`. PSN sign-in and lookup reuse upstream's pages. 8-digit code entry with paste, backspace and controller entry. Success is reported only when the console accepts the code. |
| Connection check | Real measurements: ping, jitter, packet loss and a 30-second chart, from round trips of the console's discovery request, plus the Wi-Fi band and signal the operating system reports (a 2.4 GHz link is called out). It probes twice a second, which is too slow to see the short Wi-Fi pauses described under "What the engine measures"; the stream itself counts those. |
| Choose mode | Game and Quality are upstream's Fast and High Quality renderer presets. A custom preset is kept unless a mode is picked. The profile selector uses upstream's settings profiles. When the console reports the game it is running, "Always for this game" ties that game to the profile, and the profile is switched to on the way in. |
| Stream | Upstream's stream view, patched: quick menu on the right, stream readout, disconnect question. Both renderer paths are kept (QML over the video with Vulkan, separate windows with OpenGL). |
| Quick menu | Mode, picture settings, bitrate (kept pending, applied by a confirmed reconnect), volume, microphone, picture size, overlay toggle, save the last 30 seconds, resume, disconnect. |
| Settings | Video, Network, Input, Audio, Advanced. Edits are a draft until Save, with a prompt on leaving unsaved. "All settings" under Advanced opens upstream's full settings. |
| Game profiles | Select, create and delete upstream settings profiles; mode per profile; stick deadzones and response curve per profile, applied to what is sent to the console; button mapping. |
| Sessions | History recorded on this computer: duration, average packet loss, dropped frames. Missing values show as a dash. |
| Benchmark | Runs two measured 30-second sessions on a console on this network, first with the app's speed tuning off, then on, and shows what both measured. One run each, so small gaps are noise. The console is left on afterwards. |
| Alerts | One notification host and one dialog coordinator (`vice/Vice.qml`): connection lost with retry, disconnect confirmation, reconnect to apply, console linked, connection unstable, controller disconnected, settings saved, unsaved changes, waking, pairing errors, empty states. |

Five upstream pages are not rewritten: all settings, display settings, placebo settings, button mapping and the Steam shortcut. They get the Vice frame and wallpaper (`+vice/DialogView.qml`), Vice buttons, drop-downs, toggles, sliders, radio buttons and text fields (`controls/+vice/`), and the Vice palette and font. The arrangement of their options is still upstream's, and a few controls they declare directly (tab bars, some check boxes) are Material controls in Vice colours.

Screenshots of every screen, rendered from the preview, are in [`screenshots/`](screenshots/).

## Window, full screen and handhelds

- **Name.** The app, its window, its program file and bundle, its settings location, its desktop entry and its icon all say Project Vice (`gui/include/vice/brand.h`, the `vice hook` blocks in `gui/CMakeLists.txt`). Texts that upstream's own pages show are renamed at run time by a translator, so those files need no edits. Not renamed: code identifiers, the CMake target, the log category, upstream's `docs/` site and packaging scripts, and the Steam shortcut artwork.
- **Icon.** `gui/vice.icns`, `vice.ico` and `vice.png`, made from `design/icons/03-sunset-wordmark.png`.
- **Title bar.** The system title bar is turned off and the app draws close, minimise and maximise itself (`components/TitleBar.qml`), on the same picture and gradient as the page: dots on the left on macOS, flat buttons on the right on Windows and Linux. The strip drags the window; on Windows and Linux the edges resize it. "Blend the title bar into the app" in Settings, Advanced brings the system bar back. Checked on macOS only; edge resizing on macOS and all of it on Windows and Linux are untested.
- **Full screen without a frame.** F11, or the toggle in Settings, Advanced.
- **Touch during play.** Every touch and click during a stream goes to the game, except on items that declare `viceTouchTarget` (`gui/src/vice/platform.cpp`): in-game notices, which a tap dismisses or acts on, and the quick-menu tab at the top right. Notices over the game are small dark boxes at the bottom left and always leave on their own.
- **One window.** A second plain launch brings the first window forward and exits.
- **Controller.** Settings, Input has the button-label style (automatic, PlayStation, Xbox) and, on a Steam Deck, the Steam Input layout Steam uses for the app: the community PlayStation layout or Steam's gamepad template. The app sets the PlayStation layout itself on first run on a Deck if Steam has none for it; Steam applies a change after it restarts. It assumes the Steam shortcut is named "Project Vice".
- **Clean view.** A quick-menu toggle that removes the readout, hints and notices from over the picture.
- **Steam Deck and other handhelds.** Detected from the built-in controls. Focus is always shown, text fields ask for the on-screen keyboard, the artwork is decoded smaller and the looks-only mask on the mode cards is skipped. The layout is checked at 1280×800 in the preview (`SIZE=1280x800 ./shots.sh deck deck-mode`) and the app has been played on a Deck.

## What the engine measures and changes

`gui/src/vice/engine.cpp` sits between the stream and the decoder (`vice hook` lines in `streamsession.cpp` and `qmlmainwindow.cpp`). Everything it reports is measured in the running session.

- **Readout during play.** Frame rate, received bitrate, ping, packet loss, decode time, draw time, client pipeline (frame fully received to drawn), input send delay, dropped frames, and network pauses per minute.
- **Stutters and pauses.** A stutter is the picture standing still for three frame times or more. A pause is nothing arriving from the console for that long. When the two counts match, the stutter is the network, not this computer. At 20 pauses a minute the app says so once per session.
- **Speed switches** (Settings, Advanced, all on by default): low-delay decoding, raised thread priority for the stream's threads, priority marking on stream packets, and on Windows 1 ms timers and Wi-Fi streaming mode for the length of a session. The Windows parts are written and have never been compiled or run.
- **Adaptive bitrate.** Ten seconds of packet loss above the warning level steps the stream down for the rest of that play session by reconnecting: on its own in Game mode, after asking in Quality mode. The saved settings come back when the session ends.
- **Audio buffer.** Sized at connect from the jitter the last connection check measured for that console.
- **Replay.** Off by default, because it asks the console for a full picture every 15 seconds. When on, the last 30 seconds of the encoded stream are kept in memory and saved as an MP4 without re-encoding.
- **Already upstream's behaviour, so no code here:** controller input is sent as soon as it changes, and the newest decoded frame is drawn without a queue.

Measured on an M2 Pro MacBook over 5 GHz Wi-Fi, 1080p 60 fps: decode about 3 ms, draw about 0.5 ms, client pipeline 8 to 12 ms with Vulkan; 15 to 20 ms with the OpenGL fallback. The benchmark found no measurable difference between the speed switches on and off on that Mac.

### macOS: renderer and Wi-Fi

- **Vulkan needs MoltenVK.** Without it the app falls back to OpenGL, which draws each frame in about 9 ms instead of under 1 ms, and says so in a notice. The build copies MoltenVK into the app (`Contents/Resources/vulkan/icd.d`, where the Vulkan loader looks first), so a built app has it without anything being installed on the Mac that runs it. `main.cpp` tells Qt where the Vulkan loader is: the app's `Frameworks` folder in a deployed bundle, the build machine's copy otherwise. Packaging a relocatable bundle (`macdeployqt`, signing) is upstream's recipe in `.github/workflows/build-macos-arm.yml` and has not been run for this fork.
- **OpenGL fallback** is always synced to the display on macOS; unsynced it tears.
- **Wi-Fi pauses.** Measured on the Mac above with the app closed, router on channel 52: one ping in thirteen to the router took 50 to 95 ms instead of 5. In a stream that is a frozen picture about twice a second, and no client setting removes it. The usual cause on a Mac is the radio leaving the router's channel for AirDrop, AirPlay and Handoff discovery (AWDL), which it does not need to do when the router is on channel 44 or 149; that cause is likely here and not confirmed. `sudo ifconfig awdl0 down` turns the hopping off for a while (macOS turns it back on) and is the quick way to check. A cable avoids the question.

## Not available yet

- **RTX Video upscaling and HDR conversion.** Needs NVIDIA's SDK, Windows and an RTX card. Listed in Settings as unavailable; the built-in scalers stay usable.
- **Windows.** Not built for this fork yet (see Building). The Windows-only tuning code compiles in a syntax check and has never run.
- **Discovery failure.** The backend does not report it, so Home tells apart only searching, nothing found and search turned off.
- **Stream readout and notifications over the video with the OpenGL renderer.** QML cannot be drawn over the video there. Dialogs and the quick menu use separate windows; the readout falls back to upstream's.
- **In-game touch targets and the Steam Deck controller layout** are written and have not been run on a Deck.
- The PSN remote-connection progress page and the in-stream login-PIN prompt are upstream's with the Vice backdrop and colours.

## Layout

```
gui/src/qml/vice/
    Theme.qml        every colour, size, radius and duration; screens hard-code none
    Vice.qml         notification queue, dialog coordinator, session history, preferences
    components/      buttons, form controls, dialog, toast, empty and progress states, page shell
    screens/         Home, Pair, ConnectionCheck, ChooseMode, Settings, Profiles, Sessions, Benchmark
    overlay/         QuickMenu, LatencyOverlay
    artwork/         background artwork, under its own terms (see SOURCE.md); every page shows it under a gradient
    fonts/           Rubik and Bungee (SIL OFL)
gui/src/qml/+vice/   replacements for upstream files of the same name
gui/src/qml/controls/+vice/
gui/src/vice/, gui/include/vice/   C++: connection check, engine (timing, tuning, sticks, replay, Wi-Fi), platform glue
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
brew install qt ffmpeg pkgconf opus openssl@3 cmake ninja nasm protobuf speexdsp libplacebo json-c miniupnpc libevent sdl2 molten-vk
B=$(brew --prefix)
cmake -S . -B build -G Ninja -DCMAKE_BUILD_TYPE=Release \
  -DCHIAKI_ENABLE_CLI=OFF -DCHIAKI_ENABLE_TESTS=OFF -DCHIAKI_ENABLE_STEAMDECK_NATIVE=OFF \
  -DOPENSSL_ROOT_DIR="$B/opt/openssl@3" \
  -DCMAKE_PREFIX_PATH="$B/opt/openssl@3;$B/opt/qt;$B/opt/protobuf"
CPATH="$B/opt/ffmpeg/include" cmake --build build --target chiaki
open "build/gui/Project Vice.app"
```

If linking fails with `framework 'AGL' not found` (Qt 6.9.0 on a recent macOS SDK), add `"-DWrapOpenGL_AGL=-framework OpenGL"` to the configure line. CMake warns if it cannot find MoltenVK; the app then runs on the slower OpenGL fallback.

**Steam Deck and Linux.** `scripts/build-appimage.sh` builds `appimage/ProjectVice.AppImage` inside upstream's builder container. It has been built and run on a Steam Deck (SteamOS 3.9) this way, on the Deck itself:

```
podman run --rm --volume "$(pwd):/build/chiaki:Z" -w /build/chiaki \
  --device /dev/fuse --cap-add SYS_ADMIN -e APPIMAGE_EXTRACT_AND_RUN=1 \
  docker.io/streetpea/chiaki-ng-builder:qt6.9.3 \
  /bin/bash -c "sudo -E scripts/build-appimage.sh /build/appdir"
```

Settings live in `~/.config/Project Vice/Project Vice.conf` on Linux. `steamos-add-to-steam <path to the AppImage>` adds it to the Steam library.

**Windows.** Install [MSYS2](https://www.msys2.org), open its "MSYS2 MINGW64" shell, then:

```
git clone --recursive <this repository> project-vice && cd project-vice
scripts/build-windows-msys2.sh
```

The script installs the packages, builds or fetches the dependencies upstream's recipe does (libplacebo, an FFmpeg build, SDL), builds the app and makes `ProjectVice-Win/`, a folder that runs on its own (`ProjectVice.exe`). It follows `.github/workflows/build-msys2.yml` step for step and has not been run for this fork yet, so the first run may need a fix in the script. The Vice C++ sources, Windows-only parts included, pass a syntax check with the MinGW compiler; they have not been linked or run on Windows. Vulkan comes from the graphics driver there, so nothing like MoltenVK is needed. Settings are kept in the registry under `HKEY_CURRENT_USER\Software\Project Vice`, so a Windows install starts unpaired: pair the console with its 8-digit code from Home.

Nothing builds on GitHub: Actions is turned off for the repository, and release builds will be published separately.

## Preview, screenshots and tests

The preview runs the real UI, including `+vice/Main.qml`, against the mock backend in `gui/vice-preview/`. Nothing in that folder ships, and nothing it shows is measured.

```
cd gui/vice-preview
QT_FILE_SELECTORS=vice QT_QUICK_CONTROLS_STYLE=Material qml -I . preview.qml -- home
./shots.sh            # every scene to shots/<scene>.png
./shots.sh mode pair  # only these
./test.sh             # behaviour tests (needs qmltestrunner)
```

The scene name picks a state; the full list is the `scenes` table in `preview.qml`. Groups: `home*`, `pair*`, `psn*`, `add-console`, `console-pin`, `check*`, `mode*`, `settings*`, `profiles*`, `sessions*`, `benchmark*` (results, ready, running), `stream*` (including `stream-pauses`), `waking`, `dialog-*`, `toast*`. Add a size as a second argument, for example `-- home 1920x1080`.

Controller glyphs come from the app's resources, so the preview shows letter badges in their place.
