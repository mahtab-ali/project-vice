# Project Vice

**Play GTA VI on your PC.** Your PS5 runs the game; Project Vice streams it to a Windows PC, a Mac or a Steam Deck and puts your graphics card to work on the picture. Free, open source, and built to feel like Vice City from the first screen.

![GTA VI streamed through Project Vice, with the stream readout](screenshots/stream.jpg)

**[Download for Windows, Mac and Steam Deck](../../releases)** · [Set-up guide](#set-up-step-by-step) · [Play away from home](#play-away-from-home)

It works with every PS5 and PS4 game. GTA VI is the one it was dressed and tuned for.

## GTA VI, streamed

These three pictures are frames taken straight from a Project Vice stream of GTA VI running on a PS5, at 1080p.

![GTA VI gameplay streamed through Project Vice](screenshots/gameplay-1.jpg)

| | |
| --- | --- |
| ![GTA VI gameplay](screenshots/gameplay-2.jpg) | ![GTA VI gameplay](screenshots/gameplay-3.jpg) |

The quick menu comes up over the game without leaving it: mode, upscaler, bitrate, picture size, the stats overlay, save the last 30 seconds, disconnect.

![Quick menu over the game](screenshots/stream-quick.jpg)

In the two pictures with the app's panels over the game, the game frame is a real capture and the numbers in the panels are sample values.

## The Vice City look

The whole app wears it: a sunset palette, the key art behind every screen, a bold wordmark, and tips and notices in the style of the game's own. It is driven with a controller from the couch; a keyboard or mouse works too.

![Home](screenshots/home.jpg)

| | |
| --- | --- |
| ![Connecting](screenshots/stream-loading.jpg) | ![Choose a mode](screenshots/mode.jpg) |
| ![Notices](screenshots/toasts.jpg) | ![Settings](screenshots/settings.jpg) |

## What makes it run cleaner

Remote Play sends a compressed video of the game over your network. What you see depends on how fast and how well that video is decoded, enlarged and drawn, and on how the app copes when the network stumbles. This is what Project Vice does about each.

### Your graphics card does the work

- **Hardware decoding.** The video is decoded on the graphics card, not the processor: Vulkan video or Direct3D 11 on Windows, VideoToolbox on a Mac, Vulkan video or VA-API on a Steam Deck.
- **Drawn with Vulkan.** Each frame goes to the screen through a Vulkan renderer, and the newest frame is always the one drawn; nothing waits in a queue. On a Mac the app carries its own MoltenVK, so this works with nothing else installed.
- **RTX Video Super Resolution on Windows.** With an NVIDIA RTX card, the driver's own AI upscaler enlarges the 1080p stream to your monitor's size. Project Vice asks the driver for it directly, so no NVIDIA software ships with the app. It is the sharpest picture the app can show, for about 13 ms more delay. Turn on "RTX Video Enhancement: Super Resolution" in the NVIDIA app, then choose RTX Video under Settings, Video, Upscaler.
- **HDR from the console.** Choose "H265 with HDR" as the codec, with an HDR display and HDR turned on in the system.
- **Two modes.** Game for the least delay, Quality for a sharper picture, remembered per game profile.

### Less delay between your thumb and the screen

- **Low-delay decoding:** the decoder hands over each frame without holding any back.
- **Controller input is sent the moment it changes**, not on a timer.
- **The stream's threads get raised priority**, and its packets are marked as priority traffic for routers that honour it.
- **On Windows, for the length of a session:** 1 ms system timers, and Wi-Fi streaming mode, which turns off the Wi-Fi card's background scanning.

### A connection that holds

- **Connection check before you play:** 30 seconds of ping, jitter and packet loss to the console, with the Wi-Fi band and signal your computer reports.
- **Adaptive bitrate:** when packets are being lost, the stream steps down instead of breaking up.
- **Audio buffer sized to your network,** from the jitter the connection check measured.
- **It tells you whose fault a stutter is.** The app counts network pauses separately from frames it dropped itself, and says so when the network keeps pausing.

### You can see all of it

- **Stats overlay** in three sizes: frame rate, bitrate, ping, loss, decode time, draw time, client delay, input delay, dropped frames and network pauses.
- **The game's own frame rate**, shown beside the stream's. A game drawing 30 pictures a second inside a 60 fps stream reads "60 fps, Game 30 fps".
- **A benchmark** that plays two measured sessions on your console, tuning off then on, and shows both.

| | |
| --- | --- |
| ![Connection check](screenshots/check.jpg) | ![Benchmark](screenshots/benchmark.jpg) |

### It feels like the console

- **DualSense haptics and adaptive triggers** over USB; rumble on other controllers.
- **Stick deadzones and response curve** per game profile.
- **A controller with no touchpad gets one:** the View button sends the touchpad click.
- **Replay:** save the last 30 seconds as an MP4.

### GTA VI on a Windows PC, measured

This is a frame of GTA VI from a Project Vice stream on Windows 11, with the app's own stats overlay across the top. Nothing in it is a sample value: the bar shows what the app measured at that moment.

![GTA VI streamed to Windows through Project Vice in Game mode, with the stats overlay showing live measurements](screenshots/windows-gameplay.jpg)

Three sessions were played back to back on the same console, in the same spot in the game, one in each mode. The figures are what the overlay showed.

| What | Game mode | Quality mode | Quality mode with RTX Video |
| --- | --- | --- | --- |
| Stream frame rate, and the game's own | 60 fps, game 30 fps | 60 fps, game 30 fps | 60 fps, game 30 fps |
| Round trip to the console | 3 ms | 3 ms | 4 ms |
| Packets lost | 0.0% | 0.0% | 0.0% |
| Sharpness of the pause menu's text (higher is sharper) | 196 | 263 | 356 |
| Sharpness of a poster in the game world | 128 | 161 | 225 |
| Frame received to frame ready to draw | 0.5 ms | 0.5 ms | 8.3 ms |
| Drawing the frame | 0.4 ms | 0.7 ms | 0.5 ms |
| Frame received to frame on screen | 4 to 5 ms | 4 to 7 ms | 18 to 19 ms |
| Controller change to it being sent | 0.1 ms | 0.1 ms | 0.1 ms |
| Graphics card load | 34 to 36% | 15 to 16% | 41 to 44% |

What the table says. RTX Video is clearly the sharpest picture, and it costs delay: about 13 ms more from a frame arriving to it being on screen, of which the driver's enhancement itself is about 7 ms and the rest is decoding through Direct3D and handing the enlarged frame to the renderer. Quality mode is sharper than Game mode for about a millisecond. Game mode loaded the graphics card more than Quality mode did; that was not expected and has not been looked into.

The same two patches of the picture under each setting, pixel for pixel and enlarged three times:

![The game's pause menu and a poster in the game world, in Game mode, Quality mode and with RTX Video Super Resolution](screenshots/windows-upscaling.png)

And the whole frame with RTX Video on:

![GTA VI streamed to Windows with RTX Video Super Resolution on](screenshots/windows-gameplay-rtx.jpg)

Beside the Mac, where the same overlay was read on the Mac build:

| | Windows laptop, RTX 5060 | MacBook, M2 Pro |
| --- | --- | --- |
| Decoding a frame | 0.5 ms (Vulkan video) | about 3 ms (VideoToolbox) |
| Drawing a frame | 0.4 to 0.7 ms | about 0.5 ms |
| Frame received to frame on screen | 4 to 7 ms | 8 to 12 ms with Vulkan, 15 to 20 ms on the OpenGL fallback |
| Driver upscaling | RTX Video Super Resolution | none; the built-in scalers |

The Windows machine: a laptop with an NVIDIA RTX 5060 and a 2560 x 1600 screen, Windows 11, a PS5 on the same 5 GHz Wi-Fi network, a 1080p 60 fps HEVC stream shown at 2560 x 1440. The Mac: an M2 Pro MacBook on 5 GHz Wi-Fi, 1080p 60 fps.

What this does and does not show. Sharpness is the variance of the Laplacian over the same patch of the screen, captured under each setting; still text flatters a sharpening upscaler, and nothing here was measured in motion. The timings are what the overlay showed in a quiet indoor scene over a few seconds, not averages over a play session, and the two machines were not on the same network. The game drawing 30 pictures a second is the game's own choice on the console, which no client can raise.

### What has been measured

| Setup | What | Result |
| --- | --- | --- |
| Windows 11, RTX 5060 laptop, 1080p stream shown at 1440p | Edge sharpness (higher is sharper), one still screen | 356 with RTX Video; 263 in Quality mode; 196 in Game mode; 197 with Direct3D's plain scaling |
| Same | Cost of RTX Video | About 13 ms more from frame received to frame on screen (the driver's step is about 7 ms of it); GPU load 41 to 44% against 15 to 16% |
| M2 Pro MacBook, 5 GHz Wi-Fi, 1080p 60 fps | Decode, draw, whole client pipeline | About 3 ms, 0.5 ms, 8 to 12 ms with Vulkan (15 to 20 ms on the OpenGL fallback) |

These are single measurements on those machines, not promises for yours. On that Mac the benchmark found no measurable difference between the speed switches on and off. Run the benchmark in the app to see what you get on yours.

---

## Download

**On this half of the page:** [Download](#download) · [What you need](#what-you-need) · [Set up, step by step](#set-up-step-by-step) · [Play away from home](#play-away-from-home) · [Steam Deck](#steam-deck) · [Shortcuts](#shortcuts) · [Everything it does](#everything-it-does) · [If something goes wrong](#if-something-goes-wrong) · [Build it yourself](#build-it-yourself)

Every build is on the [Releases](../../releases) page. Pick the file for your device:

| Your device | File to download |
| --- | --- |
| Windows 10 or 11, 64-bit | `ProjectVice-Setup-<version>.exe` |
| Mac with Apple silicon (M1 or newer), macOS 26 or newer | `ProjectVice-<version>-arm64.dmg` |
| Steam Deck | `ProjectVice-Install.desktop`, a small installer that downloads the app for you |
| 64-bit Intel or AMD Linux PC | `ProjectVice-<version>-x86_64.AppImage`, or the same installer |

There is no build for Intel Macs. Already using chiaki-ng? Its paired consoles and settings can be carried over; see "Moving from chiaki-ng" in [`VICE.md`](VICE.md).

## What you need

- A PS5, or a PS4 on system software 8.0 or later, that you own.
- Your PlayStation Network account: the one signed in on that console.
- A controller. A DualSense or DualShock 4 gives you everything, the touchpad included; an Xbox or other controller works too, and so do the Steam Deck's own controls. A keyboard is enough for the menus.
- A good connection between the two. Put the console on a network cable if you can. For the computer, use a cable or 5 GHz Wi-Fi; 2.4 GHz Wi-Fi stutters. Away from home, the upload speed of your home internet matters most: 10 Mbps or more is comfortable.

## Set up, step by step

Do these once, at home, with the computer and the console on the same network.

### Step 1: Install Project Vice

**Windows**

1. Download `ProjectVice-Setup-<version>.exe` and run it.
2. Windows says the installer is from an unknown publisher, because it is not signed. Choose "More info", then "Run anyway".
3. Windows asks whether the installer may make changes: choose Yes. Follow the installer. It installs into Program Files for everyone who uses the computer and adds Start menu and desktop shortcuts.
4. Open Project Vice from the Start menu.

**Mac**

1. Download `ProjectVice-<version>-arm64.dmg` and open it. A window opens with Project Vice on the left and the Applications folder on the right.
2. Drag Project Vice onto Applications.
3. Open Project Vice from Applications. macOS blocks this first launch, because the app is not notarized by Apple. Choose "Done".
4. Open System Settings, go to Privacy & Security, scroll down to the message about Project Vice and choose "Open Anyway". Confirm once more. From then on it opens normally.

Everything the app needs is inside it; there is nothing else to install.

**Steam Deck**

Download `ProjectVice-Install.desktop` in Desktop Mode and double-click it. The full steps, with adding it to Steam, are under [Steam Deck](#steam-deck) below.

**Linux PC**

Paste this into a terminal:

```
curl -fsSL https://raw.githubusercontent.com/mahtab-ali/project-vice/main/scripts/install-linux.sh | bash
```

It downloads the newest build to `~/Applications/ProjectVice.AppImage`, adds Project Vice to the application menu and the desktop, and opens it. It asks for no password. Run it again to update.

Or do it by hand: download `ProjectVice-<version>-x86_64.AppImage`, make it runnable with `chmod +x ProjectVice-*.AppImage`, and run it.

### Step 2: Get the console ready

**On a PS5**

1. Go to Settings, System, Remote Play and turn on "Enable Remote Play".
2. Go to Settings, System, Power Saving, Features Available in Rest Mode. Turn on "Stay Connected to the Internet" and "Enable Turning On PS5 from Network". This is what lets Project Vice wake the console when it is in rest mode.

**On a PS4**

1. Go to Settings, Remote Play Connection Settings and turn on "Enable Remote Play".
2. Go to Settings, Account Management, Activate as Your Primary PS4 and choose "Activate".
3. Go to Settings, Power Save Settings, Set Features Available in Rest Mode. Turn on "Stay Connected to the Internet" and "Enable Turning On PS4 from Network".

When you finish playing on the console itself, put it in rest mode instead of turning it off. A console that is fully off cannot be woken over the network.

### Step 3: Sign in to PlayStation Network

Pairing needs your PSN account ID, and signing in reads it for you. Signing in is also what makes playing away from home work without touching your router.

1. In Project Vice, choose the account button at the top right of the Home screen.
2. On Windows, the PlayStation sign-in page opens inside the app. Sign in and you are done.
3. On a Mac, a Steam Deck or a Linux PC, choose "Open sign-in page". Your browser opens the PlayStation sign-in page. Sign in. You end on a page that looks blank or broken: that is expected. Copy that page's address from the browser's address bar, go back to Project Vice and paste it into "Address of the last page".

Your password is typed into PlayStation's own page and never into Project Vice. If you would rather not sign in, choose "Find your account ID" and enter your PSN username instead; this is enough for pairing and for playing at home, but not for playing away from home through PSN.

![Sign in](screenshots/psn.jpg)

### Step 4: Pair the console

1. Project Vice finds the consoles on your network and shows them on the Home screen. Pick yours and choose "Pair console".
2. On the console, ask for a pairing code. On a PS5: Settings, System, Remote Play, Link Device. On a PS4: Settings, Remote Play Connection Settings, Add Device. The console shows an 8-digit code.
3. Enter the 8 digits in Project Vice. The code lasts a few minutes; if it is refused, get a new one on the console.
4. If your console asks for a login PIN when it starts, enter that PIN in the optional field as well.

The console now shows "Connect" on the Home screen. Pairing is done once per computer.

If your console is not listed, choose "Add console" and pick it from what was found, or type its address.

![Pair](screenshots/pair.jpg)

### Step 5: Play

1. Choose "Connect". A console in rest mode is woken first, which takes a little while.
2. Pick how you want to play: **Game** for the least delay, or **Quality** for a sharper picture. You can change this during a session.
3. The stream starts. Play.
4. To change something or stop, open the quick menu: press L1, R1, L3 and R3 together, press Ctrl+O, or click the tab at the top right of the picture. From there you can change the bitrate, the picture size and the volume, show the stats overlay, and disconnect.

Before your first session, "Connection check" on the Home screen measures ping, jitter and packet loss to the console for 30 seconds and tells you what your network can carry.

| | |
| --- | --- |
| ![Choose a mode](screenshots/mode.jpg) | ![Quick menu](screenshots/stream-quick.jpg) |

## Play away from home

Once the steps above are done, the same console can be reached from a hotel, an office or a friend's house. This works the same way on Windows, on a Mac and on a Steam Deck. There are two ways to do it. Try the first; use the second only if the first does not connect.

**Before you leave home**

- Pair the console at home (steps 1 to 4 above) and play once to confirm it works.
- Leave the console in rest mode, with the two rest mode settings from step 2 turned on.
- Sign in to PSN in Project Vice (step 3).

### Way 1: Through PSN (easiest)

No router changes. PlayStation Network introduces your computer and your console to each other, then they connect directly. It works on most networks.

1. Away from home, open Project Vice. Consoles on your account show on the Home screen as "Away, through PSN".
2. Choose "Connect".
3. If your console is missing, open Settings, Network, "Play from anywhere" and choose "Refresh my consoles". If Project Vice says your sign-in has expired, sign in again.

### Way 2: Port forwarding

Use this if connecting through PSN fails, which happens on some strict networks. You set it up once in your home router.

1. In your router, give the console a fixed address (often called a DHCP reservation or static lease), so the rules below keep pointing at it.
2. In your router, forward these ports to the console's address:

   | Console | Ports |
   | --- | --- |
   | PS5 | 9295 (TCP and UDP), 9296 (UDP), 9297 (UDP), 9302 (UDP) |
   | PS4 | 987 (UDP), 9295 (TCP and UDP), 9296 (UDP), 9297 (UDP) |

3. Note your home's public address: at home, search the web for "what is my IP".
4. Away from home, choose "Add console" in Project Vice, then "Enter an address instead", and type your home's public address. Then connect.

Things to know about this way:

- It is IPv4 only.
- If your internet provider puts you behind a shared address (CGNAT), forwarding cannot work. Use PSN instead.
- Most home connections get a new public address from time to time. If the console stops being found, check the address again.

The app has the same guide with the buttons beside each step: Settings, Network, "Play from anywhere".

![Play from anywhere](screenshots/remote-play.jpg)

### Picture quality away from home

A connection over the internet carries less than your home network. In Settings, Video, find "Away-from-home starting point" and choose "Use it": 720p, 60 fps and 8 Mbps, which holds up on most connections. Raise the bitrate from the quick menu if the connection keeps up. In Game mode, Project Vice lowers the bitrate on its own when packets are being lost.

## Steam Deck

**Install**

1. Press the Steam button, choose Power, then "Switch to Desktop".
2. In the browser, download `ProjectVice-Install.desktop` from [Releases](../../releases).
3. Open the Downloads folder and double-click the file. The Deck asks whether to run it: choose "Continue" (or "Execute").
4. A window shows the download, about 165 MB. When it finishes, Project Vice opens, and there is an icon for it on the desktop and in the application menu.

The installer puts the app in `Applications` in your home folder and asks for no password. To update later, run the same file again. If you would rather not use it, download `ProjectVice-<version>-x86_64.AppImage`, tick "Is executable" under Properties, Permissions, and double-click it.

**Set up, still in Desktop mode**

5. Do steps 2 to 4 above: get the console ready, sign in to PSN and pair. Signing in opens the browser, which is why this is done in Desktop mode. To type, press Steam and X for the on-screen keyboard.

**Add it to Steam**

6. On the Home screen of Project Vice, press L3 (or F1 on a keyboard) to add it to your Steam library. The entry comes with artwork and a controller layout made for PlayStation games.
7. Close Project Vice and choose "Return to Gaming Mode" on the desktop.
8. In Gaming Mode, open your Library, go to the Non-Steam tab and start Project Vice.

The controller layout is applied after Steam restarts, so restart the Deck once if the buttons do not match. Settings, Input, "Steam Deck layout" switches between the PlayStation layout and Steam's plain gamepad layout.

Playing away from home on a Deck is the same as above. Sign in to PSN in Desktop mode before you leave.

![Steam Deck](screenshots/deck.jpg)

## Shortcuts

The app lists these in Settings, Shortcuts.

| Where | What | Keyboard | Controller |
| --- | --- | --- | --- |
| Anywhere | Full screen | F11 | |
| Anywhere | Quit (Windows and Linux) | Ctrl+Q | |
| Menus | Move | Arrow keys | D-pad |
| Menus | Select, go back | Enter, Esc | Cross, Circle (A, B) |
| Menus | Consoles, Sessions, Settings | Page Up, Page Down | L1, R1 |
| Menus | Add a console | F2 | R3 |
| Menus | Add to Steam | F1 | L3 |
| During play | Quick menu | Ctrl+O | L1 + R1 + L3 + R3 |
| During play | Microphone on or off | Ctrl+M | |
| During play | Zoom the picture | Ctrl+Z | |
| During play | Stretch the picture | Ctrl+S | |

## Everything it does

**Consoles**
- Finds the PS4 and PS5 consoles on your network, pairs with the 8-digit code, wakes a console from rest mode and connects.
- Adds a console by address for one on another network, and hides or removes consoles.
- Play away from home through your PSN account or with port forwarding, with a step-by-step guide in the app.

**Before you play**
- A connection check: 30 seconds of ping, jitter and packet loss, with the Wi-Fi band and signal your computer reports.
- Game mode (least delay) or Quality mode (sharper scaling), remembered per game profile.
- A connecting screen with the tips you will want once the picture is up.

**While you play**
- A quick menu on one compact panel: mode, upscaler, bitrate, volume, microphone, picture size (fit, zoom, stretch), the stats overlay and its size, save the last 30 seconds, resume, disconnect.
- A stats overlay in three sizes, from everything (frame rate, bitrate, ping, loss, decode, render, client delay, input delay, dropped frames, network pauses) down to frame rate and ping. It shows the game's own frame rate beside the stream's: a game drawing 30 pictures a second in a 60 fps stream reads "60 fps, Game 30 fps".
- Replay: keep the last 30 seconds in memory and save them as an MP4.
- Adaptive bitrate that steps down when the connection cannot carry the stream.
- Notices over the game for an unstable connection, a controller that disconnects and a network that keeps pausing.
- The mouse pointer stays out of the way and comes back when you move the mouse.

**Controllers**
- Works with a controller, a keyboard or a mouse; every screen can be driven with the D-pad.
- Names the controller that is connected, and shows PlayStation or Xbox button labels to match.
- A controller with no touchpad gets one: the View button sends the touchpad click (View with Menu sends Create).
- Button mapping per controller; stick deadzones and response curve per game profile.
- DualSense haptics and adaptive triggers over USB; rumble on other controllers.
- On a Steam Deck: the Steam Input layout is set up for you, and the app can add itself to your Steam library.

**Performance**
- Hardware video decoding, drawn with Vulkan (OpenGL as a fallback).
- On Windows with an NVIDIA RTX card: RTX Video Super Resolution as the upscaler, through the graphics driver, with no NVIDIA software shipped. The sharpest picture the app can show, for about 13 ms more delay. Turn on "RTX Video Enhancement: Super Resolution" in the NVIDIA app first.
- Low-delay decoding, raised priority for the stream's threads and priority marking on stream packets.
- On Windows, for the length of a session: 1 ms timers and Wi-Fi streaming mode with background scanning off.
- A benchmark that plays two measured sessions, tuning off then on, and shows both.

**The rest**
- Settings for video, network, input, audio and advanced options, with every upstream option still reachable under "All settings".
- Session history kept on your computer: duration, bitrate, packet loss, dropped frames.
- A window without a system title bar, full screen with F11, and one window at a time.

More screens are in [`screenshots/`](screenshots/).

## If something goes wrong

| What you see | What to do |
| --- | --- |
| Windows: "Windows protected your PC" | Choose "More info", then "Run anyway". The installer is not signed. |
| Mac: "Apple could not verify Project Vice" | System Settings, Privacy & Security, "Open Anyway". The app is not notarized. |
| No console on the Home screen | Check the console is on or in rest mode and on the same network as the computer. Guest Wi-Fi networks usually keep devices apart. Otherwise choose "Add console", then "Enter an address instead". |
| The pairing code is refused | Codes last a few minutes: get a new one on the console. Check that the PSN account in Project Vice is the one signed in on the console. |
| The console does not wake | Turn on both rest mode settings from step 2, and leave the console in rest mode, not off. |
| The picture stutters or freezes briefly | Run "Connection check". Use a cable or 5 GHz Wi-Fi, lower the bitrate in the quick menu, and move closer to the router. The stats overlay counts network pauses: if "Pauses" rises with each stutter, the network is the cause. |
| A Mac on Wi-Fi stutters about twice a second | A Mac's Wi-Fi can leave the router's channel briefly for AirDrop and AirPlay discovery. A network cable avoids it; setting the router's 5 GHz channel to 44 or 149 often does too. |
| Away from home, the console does not connect through PSN | Open Settings, Network, "Play from anywhere", choose "Refresh my consoles", and sign in again if asked. If it still fails, set up port forwarding. |
| Buttons are wrong on a Steam Deck | Restart the Deck once after adding Project Vice to Steam, or change "Steam Deck layout" in Settings, Input. |

## Not available yet

- **RTX Video HDR conversion.** Turning a normal picture into HDR with an NVIDIA card is not built; the app lists it as unavailable. HDR from the console itself is available: choose "H265 with HDR" as the codec, with an HDR display and HDR turned on in the system.
- **Reading a third-party controller's own touchpad or back paddles on Windows.** In PC (XInput) mode the controller does not report them. Use the controller's PlayStation mode if it has one.
- **Signed installers.** The Windows installer is not signed and the Mac app is not notarized, so both systems ask before the first run.

## Status

Early, and every build on the Releases page is a preview.

- **Windows:** built and played on Windows 11 with an NVIDIA GPU and a PS5 over Wi-Fi. Not yet tried with a controller in hand: the second step of button mapping and the automatic touchpad assignment.
- **Mac:** built and played on an Apple silicon Mac. The disk image has been started on the Mac that built it and not yet on another one. GTA VI has been streamed from a PS5 to this build at 1080p; the gameplay pictures at the top are from that session.
- **Steam Deck:** the AppImage on the Releases page was installed on a Steam Deck (SteamOS 3.9.6) with the installer script and started from Steam in Gaming Mode: it draws with Vulkan, finds the console and refreshes the PSN sign-in. A stream from this build has not been run on the Deck yet (an earlier build was played there), and the installer file has not been double-clicked on a Deck: the script was run over SSH.
- **Away from home:** both ways use the upstream project's connection code. Neither has been tried from outside the home network with this build.

[`VICE.md`](VICE.md) has the details, what was measured and how the code is laid out.

## Build it yourself

Each platform has one command, described in full under "Building" in [`VICE.md`](VICE.md):

| Platform | Command | Result |
| --- | --- | --- |
| Windows (MSYS2 MINGW64 shell) | `scripts/build-windows-msys2.sh`, then `ISCC scripts\project-vice.iss` | `dist\ProjectVice-Setup-<version>.exe` |
| macOS (Homebrew) | `scripts/build-macos-dmg.sh` | `dist/ProjectVice-<version>-arm64.dmg` |
| Steam Deck and Linux (Docker or Podman, on any machine) | `scripts/build-appimage-docker.sh` | `dist/ProjectVice-<version>-x86_64.AppImage` |

Nothing is built on GitHub. Builds are made on a developer's machine and attached to Releases.

## Use your own console

Project Vice works with consoles you own and your own PSN account. It is not affiliated with or endorsed by Sony Interactive Entertainment, Rockstar Games or Take-Two Interactive. PlayStation, PS4 and PS5 are trademarks of Sony Interactive Entertainment. The background artwork is described in [`gui/src/qml/vice/artwork/SOURCE.md`](gui/src/qml/vice/artwork/SOURCE.md).

## Licence and credits

AGPL-3.0-only with an OpenSSL exception; see [`COPYING`](COPYING) and [`LICENSES/`](LICENSES/). Project Vice is built on the Remote Play protocol work of the Chiaki and chiaki-ng projects, whose copyright notices are kept throughout the source.
