# Project Vice — approved UI implementation prompt

Implement the approved Project Vice desktop UI in this repository. The fifteen numbered PNG files beside this document are the visual specification. Inspect every image before editing. `design/01-home.png` is the primary reference for the entire visual system; the other images extend that approved style. Build the working interface, rather than proposing another design or stopping after a plan. For alerts, dialogs, notifications, loading, empty, and validation states, also follow `design/ALERTS_IMPLEMENTATION_PROMPT.md`.

## Scope and existing architecture

- This is an existing C/C++ and Qt Quick/QML fork of chiaki-ng, targeting macOS, Windows, and Linux. Extend that application; do not create a website, Electron shell, Flutter application, or replacement streaming engine.
- Read applicable `AGENTS.md` instructions, `VICE.md`, the current working-tree changes, and the existing UI before editing. Preserve unrelated and in-progress work. Do not initialize another Git repository or reset existing changes.
- Start with `gui/src/qml/vice/Theme.qml`, `vice/components/`, `vice/screens/Home.qml`, `gui/src/qml/+vice/MainView.qml`, `gui/src/qml/vice.qrc`, and `gui/vice-preview/`.
- Preserve the `CHIAKI_ENABLE_VICE_UI` build option and Qt `vice` file-selector mechanism. Keep new screens and components under `gui/src/qml/vice/`; add the smallest necessary replacement adapters under `+vice/`. Register new resources and singleton/component imports correctly.
- Reuse `QmlBackend`, `QmlSettings`, `StreamSession`, and their existing QML exposure through `Chiaki`. Inspect the actual interfaces before binding to them. Keep upstream changes small and marked consistently with the existing `vice hook` convention.
- Implement the UI and integrate available capabilities. New latency tuning, network measurement, replay capture, benchmark instrumentation, and RTX processing are separate backend work when not already implemented. Do not silently expand this into a rewrite of those systems.

## Visual fidelity

Match the approved images closely, including layout, spacing, artwork placement, hierarchy, proportions, and selected states. This is implementation of an approved direction, not another aesthetic exploration.

- Deep navy background, approximately `#10111F`; pale pink primary controls, approximately `#F5BCCD`; warm white text; restrained lavender borders and secondary surfaces. Sample the images to refine these starting values.
- Reproduce the compact stacked white **PROJECT VICE** wordmark and short pink dash. Use heavy, rounded, upright display typography and readable smaller labels. The existing Manrope font is available, but do not assume it alone matches the reference: inspect rendered type and choose appropriate licensed font assets and weights if needed.
- Preserve the GTA VI artwork composition and pastel peach, pink, and lavender atmosphere. The home screen has artwork on the right and a navy gradient on the left. Keep character faces visible, and maintain contrast behind controls.
- Use pale pink pill buttons, outlined secondary buttons, clear pink focus states, subtle translucent navy panels, and the same icon weight throughout. Do not introduce cyan neon, italic racing typography, grunge, orbit graphics, oversized console hardware, or a generic dashboard redesign.
- Put reusable colors, typography, spacing, radii, control heights, opacity, and motion values in `Theme.qml`. Use an 8-unit spacing rhythm and responsive layouts rather than scattering fixed coordinates throughout screens.
- Render controls, text, icons, and focus rings as real QML elements. Do not display a complete mockup PNG as the functioning interface or place invisible hotspots over it. Prepare separate background/artwork assets. Record their source separately from the source-code license; the source artwork reference is https://www.rockstargames.com/VI/media/artwork-wallpapers.
- Ordinary pages share the wordmark, Consoles/Sessions/Settings navigation, avatar area, and contextual footer. Gameplay is edge-to-edge video with only the optional overlay and quick menu. Dense settings and results pages reduce the artwork to preserve readability.

## Screens and behavior

| Reference image | Required implementation |
| --- | --- |
| `design/01-home.png` | Console discovery and selection, truthful online/rest/offline states, connect, wake, add console, and connection-check entry. Support zero, one, two, and many consoles. Preserve original backend indices or stable identifiers when filtering hosts, and retain selection across discovery refreshes. |
| `design/02-pair-console.png` | Account/link/ready wizard, existing PSN sign-in integration, eight-digit PIN entry, console name, progress, retry, cancellation, validation, and success. Support pasting a complete PIN and keyboard/controller entry. Mark the account connected only after real success. |
| `design/03-connection-check.png` | Cancellable connection-check flow with progress, results, link type, ping, jitter, packet loss, recommendation, and retry. Display actual measurements where available; do not invent them. |
| `design/04-choose-mode.png` | Game/Quality selection, clear selected state, profile selector, console summary, and start/back actions. Apply only supported preset settings and preserve the user's selection. |
| `design/05-gameplay.png` | Keep the existing video renderer and input path working. Add the compact optional performance overlay and quick-menu affordance. The pictured driving scene is a design placeholder, not application wallpaper or bundled gameplay. |
| `design/06-quick-menu.png` | Mode, upscaler, bitrate, overlay toggle, replay action, resume, and disconnect. Reflect real capability availability. If a setting needs reconnection, preserve pending values and explain that before applying. |
| `design/07-video-settings.png` | Grouped Video/Network/Input/Audio/Advanced navigation, video controls, capability-aware upscaling/HDR, persistence, validation, save/reset, and unsaved-change handling. Extend the same design language to categories without a separate mockup. |
| `design/08-input-profiles.png` | Profile creation/selection, supported mode and controller settings, deadzones/curves where available, controller status/test, restore defaults, and save. Do not imply automatic game detection unless implemented. |
| `design/09-session-history.png` | Local history, selected session, actual recorded duration and available metrics, empty state, and benchmark entry. Missing values must not appear as zero. |
| `design/10-benchmark-results.png` | Benchmark progress/results UI, comparable before/after charts, run again, and image export where supported. Preserve units and scale bar lengths correctly. Client receive-to-present time must not be labelled end-to-end latency. |
| `design/11-alerts-and-states.png` | Reusable success/warning/error toasts and confirmation dialogs. This image is a component review sheet, not a destination showing six simultaneous alerts. |
| `design/12-connection-lost-dialog.png` | Connection-loss dialog in context, with unavailable/disconnected background state, retry, return, and keyboard/controller focus. |
| `design/13-disconnect-confirmation.png` | In-game disconnect confirmation. Keep playing is the focused default. Match the console-power message to the actual selected disconnect behavior. |
| `design/14-notification-components.png` | Six notification variants: pairing success, replay saved, unstable network, controller disconnected, settings saved, and unavailable RTX upscaling. |
| `design/15-empty-loading-validation.png` | No consoles, cancellable wake progress, expired pairing code with validated PIN entry, and empty session history. |

Implement the six pictured alert cases: console linked, unstable connection, replay saved, connection lost, disconnect confirmation, and reconnect-to-apply confirmation. Also cover no consoles found, discovering, waking, connecting, invalid/expired pairing code, controller disconnected, unavailable upscaler, and empty history. Derive their appearance from the approved components.

Use short actionable messages, status icons as well as colors, an appropriate dismissal policy, and a bounded notification queue. Critical failures remain visible until addressed. Dialogs trap focus, restore it on close, and give controller/keyboard users a clear cancellation path. Default disconnect confirmation to keeping the session active. Closing the quick menu must not disconnect.

## Real data and preview separation

- First inventory which operations and measurements the backend actually provides. Wire existing functionality end to end rather than replacing it with fake interactions.
- Extend `gui/vice-preview/` so all screens and states can be reviewed without a console. Use deterministic mock adapters there, clearly separated from production bindings. Never ship mock success responses, static benchmark values, or fabricated telemetry as live functionality.
- For unavailable capabilities, keep the complete preview state and show an honest, capability-based disabled or unavailable state in the real app. A button must either perform its action, expose a clear pending/progress state, or explain why it is unavailable.
- RTX-specific controls depend on actual GPU, platform, and plugin availability. macOS, Linux, and non-RTX configurations must remain usable with available alternatives. Never equate an upscaled 4K display with a native 4K console stream.
- Preserve existing authentication and credential storage, session behavior, controller mappings, and settings compatibility. Do not add telemetry.

## Interaction and responsive behavior

- Every flow must work with mouse, keyboard, and controller. Implement explicit focus order, visible focus, D-pad navigation, confirm/back, and modal focus restoration. Adapt controller glyphs to the connected device; the A/B labels in the mockups are not mandatory for DualSense.
- Keep text and control sizes readable from a couch. Check 1280×720, 1920×1080, and 3840×2160 layouts and 100%, 150%, and 200% display scaling. Use scrolling or reflow when needed rather than clipping controls or shrinking type excessively.
- Use restrained transitions, roughly 120–220 ms, with reduced-motion support. Stop decorative animation when hidden or during streaming. Avoid effects that materially add GPU cost over active video.
- Provide accessible names for icon controls and distinguish hover, focus, pressed, disabled, pending, success, warning, and error states. Localize user-facing strings using the existing QML translation conventions.

## Execution and verification

1. Inspect all references and current code; map screens to existing backend capabilities and preview-only states.
2. Update shared theme, typography, artwork assets, shell, and reusable controls; implement Home to establish the approved appearance.
3. Implement the remaining screens and shared alert/dialog system, then wire navigation and supported operations. Continue through the whole scope without requiring approval at each screen.
4. Extend the preview harness with deterministic fixtures for every screen, console count, connection state, and alert. Keep production and preview data separate.
5. Run relevant QML/static checks and build the native app with the available toolchain. Exercise keyboard/controller navigation, pairing validation, modal cancellation, focus restoration, capability gating, and dynamic console lists. Add focused tests for nontrivial behavior where useful.
6. Render screenshots of every implemented screen and compare them visually with the corresponding `design/` PNG. Correct meaningful differences in layout, typography, artwork crops, color, and control size. Check overflow at the target sizes and scaling factors.
7. Keep the Vice-disabled build path working. Verify cross-platform code paths and build configuration; report platform builds or real-console checks that could not actually be run, without claiming they passed.
8. Update `VICE.md` with implementation status, preview/run instructions, and genuinely missing backend capabilities. Finish with changed files, screenshot locations, validation results, and remaining limitations. Do not commit or publish unless separately requested.

Completion means all pictured screens and their key states are implemented and navigable in the preview, supported production operations use the real backend, unavailable operations are represented truthfully, and the visual result closely matches the approved images. Do not stop after a home-screen reskin.
