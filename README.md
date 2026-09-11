# Teleprompter

A distraction-free script reader for people who record video. Write or paste a script, hit
**Start**, and read while the text scrolls smoothly past a fixed reading line — with speed,
text size, spacing, alignment, mirroring and colours all adjustable mid-take.

Everything is local. No account, no network, no analytics.

```
Script → Edit → Save → Start Teleprompter → Adjust speed → Read → Finish
```

---

## Highlights

| | |
|---|---|
| **Smooth scrolling engine** | Frame-driven, velocity-planned, jitter-free at any refresh rate. One scroll-offset write per frame, zero widget rebuilds. |
| **Gets out of the way** | Controls hide ~4 s after you start reading, reveal the instant you touch the screen, and never cover the text while you read. |
| **Gesture control** | Swipe to scrub manually (auto-scroll waits for you), tap to show/hide controls, double tap to pause/resume. |
| **Adjustable on the fly** | Speed, text size, line height, paragraph spacing, alignment, typeface, palette and mirror — all changeable without leaving the session. |
| **Mirror mode** | For beam-splitter prompter glass. Presentation only — the stored script is never modified. |
| **Works with long scripts** | 5,000-word scripts open instantly and scroll at the same per-frame cost as a one-line script (verified by test). |
| **Offline first** | Scripts and settings live on the device. The app launches and works with no connectivity, always. |
| **Any orientation** | Portrait and landscape, phone to tablet, with responsive layouts and a compact prompter control layout on short screens. |

---

## Quick start

```bash
flutter pub get
flutter run                 # phone, tablet, desktop or web
flutter analyze             # clean
flutter test                # 45 tests
```

Requires Flutter 3.47+ / Dart 3.13+ (built and verified against **Flutter 3.47.3, Dart 3.13.3**).

---

## Architecture

Clean Architecture with a strict one-way dependency rule. Widgets never touch storage, and
no business rule lives in a `build()` method.

```
Widget  →  Cubit  →  UseCase  →  Repository  →  LocalDataSource  →  shared_preferences
                    (domain)     (domain iface)   (data impl)
```

```
lib/
├── app.dart                       # MaterialApp.router + global providers
├── main.dart                      # boots storage, then the app
├── core/
│   ├── constants/                 # app constants, layout tokens, storage keys
│   ├── di/app_dependencies.dart   # composition root (wires every layer once)
│   ├── errors/                    # exceptions · failures · Result<T> · guard()
│   ├── router/                    # go_router config + route name constants
│   ├── services/                  # KeepAwakeService + KeepAwakeScope
│   ├── theme/                     # colours, typography, palettes, script fonts
│   ├── utils/                     # TextMetrics, DateTimeFormat, IdGenerator
│   └── widgets/                   # shared kit: cards, sheets, dialogs, sliders…
└── features/teleprompter/
    ├── data/
    │   ├── datasources/           # KeyValueStore + script/settings sources
    │   ├── models/                # JSON models with defensive readers
    │   └── repositories/          # implementations of the domain contracts
    ├── domain/
    │   ├── entities/              # Script, TeleprompterSettings, AppSettings
    │   ├── repositories/          # interfaces only
    │   └── usecases/              # GetScripts, SaveScript, ComputeScrollSpeed…
    └── presentation/
        ├── bloc/                  # ScriptListCubit, ScriptEditorCubit,
        │                          # TeleprompterCubit, AppSettingsCubit
        ├── engine/                # TextScrollController (the scrolling engine)
        ├── pages/                 # home, editor, teleprompter, settings, 404
        ├── widgets/               # prompter surface, controls, sheets, cards
        └── dialogs/               # rename / delete confirmations
```

### Why this shape

- **`Result<T>` instead of thrown exceptions across layers.** Use cases return `Ok`/`Err`;
  cubits switch on the result, so error handling is visible in the type signature and every
  failure becomes a friendly message before it reaches a widget.
- **Use cases own the rules.** Title normalisation, `createdAt` preservation, duplicate
  naming and speed/size clamping all happen in `domain/usecases`, so no screen has to
  remember them.
- **Defensive serialisation.** Persisted JSON is treated as untrusted: malformed records are
  skipped, out-of-range numbers fall back to defaults, corrupt payloads degrade to "nothing
  saved yet" instead of crashing on launch.
- **One writer per store.** Script writes are queued through a serialised chain; settings
  writes are debounced, so dragging a slider produces one disk write, not eighty.

---

## The scrolling engine

`presentation/engine/text_scroll_controller.dart` is the core of the app.

- **Frame-driven, not timer-driven.** An `AnimationController` drives the motion, so text
  advances exactly once per rendered frame — identical velocity on 60/90/120 Hz and no drift
  over a 30-minute read. A `Timer` would drift and stutter under load.
- **Velocity, not position.** The animation's duration represents the *whole* remaining range,
  and Flutter scales it by the distance actually left. Changing speed, resuming after a scrub
  or rotating the device re-plans from the current position — so the text never jumps.
- **Zero rebuilds while scrolling.** The offset is written straight into the `ScrollPosition`
  (`jumpTo`) each frame; no widget is rebuilt, nothing is laid out again.
- **Speed that means the same thing everywhere.** The 0–1 setting maps to *lines per second*
  (non-linear, with fine control at the slow end) and is then scaled by the rendered line
  box. 0.5 feels identical at 20 pt and at 100 pt, on a phone and on a tablet.
- **Stops burning frames when idle.** Paused or completed, the ticker stops scheduling.
- **Honest end handling.** A script that fits on one screen never reports "finished" the
  moment you start; the completion overlay appears only when the last line has genuinely
  passed the reading line.

---

## Screens

### Home
Header with the app mark, a large **+ New Script** action, and script cards showing title,
preview, last edited, word count and estimated read time. Each card has a play button that
goes straight to the prompter, plus rename / edit / duplicate / delete. Deleting offers
**Undo**. Empty state: *"Your scripts will appear here."*

### Editor
A writing surface, not a form: borderless text area, inline title in the app bar, live
word / character / paragraph / read-time counters, auto-save with an honest status
("Unsaved" → "Saving…" → "Saved 2m ago"), undo/redo wired to the text field's own history,
and a bottom toolbar for text size, alignment, mirror, spacing and the full setup sheet.
`Ctrl/⌘+S` saves, `Ctrl/⌘+↵` saves and starts.

### Teleprompter
Full screen, immersive, one job. The script starts with its first line on the reading line
and scrolls upward. A hairline guide with a centre notch marks the reading line (toggleable).
A thin progress bar rides the bottom edge and the top bar shows the exact percentage.
Transport: play/pause, restart, ±speed, text size, mirror, guide, settings, exit. On short
screens (landscape phones) the panel collapses to one dense row.

Keyboard: `Space` play/pause · `↑/↓` (or `←/→`, `+/-`) speed · `R` restart · `M` mirror ·
`G` guide · `Esc` exit.

### Settings
Prompter defaults (speed, text size, line height, paragraph spacing, reading guide, mirror,
alignment, typeface, canvas palette, custom colours) with a live preview strip, app theme
(Dark / Light / System), keep-screen-awake, reset-to-defaults and an About panel listing the
shortcuts.

---

## Design decisions

**Dark first.** The app is used in dim rooms next to cameras, so the dark palette is the
default and the light one is a complete counterpart, not an afterthought.

**The prompter canvas is independent of the app theme.** A reader may want a paper-white
canvas while the rest of the app stays dark. Four palettes ship — Classic (black/white),
Warm (low-glare amber on charcoal), Light (paper) and Custom (a curated 24-swatch picker,
because prompter colours must stay high-contrast and glare-free rather than arbitrary).

**The reading line sits at 38% of the height**, slightly above centre — where a reader's eye
naturally rests and where the next lines are visible without moving the head.

**Four bundled typefaces.** Inter (neutral sans), Atkinson Hyperlegible (maximum legibility),
Lora (serif for long reads) and JetBrains Mono (narration). All ship with the app, so
rendering is identical offline on every platform — no runtime font fetching.

**Real gestures, no conflicts.** The instant a finger touches the screen the controls appear
(driven by a raw pointer-down, because a double-tap recogniser would otherwise delay it by
~300 ms). Only *hiding* waits for a confirmed single tap, so tapping doesn't fire while you
double tap to pause. Dragging the text pauses auto-scroll and — if it was running — resumes
shortly after you let go, from where you left it.

**Keep screen awake without a plugin.** A 12-line platform channel
(`teleprompter/screen`) sets `FLAG_KEEP_SCREEN_ON` on Android and `isIdleTimerDisabled` on
iOS, re-applies it when the app returns to the foreground and releases it on exit. Desktop
and web resolve to a no-op.

**Lifecycle correctness.** Backgrounding the app mid-read pauses the session rather than
letting the script run on unwatched; rotating the device (or changing font size) keeps the
reader's place *in the script*, not in pixels.

---

## Edge cases handled

Empty and whitespace-only scripts · very long scripts (5,000+ words) · extremely short
scripts that fit on one screen · maximum font size · minimum (creeping) and maximum speed ·
portrait ⇄ landscape ⇄ window resize · app backgrounded mid-read · script reaching the end ·
deleting the script you are reading · duplicate names (allowed — it renames to "… copy") ·
keyboard opening and closing · saving while typing · saving an untouched draft · no saved
scripts at all · storage unavailable (falls back to in-memory and keeps working) · corrupt
stored data (degrades instead of crashing) · deep links to deleted scripts (friendly "no
longer available" state, never a red screen).

---

## Tests

```bash
flutter test        # 45 tests
flutter analyze     # no issues
```

| File | Covers |
|---|---|
| `text_metrics_test.dart` | Word/paragraph counting, previews, read-time estimates, 5,000-word input |
| `compute_scroll_speed_test.dart` | Speed curve is monotonic, capped, clamped, and scale-invariant across font sizes |
| `script_repository_test.dart` | CRUD, title normalisation, `createdAt` preservation, idempotent delete, duplicates, corrupt/partial storage, ordering |
| `script_list_cubit_test.dart` | Load/create/rename/duplicate/delete/undo and the "missing script" no-op |
| `text_scroll_controller_test.dart` | Advancing at the requested rate, completion, pause freezing position, restart, short scripts, very slow speeds |
| `reading_guide_test.dart` | The guide is actually laid out and painted (regression test) |
| `teleprompter_surface_test.dart` | Guide + progress bar geometry, tap-to-hide/show, double tap, instant reveal |
| `widget_test.dart` | End-to-end: empty state → create → edit → save → prompter scroll → pause → speed nudge → drag → exit; delete + undo |
| `responsive_layout_test.dart` | Every screen at 320 px, landscape phone and tablet sizes |
| `long_script_test.dart` | A 5,000-word script loads, scrolls, and costs no more per frame than a one-line script |

Two real bugs were found and fixed by these tests during development: the reading guide and
the progress bar both collapsed to zero width (painting nothing) because a height-only
`SizedBox` inside a loose constraint has no width; and the home header and editor toolbar
overflowed at 320 px.

---

## Platform notes

- **Android / iOS** — full support, including keep-screen-awake.
- **Web / desktop** — fully functional (keyboard shortcuts included); keep-screen-awake is a
  no-op because the platform has no equivalent hook.
- **Build Linux desktop:** requires `clang cmake ninja-build pkg-config libgtk-3-dev`.
- **Android release builds** need a JDK in Gradle's supported range (17–25); the generated
  project pins Gradle 9.3.1.

## Persistence format

Two `shared_preferences` keys, both versioned JSON:

- `teleprompter.scripts.v1` — array of `{id, title, content, createdAt, updatedAt}`
- `teleprompter.app_settings.v1` — `{themeMode, keepScreenAwake, teleprompter:{…}}`
- `teleprompter.settings.v1` — prompter defaults on their own, so a session never rewrites
  the whole settings blob

---

## Licence

Bundled typefaces: Inter, Lora and JetBrains Mono (SIL Open Font License 1.1) and Atkinson
Hyperlegible (SIL OFL 1.1) — see `assets/fonts/`.
