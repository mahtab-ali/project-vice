# Project Vice — launcher icon implementation

Apply the selected launcher icon to the existing native Project Vice application across macOS, Windows, and Linux. The source image is `design/icons/project-vice-launcher.png`, an exact copy of option 2, `design/icons/02-neon-gradient-type.png`. Inspect this image before editing. The selected design has the full **PROJECT VICE** title in neon-gradient lettering. Other icon candidates, including the VI-only versions, are historical alternatives, not the selected source.

## Preserve the selected design

Keep the complete two-line PROJECT / VICE title, blue-violet-to-hot-pink-to-coral/peach letter fills, thin white keylines, dark-purple and pink outlines, deep navy/plum tile, pink inset border, peach underline, rounded-square silhouette, and transparent exterior. Do not abbreviate the title to VI, VICE, or PV, add palms, remove the border, or redesign this selected icon. The application name remains **Project Vice**.

The source is a square RGBA raster master. Keep it unchanged and generate platform assets from it. Normalize padding and output resolution without stretching, clipping the tile, flattening alpha onto black/white, or adding another rounded-square frame. Inspect downscaled edges for halos. Do not describe an embedded PNG in an SVG wrapper as a vector master.

## Repository integration

Read applicable `AGENTS.md`, `VICE.md`, current working-tree changes, and the relevant build/resource files. Preserve unrelated work, bundle/application identifiers, settings paths, binary names, and upstream copyright notices. This task changes launcher/window/packaging artwork, not the application architecture or approved screen layouts.

The following are integration points observed in this repository; recheck their current contents before editing:

- `gui/src/main.cpp` selects `:/icons/chiaking_macos.svg` or `:/icons/chiaking.svg` with `QGuiApplication::setWindowIcon`.
- `gui/res/resources.qrc` contains shared icon resources. `gui/src/qml/vice.qrc` is included when the Vice UI is enabled.
- `gui/CMakeLists.txt` packages `chiaking.icns`, sets `MACOSX_BUNDLE_ICON_FILE`, configures Windows resources, and installs Linux desktop/icon files.
- `gui/MacOSXBundleInfo.plist.in` references the CMake bundle icon setting.
- `gui/chiaking.rc.in` currently embeds `chiaking.ico`; `scripts/chiaki-ng.iss` also references it for the installer.
- `gui/chiaking.desktop` uses `Icon=chiaking`, and the current Linux install rule installs `chiaking.png` under the hicolor icon theme.
- `scripts/macos/dmg-settings.py` references the bundled icon path. `assets/gen-icns.sh` provides an existing iconset workflow to inspect or adapt.

Use Vice-specific assets and the existing `CHIAKI_ENABLE_VICE_UI` / `CHIAKI_VICE_UI` mechanism where appropriate. Keep the Vice-disabled build's original icons working. Make minimal, clearly marked hooks rather than overwriting upstream artwork indiscriminately.

## Generate and wire the assets

1. Add a repeatable local generation command or script accepting the selected PNG master. Document dependencies and generated destinations; avoid new runtime dependencies or network downloads during normal builds.
2. Generate PNG sizes suitable for window/taskbar and Linux theme usage, including 16, 24, 32, 48, 64, 128, 256, 512, and 1024 pixels. Retain the original master separately. Use high-quality alpha-aware downsampling.
3. Generate a multi-resolution Windows `.ico` with the required small sizes and a 256px representation. Wire both executable and applicable installer artwork to the correct generated asset.
4. Generate macOS `.icns` with the standard iconset representations, including the 1024px image. Include it in the `.app` resources, set the bundle icon property correctly, and keep the DMG script consistent. Updating only `setWindowIcon` is not sufficient for Finder/Dock branding.
5. Install Linux PNGs into matching hicolor size directories with a consistent icon basename and update the Vice desktop entry's `Icon=` to that basename. Inspect AppImage/Flatpak/package paths that actually use these assets and keep them consistent without changing app identifiers unnecessarily.
6. Add Vice runtime icon resources and construct an appropriate `QIcon` for the application window/taskbar while preserving the upstream fallback. Ensure resources resolve from a clean build/install, not just from the source working directory.

Do not edit OS caches, installed shortcuts, or user applications without needing to for the requested build. Never claim that a generated icon file alone proves the launcher has updated.

## Verify and finish

- Verify output formats, dimensions, included ICO/ICNS sizes, and alpha transparency. Inspect the icon at 16, 32, 64, 128, and 256 pixels on light and dark surfaces.
- Check that the complete PROJECT VICE title remains as legible as possible at small sizes, the neon gradient retains its character, the icon has consistent optical size, and no black/white corner boxes or halos appear. Do not substitute an abbreviated mark without a new user instruction.
- Build with the available native toolchain. Inspect the built bundle/executable/resources and launch the app where possible to verify the window and OS launcher icon. Check the Vice-disabled path as well.
- Run or inspect relevant packaging paths. Clearly distinguish actual platform validation from source inspection when Windows/Linux/macOS tooling is unavailable.
- Update `VICE.md` with the master source, regeneration command, outputs, and any unverified platform checks. Report changed files, verification results, and preview paths. Do not commit or publish unless requested.

Implement the integration end to end; do not stop after copying the PNG into the repository.
