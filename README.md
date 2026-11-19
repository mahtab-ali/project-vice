# Project Vice

Project Vice is a free, open-source Remote Play client for PC. Your console runs the game; Project Vice streams it to a Windows, macOS or Linux computer or a Steam Deck, with a controller-first interface built for the couch.

![Home](screenshots/home.jpg)

## What it does

- Finds the consoles on your network, pairs with an 8-digit code, wakes a console from rest mode and connects.
- Checks the link to a console before you play and shows the ping, jitter and packet loss it measured.
- Game and Quality modes, per-profile settings, and a quick menu during play.
- Play away from home through your PSN account or with port forwarding, with a step-by-step guide in the app.
- Works with a controller, a keyboard or a mouse.

More screens are in [`screenshots/`](screenshots/).

| | |
| --- | --- |
| ![Choose a mode](screenshots/mode.jpg) | ![Settings](screenshots/settings.jpg) |
| ![Sign in](screenshots/psn.jpg) | ![Play from anywhere](screenshots/remote-play.jpg) |

## Status

Early. The interface is complete; RTX upscaling and HDR conversion are not built and say so in the app. It has been built and run on macOS, and built on Linux. Windows is not built yet. [`VICE.md`](VICE.md) has the details, the build steps and how the code is laid out.

Release builds are not published yet.

## Use your own console

Project Vice works with consoles you own and your own PSN account. It is not affiliated with or endorsed by Sony Interactive Entertainment, Rockstar Games or Take-Two Interactive. PlayStation, PS4 and PS5 are trademarks of Sony Interactive Entertainment. The background artwork is described in [`gui/src/qml/vice/artwork/SOURCE.md`](gui/src/qml/vice/artwork/SOURCE.md).

## Licence and credits

AGPL-3.0-only with an OpenSSL exception; see [`COPYING`](COPYING) and [`LICENSES/`](LICENSES/). Project Vice is built on the Remote Play protocol work of the Chiaki and chiaki-ng projects, whose copyright notices are kept throughout the source.
