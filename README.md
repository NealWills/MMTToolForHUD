<p align="center">
    <img src="MMTToolForHUD@1x.png" alt="MMTToolForHUD demo" width="1063">
</p>

# MMTToolForHUD

[![tests](https://github.com/NealWills/MMTToolForHUD/actions/workflows/tests.yml/badge.svg)](https://github.com/NealWills/MMTToolForHUD/actions/workflows/tests.yml)
[![Version](https://img.shields.io/cocoapods/v/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)
[![License](https://img.shields.io/cocoapods/l/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)
[![Platform](https://img.shields.io/cocoapods/p/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)

A lightweight, thread-safe HUD library for iOS 13+ with **toast**, **loading**
and **progress** support. Zero third-party dependencies, built on UIScene,
fully customizable through a single `MMTToolForHUDConfig`.

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Behavior notes](#behavior-notes)
- [API reference](#api-reference)
- [Configuration reference](#configuration-reference)
- [UI automation & Appium](#ui-automation--appium)
- [Example app](#example-app)
- [Testing](#testing)
- [Documents & reports](#documents--reports)
- [Project layout](#project-layout)
- [Contributing](#contributing)
- [Author](#author)
- [License](#license)

## Documents & reports

| Resource | Link |
|---|---|
| Latest changelog (0.6.3) | [`Changelogs/0.6.3.md`](Changelogs/0.6.3.md) |
| All changelogs (per version) | [`Changelogs/`](Changelogs) |
| Latest performance report (tag 0.6.3) | [`perf-report-0.6.3.md`](PerformanceReports/perf-report-0.6.3.md) |
| Latest performance report (machine-readable) | [`perf-report-0.6.3.json`](PerformanceReports/perf-report-0.6.3.json) |
| All performance reports (history) | [`PerformanceReports/`](PerformanceReports) |
| Latest performance test run log | [`last-run.log`](PerformanceReports/last-run.log) |
| Unit + performance test suite | [`Example/Tests/Tests.swift`](Example/Tests/Tests.swift) |
| Appium end-to-end guide | [`Appium/README.md`](Appium/README.md) |
| Appium test spec | [`Appium/specs/hud.spec.js`](Appium/specs/hud.spec.js) |
| Appium capabilities | [`Appium/wdio.conf.js`](Appium/wdio.conf.js) |
| Example demo app source | [`Example/MMTToolForHUD/ViewController.swift`](Example/MMTToolForHUD/ViewController.swift) |
| Performance runner script | [`scripts/run-performance-tests.sh`](scripts/run-performance-tests.sh) |
| Podspec | [`MMTToolForHUD.podspec`](MMTToolForHUD.podspec) |
| License | [`LICENSE`](LICENSE) |

Performance reports are committed to the repository. The filename carries
the version tag (`perf-report-<version>.md/.json`) and every run replaces
the report for its version, so each tag keeps exactly one final report
under `PerformanceReports/`. Every release also adds
`Changelogs/<version>.md` describing what changed since the previous
version; keep it in sync with the release notes in
`MMTToolForHUD.versionDescription`.

## Project layout

The public API lives in a single file; everything else is internal
implementation.

| File | Visibility | Contents |
|---|---|---|
| [`MMTToolForHUD.swift`](MMTToolForHUD/Classes/MMTToolForHUD.swift) | Public | `MMTToolForHUD`, `MMTToolForHUDToast`, `MMTToolForHUDConfig`, progress / toast style enums, accessibility IDs |
| [`MMTToolForHUDPresenter.swift`](MMTToolForHUD/Classes/MMTToolForHUDPresenter.swift) | Internal | Per-window HUD presentation controller, threading helpers |
| [`MMTToolForHUDToastManager.swift`](MMTToolForHUD/Classes/MMTToolForHUDToastManager.swift) | Internal | Toast stacking manager, container and item views |
| [`MMTToolForHUDContainerView.swift`](MMTToolForHUD/Classes/MMTToolForHUDContainerView.swift) | Internal | Full-window HUD container, touch interception |
| [`MMTToolForHUDContentView.swift`](MMTToolForHUD/Classes/MMTToolForHUDContentView.swift) | Internal | HUD panel, ring / bar indicator views |
| [`MMTToolForHUDWindowFinder.swift`](MMTToolForHUD/Classes/MMTToolForHUDWindowFinder.swift) | Internal | UIScene front-window resolution |

## Features

- **Toast** — stackable capsules at the top, center or bottom; auto-dismiss;
  success / error / info icons; long-text wrapping; never blocks touches
- **Loading** — spinner with optional multi-line text; strictly modal or
  panel-only touch interception
- **Progress** — bar and ring styles, live updates with animated transitions
  and an automatic percentage readout
- **Status flash** — auto-dismissing success (checkmark) and error (cross)
  icons
- **Per-window management** — every show / dismiss call targets one window,
  so multiple windows display fully independent HUDs and toasts
- **Sticky panel width** — while a HUD is visible its panel only grows;
  text changes never shrink it and the text always stays centered
- **Thread-safe** — every API can be called from any thread
- **Automatable** — stable accessibility identifiers for XCUITest / Appium

## Requirements

- iOS 13.0+
- Swift 5.0+

## Installation

MMTToolForHUD is available through [CocoaPods](https://cocoapods.org). Add
the following line to your Podfile:

```ruby
pod 'MMTToolForHUD'
```

## Quick start

Import the module once:

```swift
import MMTToolForHUD
```

Every API below also accepts a trailing `in: UIWindow?` parameter to target
a specific window (the front window by default). See
[Behavior notes](#behavior-notes).

### Toast

```swift
MMTToolForHUDToast.show("Saved")                        // bottom, auto-dismiss
MMTToolForHUDToast.show("Top notice", position: .top)   // explicit position
MMTToolForHUDToast.show("Centered", position: .center)
MMTToolForHUDToast.success("Submitted successfully")    // green checkmark
MMTToolForHUDToast.error("Network error")               // red cross
MMTToolForHUDToast.info("Update available")             // blue info icon
MMTToolForHUDToast.show("Stays 5s", duration: 5)        // custom duration
MMTToolForHUDToast.dismissAll()                         // clear every window
MMTToolForHUDToast.dismissAll(in: someWindow)           // clear one window
```

Toasts stack vertically at their position, wrap long text automatically and
auto-dismiss in reverse order of appearance.

### Loading

```swift
MMTToolForHUD.showLoading()                    // spinner only
MMTToolForHUD.showLoading("Loading, please wait…")
MMTToolForHUD.dismiss()                        // hide the front-window HUD
MMTToolForHUD.dismiss(after: 2)                // auto-hide after 2 seconds
```

### Progress

```swift
MMTToolForHUD.showProgress(0.0, text: "Downloading")              // bar (default)
MMTToolForHUD.showProgress(0.0, text: "Downloading", style: .ring)
MMTToolForHUD.updateProgress(0.5)                                  // live update
MMTToolForHUD.updateProgress(0.8, text: "Almost done")             // update text too
```

Progress is clamped to `0.0...1.0`. The percentage is rendered automatically
(in the ring center, or appended to the text for bars) and updates animate.

### Status flash

```swift
MMTToolForHUD.showSuccess("Submitted")   // checkmark, auto-dismiss (1.6s default)
MMTToolForHUD.showError("Failed")        // cross, auto-dismiss
```

### Configuration

```swift
// Global; applies to HUDs and toasts presented afterwards.
MMTToolForHUD.updateConfig {
    $0.spinnerColor = .systemOrange
    $0.successIconColor = .systemGreen
    $0.errorIconColor = .systemRed
    $0.interactionStyle = .blockAll     // .blockHUD / .blockAll / .passThrough
    $0.toastDuration = 3
    $0.toastPosition = .top
    $0.progressStyle = .ring
}

// or assign a whole value
var config = MMTToolForHUDConfig()
config.animationDuration = 0.35
MMTToolForHUD.config = config
MMTToolForHUDToast.config = config      // same underlying configuration
```

> **Pitfall:** `MMTToolForHUDConfig` is a value type, so
> `MMTToolForHUD.config.animationDuration = 0.35` mutates a temporary copy
> and has **no effect**. Always use `updateConfig { … }` or assign a
> complete value as shown above.

## Behavior notes

**Windows.** Every show / dismiss / query API takes an optional `in:`
window (the front window by default) and only manages the content attached
to that window. Showing a HUD on another window never disturbs the first
one; `dismiss(in:)` only hides that window's HUD; toasts are stored per
(window, position).

```swift
MMTToolForHUD.showLoading("Loading", in: someWindow)
MMTToolForHUD.updateProgress(0.4, in: someWindow)
MMTToolForHUD.isVisible(in: someWindow)       // -> true
MMTToolForHUD.currentProgress(in: someWindow) // -> 0.4
MMTToolForHUD.dismiss(in: someWindow)
```

**Content updates reuse the visible panel.** Calling any show API while a
HUD is already visible on that window replaces its content in place — the
spinner can become a progress bar or a success icon without re-animating
the panel.

**Sticky panel width.** While a HUD is visible its panel only ever grows:
shorter text keeps the wider panel so the layout never jitters (e.g.
`"Downloading 45%"` → `"Done 100%"`). The text label spans the full panel
and centers its content, so text always swaps in place. A fresh
presentation starts from the natural width again.

**Touch interception** (HUD only; toasts are always pass-through):

| Style | Behavior |
|---|---|
| `.blockHUD` (default) | Touches on the panel are swallowed; everything else passes through |
| `.blockAll` | The whole screen blocks interaction (strictly modal loading) |
| `.passThrough` | Nothing is blocked |

**Thread safety.** All public APIs dispatch to the main thread when needed;
call them freely from background queues.

**Auto-dismiss.** `showSuccess` / `showError` schedule a dismissal after
`statusAutoDismissDelay` seconds. Any subsequent show call on the same
window cancels that timer. `dismiss(after:)` targets whatever HUD is on
the window when the delay elapses — including one shown after scheduling.

**Keyboard.** HUDs and toasts do not avoid the keyboard; bottom toasts may
be covered while a keyboard is visible. Position toasts at `.top` in
keyboard-heavy screens if that matters.

## API reference

### MMTToolForHUD

| API | Description |
|---|---|
| `version` | Library version string (e.g. `"0.6.3"`), kept in sync with the podspec |
| `versionDescription` | Release notes: what changed in the current version since the previous release |
| `showLoading(_:in:)` | Spinner with optional text |
| `showProgress(_:text:style:in:)` | Bar or ring progress |
| `updateProgress(_:text:in:)` | Update the visible progress (ignored when none is shown) |
| `showSuccess(_:in:)` | Checkmark status, auto-dismisses |
| `showError(_:in:)` | Cross status, auto-dismisses |
| `dismiss(in:animated:completion:)` | Hide the HUD on a window |
| `dismiss(after:in:animated:completion:)` | Hide after a delay |
| `isVisible` / `isVisible(in:)` | Whether a HUD is showing (any / given window) |
| `currentProgress` / `currentProgress(in:)` | Current progress, nil when not showing |
| `config` / `updateConfig(_:)` | Global configuration |

### MMTToolForHUDToast

| API | Description |
|---|---|
| `show(_:duration:position:in:)` | Plain text toast |
| `success(_:duration:position:in:)` | Green checkmark toast |
| `error(_:duration:position:in:)` | Red cross toast |
| `info(_:duration:position:in:)` | Blue info toast |
| `dismissAll(in:)` | Clear toasts (`nil` clears every window) |
| `isVisible` / `isVisible(in:)` | Whether a toast is showing |
| `config` | Alias of `MMTToolForHUD.config` |

## Configuration reference

All options live on `MMTToolForHUDConfig` and apply to presentations made
after the change.

### General

| Option | Description | Default |
|---|---|---|
| `isAnimationEnabled` | Enable show / hide animations | `true` |
| `animationDuration` | Animation duration (seconds) | `0.25` |
| `statusAutoDismissDelay` | Success / error auto-dismiss delay | `1.6` |
| `interactionStyle` | Touch interception policy | `.blockHUD` |

### HUD panel

| Option | Description | Default |
|---|---|---|
| `hudBackgroundColor` | Panel background | near-black (0.06, 0.9) |
| `textColor` / `textFont` | Text appearance | white / 14pt medium |
| `cornerRadius` | Panel corner radius | `16` |
| `hudPadding` | Padding between panel edge and content | `16` |
| `hudTextSpacing` | Gap between indicator and text | `6` |
| `hudMargin` | Minimum distance to screen edges | `28` |

### Colors

All default colors are fixed RGB values created with
`UIColor(red:green:blue:alpha:)`; they render identically in light and dark
mode and are never swapped by the system.

| Option | Description | Default |
|---|---|---|
| `spinnerColor` | Loading spinner render color | white (RGB 1, 1, 1) |
| `successIconColor` | Success icon render color | fixed green (52, 199, 89) |
| `errorIconColor` | Error icon render color | fixed red (255, 59, 48) |
| `tintColor` | Progress tint (bar, ring, percent label) | white (RGB 1, 1, 1) |

### Progress

| Option | Description | Default |
|---|---|---|
| `progressStyle` | Style used when `showProgress` omits one | `.bar` |
| `barProgressWidth` / `barProgressHeight` | Bar dimensions | `132` / `5` |
| `ringProgressRadius` / `ringProgressLineWidth` | Ring dimensions | `21` / `4` |
| `progressTrackColor` | Track color behind the fill | white 28% |

### Toast

| Option | Description | Default |
|---|---|---|
| `toastBackgroundColor` | Capsule background | near-black (0.06, 0.92) |
| `toastTextColor` / `toastFont` | Text appearance | white / 14pt medium |
| `toastCornerRadius` | Capsule corner radius | `8` |
| `toastDuration` | Default duration (seconds) | `2.0` |
| `toastPosition` | Default position | `.bottom` |
| `toastMargin` | Distance to the safe-area edges | `20` |
| `toastSpacing` | Gap between stacked toasts | `10` |

## UI automation & Appium

### Stable accessibility identifiers

Every HUD, toast and demo control exposes a stable accessibility identifier,
queryable with the **"accessibility id"** strategy. Identifier format:
`MMTToolForHUD.<area>.<element>[.<detail>]` — renaming is considered a
breaking change.

Library identifiers (defined in `MMTToolForHUDAccessibilityID`):

| Identifier | Element | Accessibility label |
|---|---|---|
| `MMTToolForHUD.hud.panel` | The HUD panel container | — |
| `MMTToolForHUD.hud.spinner` | Loading spinner | "Loading" |
| `MMTToolForHUD.hud.progress.ring` | Ring progress | current percent, e.g. "45%" |
| `MMTToolForHUD.hud.progress.bar` | Bar progress | current percent, e.g. "45%" |
| `MMTToolForHUD.hud.status.icon` | Success / error icon | "Success" / "Error" |
| `MMTToolForHUD.hud.text` | HUD text label | the text itself |
| `MMTToolForHUD.toast.item` | Any toast view (shared id) | the toast text |

Example app controls use `MMTToolForHUD.demo.<section>.<name>`:

| Section | Identifiers |
|---|---|
| Toast | `…demo.toast.bottom` / `.top` / `.center` / `.icons` / `.long-text` / `.dismiss-all` |
| Loading | `…demo.loading.spinner` / `.text` / `.block-all` |
| Status | `…demo.status.success` / `.error` |
| Progress | `…demo.progress.bar` / `.ring` |
| Config | `…demo.config.colors` |
| Headers | `…demo.section.toast` / `.loading` / `.status` / `.progress` / `.config` |

### Appium setup

Appium (WebDriverIO) end-to-end tests live in [`Appium/`](Appium) using Appium 2 + WebDriverIO
with the XCUITest driver — see the dedicated [`Appium/README.md`](Appium/README.md)
for prerequisites, configuration and the coverage list:

1. **Prerequisites**: Node 18+, Xcode with an iOS Simulator runtime, and the
   example app built and installed:

   ```bash
   cd Example && pod install
   xcodebuild -workspace MMTToolForHUD.xcworkspace -scheme MMTToolForHUD-Example \
     -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
   xcrun simctl boot "iPhone 16 Pro"
   APP=$(find ~/Library/Developer/Xcode/DerivedData/MMTToolForHUD-* \
     -name MMTToolForHUD_Example.app -path "*Debug-iphonesimulator*" | head -1)
   xcrun simctl install booted "$APP"
   ```

2. **Install the test stack** and start the server:

   ```bash
   cd Appium
   npm install                 # installs appium, wdio and the xcuitest driver
   npm run appium              # terminal 1: serve on http://127.0.0.1:4723
   ```

3. **Run the suite**:

   ```bash
   npm test                    # terminal 2
   ```

### Writing Appium tests

Select elements with the `~accessibilityId` shorthand and assert on labels:

```js
const toast = $('~MMTToolForHUD.toast.item');
await $('~MMTToolForHUD.demo.toast.bottom').click();
await toast.waitForDisplayed({ timeout: 5000 });
await expect(toast).toHaveText('This is a bottom toast');

const bar = $('~MMTToolForHUD.hud.progress.bar');
await $('~MMTToolForHUD.demo.progress.bar').click();
await bar.waitForDisplayed({ timeout: 5000 });
await expect(bar).toHaveAttribute('label', '100%');   // percent readout
```

The bundled spec (`Appium/specs/hud.spec.js`) covers toast show / stack /
auto-dismiss, loading with text, success flash, and both progress styles
end-to-end. Capabilities (device name, UDID, bundle id) are configured in
[`Appium/wdio.conf.js`](Appium/wdio.conf.js).

## Example app

The example app demonstrates every feature with one-tap buttons: toasts in
all positions with icons, loading with and without text, modal loading,
status flashes, bar / ring progress with a simulated download, and custom
colors. An info button in the top-right corner shows the library version
and its release notes.

```bash
cd Example
pod install
open MMTToolForHUD.xcworkspace
```

## Testing

Unit tests (39 specs, see [`Example/Tests/Tests.swift`](Example/Tests/Tests.swift))
run on the simulator:

```bash
cd Example
xcodebuild test -workspace MMTToolForHUD.xcworkspace -scheme MMTToolForHUD-Example \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

### Performance testing

Automated benchmarks with budget assertions live in
[`MMTToolForHUDPerformanceTests`](Example/Tests/Tests.swift). One command
runs them and writes JSON + Markdown reports into
[`PerformanceReports/`](PerformanceReports) (reports are committed to the
repository as history — see the
[latest report](PerformanceReports/perf-report-0.6.3.md)):

```bash
scripts/run-performance-tests.sh          # uses the booted simulator
scripts/run-performance-tests.sh "iPhone 16 Pro"   # or by name
```

The report covers show/dismiss cycles, per-call `updateProgress` cost,
text-measurement (`preferredSize`) cost, toast lifecycle cost and a memory
stress pass, each asserted against a documented budget. Latest results on
an iPhone 16 Pro simulator (all PASS):

| Benchmark | Average | Budget |
|---|---:|---:|
| showLoading + layout + dismiss | 0.668ms | 15ms |
| updateProgress (per call) | 0.396ms | 2ms |
| preferredSize with long text | 0.052ms | 1ms |
| toast present + remove | 0.598ms | 5ms |

XCTest-native `measure` baselines (`testShowDismissBaseline`,
`testProgressUpdateBaseline`) are also available for Xcode's baseline
curves.

## Contributing

This project uses **English only**: code, comments, documentation, example
app strings and commit messages must all be written in English.

## Author

nealwills, nealwills93@gmail.com

## License

MMTToolForHUD is available under the MIT license. See the [LICENSE](LICENSE)
file for more info.
