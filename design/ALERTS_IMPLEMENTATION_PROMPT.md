# Project Vice — alerts, dialogs, and application states

Implement the alert and application-state UI in the existing Project Vice Qt Quick/QML application. This is a focused implementation task: keep the approved screen layouts and add the reusable components, interactions, and integrations described below. Complete the work rather than only proposing a plan.

## Inspect the references first

- `design/01-home.png`: authoritative typography, palette, artwork treatment, buttons, and app shell.
- `design/11-alerts-and-states.png`: original alert/dialog component overview.
- `design/12-connection-lost-dialog.png`: connection-loss dialog over the dimmed home screen.
- `design/13-disconnect-confirmation.png`: disconnect confirmation over dimmed gameplay.
- `design/14-notification-components.png`: toast and inline notification variants.
- `design/15-empty-loading-validation.png`: empty, progress, and pairing-validation states.

The component sheets show alternate examples; do not implement a production page displaying every alert at once. The gameplay image is a mockup reference, not a background asset to insert into the real stream. Prefer the newer detailed references 12–15 for these components while retaining the visual system from 01.

Read applicable `AGENTS.md` instructions, `VICE.md`, `design/IMPLEMENTATION_PROMPT.md`, and current working-tree changes. Preserve unrelated changes. Reuse the existing C++/QML architecture, `CHIAKI_ENABLE_VICE_UI`, the `vice` file selector, `Chiaki` backend bindings, `Theme.qml`, existing components, and preview harness. Do not start a different app or reimplement the streaming engine.

## Visual requirements

Match the supplied images closely: deep navy surfaces, warm white heavy rounded headings, smaller readable body text, pale pink pill actions, subtle lavender borders, softly rounded panels, and a controlled navy background scrim. Use sage success, amber warning, coral error, and lavender informational icons. Status must remain understandable without color. Define all reusable dimensions, colors, spacing, and motion in the shared theme.

Use real QML controls and text, not screenshots with clickable hotspots. Keep dialogs readable at 720p, 1080p, 4K, and 100–200% display scaling. Let long or localized content wrap and scroll without hiding actions. A small dialog remains centered; it must not stretch to fill a large monitor. Keep the background recognizable but subordinate. Restrained blur is optional where supported and inexpensive; a navy scrim must work on every supported rendering path.

## Reusable structure

Extend existing equivalents or introduce components such as `AlertDialog`, `Toast`, `InlineAlert`, `EmptyState`, `ProgressState`, and `PinEntry` under `gui/src/qml/vice/`. Add a single notification host and a single dialog coordinator at the appropriate application/window layer. Register resources in `vice.qrc` and imports in the existing module structure.

Use explicit severity, title, body, icon, primary/secondary action, busy, dismissal policy, and operation identity properties. Keep backend commands in adapters or coordinators rather than embedding ad hoc actions throughout visual components. Only one modal should own focus at a time; handle an urgent connection failure by replacing or resolving a less important pending dialog predictably.

## Required interactions

| Case | Behavior |
| --- | --- |
| Connection lost | Show the dialog from reference 12 once per failed connection attempt/session. Replace stale online/telemetry values with unavailable state. `Try again` starts one supported retry and shows pending feedback; disable duplicate retries. `Back to consoles`, Close, and Back/Escape dismiss the failed-session state consistently. A locally detected failure must not assert that the console is definitely powered off. |
| End remote play | Match reference 13. Focus `Keep playing` by default; Close and Back/Escape do the same. Only explicit `Disconnect` ends the session. The console-power sentence must reflect whether the backend will leave the console on or put it into rest mode. Do not claim that opening the dialog pauses the console game. |
| Reconnect to apply | Preserve pending stream changes. Explain that reconnection briefly interrupts the stream; only `Reconnect` applies and starts the operation. `Cancel` leaves active settings untouched. Show pending and failure states without losing the user's proposed values. |
| Console linked | Show success only after pairing actually succeeds. Name the linked console; `Connect` targets that console. |
| Replay saved | Show success only after a real save completes. `Open folder` opens the actual saved file's containing directory using the supported cross-platform API. Unavailable capture must not report success. |
| Connection unstable | Use existing reliable measurements where available. Deduplicate/rate-limit repeated warnings; `Adjust stream` opens relevant controls. Do not invent a cause such as another device downloading. |
| Controller disconnected | Notify once, preserve keyboard/mouse operation, and expose controller settings. Clear or update the notice when the controller reconnects. |
| Settings saved | Confirm an actual successful settings operation, not a button click. Surface persistence failure separately. |
| RTX unavailable | Explain missing hardware/platform/plugin capability and route to available upscalers. Keep fallback choices usable. |
| No consoles | Match reference 15: `Add console` enters pairing/manual-add; `Search again` triggers supported discovery. Keep discovering, no results, and discovery failure distinguishable. |
| Waking/connecting | Show a cancellable, indeterminate pending state with truthful phase labels. Do not invent percentages or guaranteed time estimates. Cancel stops automatic continuation; it cannot undo a wake packet already sent. Ignore stale completion callbacks after cancellation. |
| Invalid/expired PIN | Explain the actual error; clear an expired code and focus the first field. Accept eight ASCII digits, whole-code paste, backspace, and accessible keyboard/controller entry. Disable submission until valid; prevent double submission and retain the console/account context. Do not log PINs or credentials. |
| No history | Show the empty-history illustration and `Go to consoles` action instead of fabricated rows or zero-valued statistics. |
| Unsaved changes | If the existing settings flow supports this, provide Save, Discard, and Keep editing using the shared dialog style. Default to keeping edits. |

## Notification and focus lifecycle

- Informational toasts do not steal focus. During gameplay show at most one compact nonblocking toast; elsewhere show at most three. Keep a bounded pending queue, deduplicate by event/console, and prioritize actionable failures over routine success.
- Routine success notices may auto-dismiss after approximately six seconds. Pause dismissal while hovered or keyboard-focused. Actionable failures stay until resolved or explicitly dismissed. Centralize durations in the theme/configuration and honor accessibility/reduced-motion preferences.
- Opening a modal captures focus and blocks interactions with the background. Suppress UI-navigation controller input from leaking into the live game while the modal owns it, using existing input-routing mechanisms and avoiding stuck buttons. Restore focus to the invoking control or a valid fallback on close.
- Adapt controller hints to the actual controller. Do not reproduce conflicting A/B and cross/circle hints shown in different parts of the mockups. Display a single context-appropriate hint set while a modal is open.
- D-pad, Tab/Shift-Tab, confirm, and Back/Escape must work predictably. Make focus, pressed, disabled, and pending states visually distinct. Provide accessible names, localized strings, and status announcements through the Qt facilities available in this project.
- Tie callbacks, subscriptions, and timers to operation/session identity. Dispose of them correctly when navigating away, closing a dialog, disconnecting, or destroying a window. A late result must not reopen an obsolete alert or report success for a different console.

## Integration and preview

Inspect existing backend methods/signals and connect real operations where available. Avoid adding parallel session state or inventing API names. Keep missing backend features clearly unavailable in production; provide deterministic fixtures for their UI in `gui/vice-preview/`. Do not turn this UI task into implementing RTX inference, replay capture, network instrumentation, or benchmark engines.

Extend the preview so every listed variant can be opened and dismissed independently, including pending-to-success, pending-to-failure, cancel-then-late-result, controller reconnect, long text, unavailable capability, and overlapping notification events. Preview controls and mock data must not appear as live production measurements.

## Validation and deliverables

Run the appropriate QML checks and available native build. Add focused behavioral tests for deduplication, cancellation/stale completion, single-action submission, and modal focus/input routing where feasible. Exercise actual keyboard navigation and controller navigation when a device is available; report untested hardware/platform paths accurately.

Capture implemented dialogs both over Home and over the stream/preview scene. Capture the notification and empty/progress/validation variants. Compare screenshots to references 11–15 and correct spacing, typography, focus, opacity, and overflow issues. Keep the Vice-disabled path and macOS/Windows/Linux compatibility intact.

Finish with changed files, how to open the preview states, screenshot paths, validation results, and unsupported backend integrations. Do not commit or publish unless requested. Completion means the full set is implemented in the preview, supported real events are connected, and unavailable operations are represented truthfully—not just a static alert gallery.
