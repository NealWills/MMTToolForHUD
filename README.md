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
    $0.hudBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.92)
    $0.cornerRadius = 24
    $0.interactionStyle = .blockAll  // .blockHUD / .blockAll / .passThrough
    $0.toastDuration = 3
    $0.toastPosition = .top
    $0.progressStyle = .ring
}
```

Frequently used options (see `MMTToolForHUDConfig` for the full list):

| Option | Description | Default |
|---|---|---|
| `hudBackgroundColor` / `tintColor` / `textColor` | HUD colors | dark panel / white / white |
| `interactionStyle` | Touch interception policy | `.blockHUD` (panel only) |
| `statusAutoDismissDelay` | Success/error auto-dismiss delay | 1.6s |
| `progressStyle` | Default progress style | `.bar` |
| `toastDuration` / `toastPosition` / `toastMargin` | Toast duration / position / margin | 2s / `.bottom` / 20 |
| `toastBackgroundColor` / `toastFont` | Toast appearance | dark capsule / 14pt medium |
| `isAnimationEnabled` / `animationDuration` | Animation toggle and duration | true / 0.25s |

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

## Contributing

This project uses **English only**: code, comments, documentation, example
app strings and commit messages must all be written in English.

## Author

nealwills, nealwills93@gmail.com

## License

MMTToolForHUD is available under the MIT license. See the LICENSE file for more info.
