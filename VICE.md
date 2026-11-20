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
| Quick menu | One line per setting, controls in one column: mode, upscaler, bitrate (kept pending, applied by a confirmed reconnect), volume, microphone, picture size, stats overlay and its size (full, small, mini). Save the last 30 seconds, resume and disconnect stay at the bottom; only the settings scroll. |
| Settings | Video, Network, Input, Audio, Advanced. Edits are a draft until Save, with a prompt on leaving unsaved. "All settings" under Advanced opens upstream's full settings. |
| Game profiles | Select, create and delete upstream settings profiles; mode per profile; stick deadzones and response curve per profile, applied to what is sent to the console; button mapping. |
| Sessions | History recorded on this computer: duration, average packet loss, dropped frames. Missing values show as a dash. |
| Benchmark | Runs two measured 30-second sessions on a console on this network, first with the app's speed tuning off, then on, and shows what both measured. One run each, so small gaps are noise. The console is left on afterwards. |
| Alerts | One notification host and one dialog coordinator (`vice/Vice.qml`): connection lost with retry, disconnect confirmation, reconnect to apply, console linked, connection unstable, controller disconnected, settings saved, unsaved changes, waking, pairing errors, empty states. |

Five upstream pages are not rewritten: all settings, display settings, placebo settings, button mapping and the Steam shortcut. They get the Vice frame and wallpaper (`+vice/DialogView.qml`), Vice buttons, drop-downs, toggles, sliders, radio buttons and text fields (`controls/+vice/`), and the Vice palette and font. The arrangement of their options is still upstream's, and a few controls they declare directly (tab bars, some check boxes) are Material controls in Vice colours.

Screenshots of every screen, rendered from the preview, are in [`screenshots/`](screenshots/). `gameplay-1.jpg` to `gameplay-3.jpg` are different: they are frames from a real stream of GTA VI from a PS5 to the Mac build (1080p, H265), taken from the app's own replay files. The stream screens (`stream*.jpg`) are preview renders with `gameplay-1.jpg` standing in for the video, so the game frame in them is real and the numbers and panels over it are the preview's sample data.

## Window, full screen and handhelds

- **Name.** The app, its window, its program file and bundle, its settings location, its desktop entry and its icon all say Project Vice (`gui/include/vice/brand.h`, the `vice hook` blocks in `gui/CMakeLists.txt`). Texts that upstream's own pages show are renamed at run time by a translator, so those files need no edits. Not renamed: code identifiers, the CMake target, the log category, upstream's `docs/` site and packaging scripts, and the Steam shortcut artwork.
- **Icon.** `gui/vice.icns`, `vice.ico` and `vice.png`, made from `design/icons/03-sunset-wordmark.png`.
- **Title bar.** The system title bar is turned off and the app draws close, minimise and maximise itself (`components/TitleBar.qml`), on the same picture and gradient as the page: dots on the left on macOS, flat buttons on the right on Windows and Linux. The strip drags the window; on Windows and Linux the edges resize it. "Blend the title bar into the app" in Settings, Advanced brings the system bar back. Checked on macOS and on Windows 11 (drag, double-click, edges and corners, the three buttons, the system bar when blending is off); edge resizing on macOS and all of it on Linux are untested.
- **Full screen without a frame.** F11, or the toggle in Settings, Advanced.
- **Touch during play.** Every touch and click during a stream goes to the game, except on items that declare `viceTouchTarget` (`gui/src/vice/platform.cpp`): in-game notices, which a tap dismisses or acts on, and the quick-menu tab at the top right. Notices over the game are small dark boxes at the bottom left and always leave on their own.
- **One window.** A second plain launch brings the first window forward and exits.
- **Controller.** Settings, Input has the button-label style (automatic, PlayStation, Xbox) and, on a Steam Deck, the Steam Input layout Steam uses for the app: the community PlayStation layout or Steam's gamepad template. The app sets the PlayStation layout itself on first run on a Deck if Steam has none for it; Steam applies a change after it restarts. It assumes the Steam shortcut is named "Project Vice".
- **Stream readout sizes.** Full, small (one line: frame rate, bitrate, ping, loss, client delay, pauses) or mini (frame rate and ping), chosen in the quick menu. There is no "clean view": it hid the only on-screen way back to the quick menu.
- **Connecting screen.** The app icon breathing inside a turning ring, the console's name, and one tip at a time drawn from the shortcuts the app really has (`components/StreamLoading.qml`).
- **Pointer during play.** With "hide cursor" on, moving the mouse shows the pointer for 2.5 seconds so the quick-menu tab and window buttons can be reached. Checked on Windows.
- **The window is opaque.** The render target is declared as having no alpha, and the Windows build of libplacebo asks for an opaque swapchain first (`scripts/build-libplacebo-windows.sh`). Without both, tools that extend the window frame over the client area (Windhawk's "Translucent Windows", for one) showed the desktop through the game.
- **Pop-ups under a render control.** From Qt 6.11 the overlay that pop-ups live in is left at 0 x 0 when the app draws through `QQuickRenderControl`; `+vice/Main.qml` sizes it to the window. Without that, every Vice dialog opened off screen with no height.
- **Keys and D-pad.** Up from a page's first control goes to the header (tabs and account), Left and Right move along it, Down returns. The focus ring is switched off only by a pointer that really moved.
- **Controller name.** The footer names the controller. Windows reports every XInput pad as "XInput Controller"; the app reads the product name from the USB device (`vicePlatformControllerName`).
- **Button mapping.** Two steps: press a button on the controller to pick it, then upstream's mapping page. A controller with no touchpad gets one assigned: View (Back) sends the touchpad click and View with Menu sends Create ("View button sends" in Settings, Input: auto, Create, touchpad). PlayStation pads and a Steam Deck are left as they are. The second step and the assignment have not been tried with a controller in hand.
- **Steam Deck and other handhelds.** Detected from the built-in controls. Focus is always shown, text fields ask for the on-screen keyboard, the artwork is decoded smaller and the looks-only mask on the mode cards is skipped. The layout is checked at 1280×800 in the preview (`SIZE=1280x800 ./shots.sh deck deck-mode`) and the app has been played on a Deck.
- **A console that is already streaming.** A console in a Remote Play session with another device answers a new request with "already in use". Upstream's session code retries a failed connection for 20 seconds with a few milliseconds between tries, which against that answer was 683 requests in one 20-second run. The app now stops at the first such answer and shows the failure (`vice hook` in `streamsession.cpp`). Other failures still retry as upstream does. The change has not been run against a console in use: the console was free again by the time it was built.

## What the engine measures and changes

`gui/src/vice/engine.cpp` sits between the stream and the decoder (`vice hook` lines in `streamsession.cpp` and `qmlmainwindow.cpp`). Everything it reports is measured in the running session.

- **Readout during play.** Frame rate, received bitrate, ping, packet loss, decode time, draw time, client pipeline (frame fully received to drawn), input send delay, dropped frames, and network pauses per minute.
- **Stutters and pauses.** A stutter is the picture standing still for three frame times or more. A pause is nothing arriving from the console for that long. When the two counts match, the stutter is the network, not this computer. At 20 pauses a minute the app says so once per session.
- **Speed switches** (Settings, Advanced, all on by default): low-delay decoding, raised thread priority for the stream's threads, priority marking on stream packets, and on Windows 1 ms timers and Wi-Fi streaming mode for the length of a session. The Windows parts compile and link; they have run in streams on Windows 11, and each reports what it did in the log (`vice.platform`).
- **Adaptive bitrate.** Ten seconds of packet loss above the warning level steps the stream down for the rest of that play session by reconnecting: on its own in Game mode, after asking in Quality mode. The saved settings come back when the session ends.
- **Audio buffer.** Sized at connect from the jitter the last connection check measured for that console.
- **RTX Video Super Resolution** (Windows, NVIDIA RTX; Settings, Video, Upscaler; `gui/src/vice/rtxvideo.cpp`). Not NVIDIA's SDK: the driver implements it inside Direct3D 11's video processor, and the app asks for it with the driver's stream extension, as media players do. With it on, the stream is decoded with `d3d11va` on the NVIDIA adapter (on a laptop with two graphics chips Direct3D picks the other one by default, whose driver accepts the request and ignores it), each frame is enlarged to the window's size by the video processor, read back and handed to the Vulkan renderer. Measured on an RTX 5060 laptop, 1080p to 1440p, on one still screen: edge sharpness 356 with it on, 197 with the same path and the driver's part off, 263 for the Quality scaler. The driver's step takes about 7 ms a frame; the whole client path, frame received to frame on screen, goes from 4 to 7 ms to 18 to 19 ms, and GPU load from 15% to 43%. It needs "RTX Video Enhancement: Super Resolution" turned on in the NVIDIA app; with that off the driver says yes and does nothing, and the picture is softer than the built-in scaler. `VICE_RTX_PLAIN=1` in the environment runs the same path with the driver's part off, for comparing. 8-bit streams only.
- **The game's own frame rate.** The readout shows it beside the stream's. A game drawing 30 pictures a second in a 60 fps stream has each sent twice; the console's encoder does not make the repeat tiny, but it is reliably much smaller than the new pictures either side (about 40% of their size on a PS5). The engine counts the share of recent frames that sit well below both neighbours. Checked on one game on a PS5, which read 30 where the stream read 60.
- **Replay.** Off by default, because it asks the console for a full picture every 15 seconds. When on, the last 30 seconds of the encoded stream are kept in memory and saved as an MP4 without re-encoding.
- **Already upstream's behaviour, so no code here:** controller input is sent as soon as it changes, and the newest decoded frame is drawn without a queue.

Measured on an M2 Pro MacBook over 5 GHz Wi-Fi, 1080p 60 fps: decode about 3 ms, draw about 0.5 ms, client pipeline 8 to 12 ms with Vulkan; 15 to 20 ms with the OpenGL fallback. The benchmark found no measurable difference between the speed switches on and off on that Mac.

### macOS: renderer and Wi-Fi

- **Vulkan needs MoltenVK.** Without it the app falls back to OpenGL, which draws each frame in about 9 ms instead of under 1 ms, and says so in a notice. The build copies MoltenVK into the app (`Contents/Resources/vulkan/icd.d`, where the Vulkan loader looks first), so a built app has it without anything being installed on the Mac that runs it. `main.cpp` tells Qt where the Vulkan loader is: the app's `Frameworks` folder in a deployed bundle, the build machine's copy otherwise. `scripts/build-macos-dmg.sh` makes the bundle that runs on another Mac; see "macOS disk image" under Building.
- **OpenGL fallback** is always synced to the display on macOS; unsynced it tears.
- **Wi-Fi pauses.** Measured on the Mac above with the app closed, router on channel 52: one ping in thirteen to the router took 50 to 95 ms instead of 5. In a stream that is a frozen picture about twice a second, and no client setting removes it. The usual cause on a Mac is the radio leaving the router's channel for AirDrop, AirPlay and Handoff discovery (AWDL), which it does not need to do when the router is on channel 44 or 149; that cause is likely here and not confirmed. `sudo ifconfig awdl0 down` turns the hopping off for a while (macOS turns it back on) and is the quick way to check. A cable avoids the question.

## Not available yet

- **RTX Video HDR conversion.** Not built. It would go through the same Direct3D 11 video processor as Super Resolution (see "What the engine measures and changes") with an HDR output, which the renderer's swapchain is not set up for.
- **RTX Video on 10-bit (HDR) streams.** Super Resolution is applied to 8-bit streams only; an HDR stream goes to the built-in scalers.
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

When it is on, a Qt file selector named `vice` is active: a file in a `+vice/` folder is loaded wherever upstream asks for the file of the same name beside that folder. No upstream QML file is edited.

`+vice/` files import the Vice folders as modules (`import vice`, `import vice.components as V`, `vice.screens`, `vice.overlay`), each with a `qmldir`, found through the `qrc:/` import path the app adds (the preview passes `-I ../src/qml`). Relative imports would not do: up to Qt 6.10 they resolve from the folder of the file being replaced, and from Qt 6.11 they resolve from the `+vice/` folder itself whenever the file is reached by type name. A new file in `vice/components`, `vice/screens` or `vice/overlay` needs a line in that folder's `qmldir`, or it is not visible to other files.

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

**macOS disk image.** With the build folder configured as above, `scripts/build-macos-dmg.sh` builds the app, copies Qt and every Homebrew library it loads into it with `macdeployqt`, and writes `dist/ProjectVice-<version>-arm64.dmg` (about 210 MB; the app is about 450 MB, most of it the browser engine behind the PSN sign-in page). The script stops if any file in the app still loads a library from outside it. Checked on the Mac that built it: the app copied out of the mounted image starts with an empty environment, loads nothing from Homebrew or the build folder, draws with Vulkan through its own MoltenVK, and the sign-in helper process starts. Not checked: a Mac without Homebrew, a stream from the packaged app, and the sign-in page itself. The image runs on Apple silicon with macOS 26 or newer, because Homebrew's libraries on the build Mac are built for the macOS they are installed on. It is signed ad hoc and not notarized, so Gatekeeper blocks the first launch until "Open Anyway" is chosen in System Settings, Privacy & Security (or `xattr -dr com.apple.quarantine "/Applications/Project Vice.app"`). A notarized build needs a Developer ID certificate and Apple's notary service; `scripts/macos-sign.sh` is upstream's signing step for that and has not been run for this fork.

**Steam Deck and Linux.** `scripts/build-appimage.sh` builds `appimage/ProjectVice.AppImage` inside upstream's builder container. It has been built and run on a Steam Deck (SteamOS 3.9) this way, on the Deck itself:

```
podman run --rm --volume "$(pwd):/build/chiaki:Z" -w /build/chiaki \
  --device /dev/fuse --cap-add SYS_ADMIN -e APPIMAGE_EXTRACT_AND_RUN=1 \
  docker.io/streetpea/chiaki-ng-builder:qt6.9.3 \
  /bin/bash -c "sudo -E scripts/build-appimage.sh /build/appdir"
```

**Steam Deck and Linux, from another machine.** `scripts/build-appimage-docker.sh` runs the same build in the same container with Docker or Podman and writes `dist/ProjectVice-<version>-x86_64.AppImage` (about 165 MB). The checkout is mounted read-only and copied inside the container. It works on an Apple silicon Mac, where the container runs under x86-64 emulation: about ten minutes with Docker Desktop on an M2 Pro. Under emulation Linux refuses to start an AppImage because of three marker bytes in its header, so the script blanks them in the two build tools it downloads (linuxdeploy and its Qt plugin); the AppImage it produces is left as built. Checked for an image built this way: the library unit tests pass during the build, every library the program needs resolves inside the image or to the system's own graphics and C libraries, and the program starts and reaches renderer set-up in a container with no display. Not checked: running it on a Steam Deck or any Linux desktop.

Settings live in `~/.config/Project Vice/Project Vice.conf` on Linux. `steamos-add-to-steam <path to the AppImage>` adds it to the Steam library.

**Windows** (built and run on Windows 11 with MSYS2's Qt 6.12). Install [MSYS2](https://www.msys2.org), open its "MSYS2 MINGW64" shell, then:

```
pacman -S --needed git
git clone --recursive <this repository> project-vice && cd project-vice
scripts/build-windows-msys2.sh
```

A fresh MSYS2 has no `git`, hence the first line. A clone made with Git for Windows works too; `.gitattributes` keeps the shell scripts' line endings as bash needs them. MSYS2's `git` has no stored GitHub sign-in, so clone a private copy of the repository with Git for Windows.

The script installs the packages, builds or fetches the dependencies upstream's recipe does (libplacebo, an FFmpeg build, SDL), builds the app and makes `ProjectVice-Win/`, a folder that runs on its own (`ProjectVice.exe`, about 330 MB with its DLLs and QML). It follows `.github/workflows/build-msys2.yml` step for step; the first run takes a while and downloads about 250 MB of packages. Vulkan comes from the graphics driver, so nothing like MoltenVK is needed. Settings are kept in the registry under `HKEY_CURRENT_USER\Software\Project Vice\Project Vice`, so a Windows install starts unpaired: pair the console with its 8-digit code from Home.

Checked on Windows 11 with an NVIDIA GPU and a PS5 over Wi-Fi: the folder runs with only Windows' own directories on `PATH`; discovery; the connection check with the Wi-Fi band and signal read from Windows; a stream, with Vulkan hardware decoding; the session tuning, which the log reports line by line (`vice.platform`: 1 ms timers, Wi-Fi streaming mode, thread priority, packet priority); the frameless window; dialogs; keyboard navigation; the pointer during play; one window; the saved window position; `./test.sh` and the library unit tests (`cmake --build build --target chiaki-unit`). Not yet tried with a controller in hand: the second step of button mapping and the automatic touchpad assignment.

**Windows installer.** With the app folder built, [Inno Setup](https://jrsoftware.org/isinfo.php) 6 or newer makes an installer from it: `ISCC scripts\project-vice.iss` writes `dist\ProjectVice-Setup-<version>.exe` (about 87 MB). It asks for administrator rights, installs into Program Files for all users, adds Start menu and desktop shortcuts, and appears under Installed apps with an uninstaller. Each user's settings stay in their own account. It is not signed, so Windows SmartScreen asks before running it. Installers are attached to the repository's Releases, not committed.

**Moving from chiaki-ng on Windows.** chiaki-ng keeps its paired consoles and settings in the registry under `HKEY_CURRENT_USER\Software\Chiaki`. Export that key, replace `Software\Chiaki\Chiaki` with `Software\Project Vice\Project Vice` and `Software\Chiaki\pl_render_params` with `Software\Project Vice\pl_render_params` in the exported file, and import it with Project Vice closed. The console then shows Connect, not Pair. chiaki-ng's "Zoom" window type comes across too; set the picture to Fit in the quick menu if the stream starts zoomed in.

Nothing builds on GitHub: Actions is turned off for the repository. Builds are made on a developer's machine and attached to Releases.

## Preview, screenshots and tests

The preview runs the real UI, including `+vice/Main.qml`, against the mock backend in `gui/vice-preview/`. Nothing in that folder ships, and nothing it shows is measured.

```
cd gui/vice-preview
QT_FILE_SELECTORS=vice QT_QUICK_CONTROLS_STYLE=Material qml -I . -I ../src/qml preview.qml -- home
./shots.sh            # every scene to shots/<scene>.png
./shots.sh mode pair  # only these
./test.sh             # behaviour tests (needs qmltestrunner)
```

The scene name picks a state; the full list is the `scenes` table in `preview.qml`. Groups: `home*`, `pair*`, `psn*`, `add-console`, `console-pin`, `check*`, `mode*`, `settings*`, `profiles*`, `sessions*`, `benchmark*` (results, ready, running), `stream*` (including `stream-pauses`), `waking`, `dialog-*`, `toast*`. Add a size as a second argument, for example `-- home 1920x1080`.

Controller glyphs come from the app's resources, so the preview shows letter badges in their place.
