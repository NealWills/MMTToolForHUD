# MMTToolForHUD

[![CI Status](https://img.shields.io/travis/nealwills/MMTToolForHUD.svg?style=flat)](https://travis-ci.org/nealwills/MMTToolForHUD)
[![Version](https://img.shields.io/cocoapods/v/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)
[![License](https://img.shields.io/cocoapods/l/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)
[![Platform](https://img.shields.io/cocoapods/p/MMTToolForHUD.svg?style=flat)](https://cocoapods.org/pods/MMTToolForHUD)

A lightweight iOS HUD library supporting **toast, loading and progress**.
Built on iOS 13+ UIScene, thread-safe, zero third-party dependencies.

## Features

- **Toast**: stackable, three positions (top / center / bottom), auto-dismiss,
  success / error / info icons, long-text wrapping, never blocks touches
- **Loading**: spinner with optional text, whole-screen or panel-only
  touch interception
- **Progress**: bar and ring styles, live updates, automatic percentage
- **Status flash**: auto-dismissing success (checkmark) / error (cross)
- **Unified configuration**: a single `MMTToolForHUDConfig` customizes all
  colors, fonts, corner radius, animations and durations
- **Thread-safe**: every API can be called from any thread
- **Window aware**: attaches to the key window of the active foreground
  scene, or any window you specify

## Requirements

- iOS 13.0+
- Swift 5.0+

## Installation

MMTToolForHUD is available through [CocoaPods](https://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod 'MMTToolForHUD'
```

## Quick start

### Toast

```swift
import MMTToolForHUD

MMTToolForHUDToast.show("A simple toast")               // bottom, auto-dismiss
MMTToolForHUDToast.show("Top notice", position: .top)   // explicit position
MMTToolForHUDToast.success("Saved")                     // green checkmark
MMTToolForHUDToast.error("Network error")               // red cross
MMTToolForHUDToast.info("Update available")             // blue info icon
MMTToolForHUDToast.show("Stays 5s", duration: 5)        // custom duration
MMTToolForHUDToast.dismissAll()                         // remove all now
```

### Loading

```swift
MMTToolForHUD.showLoading()                  // spinner only
MMTToolForHUD.showLoading("Loading…")        // spinner + text
MMTToolForHUD.dismiss()                      // dismiss manually
MMTToolForHUD.dismiss(after: 2)              // auto-dismiss after 2s
```

### Progress

```swift
MMTToolForHUD.showProgress(0.0, text: "Downloading")             // bar (default)
MMTToolForHUD.showProgress(0.0, text: "Downloading", style: .ring) // ring
MMTToolForHUD.updateProgress(0.5)                                 // live update
MMTToolForHUD.updateProgress(0.8, text: "Almost done")            // update text too
```

### Status flash

```swift
MMTToolForHUD.showSuccess("Submitted")   // checkmark, auto-dismiss (1.6s default)
MMTToolForHUD.showError("Failed")        // cross, auto-dismiss
```

### Custom configuration

```swift
// Global; applies to HUDs and toasts presented afterwards.
MMTToolForHUD.updateConfig {
    $0.spinnerColor = .systemOrange
    $0.successIconColor = .systemGreen
    $0.errorIconColor = .systemRed
    $0.interactionStyle = .blockAll  // .blockHUD / .blockAll / .passThrough
    $0.toastDuration = 3
    $0.toastPosition = .top
    $0.progressStyle = .ring
}
```

Frequently used options (see `MMTToolForHUDConfig` for the full list):

| Option | Description | Default |
|---|---|---|
| `hudBackgroundColor` / `textColor` | Panel background / text | near-black / white |
| `tintColor` | Progress tint (bar, ring, percent label) | white |
| `spinnerColor` / `successIconColor` / `errorIconColor` | Spinner and status icon render colors | white / green / red |
| `interactionStyle` | Touch interception policy | `.blockHUD` (panel only) |
| `statusAutoDismissDelay` | Success/error auto-dismiss delay | 1.6s |
| `progressStyle` | Default progress style | `.bar` |
| `toastDuration` / `toastPosition` / `toastMargin` | Toast duration / position / margin | 2s / `.bottom` / 20 |
| `toastCornerRadius` | Toast corner radius | 8 |
| `toastBackgroundColor` / `toastFont` | Toast appearance | near-black capsule / 14pt medium |
| `isAnimationEnabled` / `animationDuration` | Animation toggle and duration | true / 0.25s |

### Windows

Every show / dismiss API takes an optional `in:` window (the front window by
default) and only manages the content attached to that window, so multiple
windows can display independent HUDs and toasts:

```swift
MMTToolForHUD.showLoading("Loading", in: someWindow)
MMTToolForHUD.dismiss(in: someWindow)
MMTToolForHUD.isVisible(in: someWindow)
MMTToolForHUD.currentProgress(in: someWindow)

MMTToolForHUDToast.show("Saved", in: someWindow)
MMTToolForHUDToast.dismissAll(in: someWindow)   // nil clears every window
```

## Example

To run the example project, clone the repo, and run `pod install` from the Example directory first.

```bash
cd Example
pod install
open MMTToolForHUD.xcworkspace
```

The example app includes buttons demonstrating every feature: toasts in all
positions with icons, modal loading, bar / ring progress with a simulated
download, and custom theming.

## Tests

```bash
cd Example
xcodebuild test -workspace MMTToolForHUD.xcworkspace -scheme MMTToolForHUD-Example \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro'
```

## Automation & Appium identifiers

All HUD, toast and demo controls expose stable accessibility identifiers so
XCUITest and Appium can query them with the "accessibility id" strategy.
Identifier format: `MMTToolForHUD.<area>.<element>[.<detail>]`.

Library identifiers (defined in `MMTToolForHUDAccessibilityID`):

| Identifier | Element |
|---|---|
| `MMTToolForHUD.hud.panel` | The HUD panel container |
| `MMTToolForHUD.hud.spinner` | Loading spinner |
| `MMTToolForHUD.hud.progress.ring` | Ring progress (accessibility label = percent) |
| `MMTToolForHUD.hud.progress.bar` | Bar progress (accessibility label = percent) |
| `MMTToolForHUD.hud.status.icon` | Success / error icon (label = Success / Error) |
| `MMTToolForHUD.hud.text` | HUD text label |
| `MMTToolForHUD.toast.item` | Any toast view (label = toast text) |

Example app buttons use `MMTToolForHUD.demo.<section>.<name>` identifiers
(`MMTToolForHUD.demo.toast.bottom`, `MMTToolForHUD.demo.loading.text`,
`MMTToolForHUD.demo.progress.ring`, …) and section headers use
`MMTToolForHUD.demo.section.<name>`.

Appium (WebDriverIO) end-to-end tests live in [`Appium/`](Appium):

```bash
cd Appium
npm install
npm run appium   # terminal 1: start the Appium server
npm test         # terminal 2: run the suite against the booted simulator
```

## Contributing

This project uses **English only**: code, comments, documentation, example
app strings and commit messages must all be written in English.

## Author

nealwills, nealwills93@gmail.com

## License

MMTToolForHUD is available under the MIT license. See the LICENSE file for more info.
