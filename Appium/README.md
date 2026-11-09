# MMTToolForHUD Appium tests

End-to-end tests for the [MMTToolForHUD](../README.md) example app, using
**Appium 2** + **WebDriverIO 9** with the **XCUITest** driver.

## Prerequisites

- Node 18+
- Xcode with an iOS Simulator runtime
- The example app built and installed on a booted simulator:

```bash
cd ../Example && pod install
xcodebuild -workspace MMTToolForHUD.xcworkspace -scheme MMTToolForHUD-Example \
  -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
xcrun simctl boot "iPhone 16 Pro"
APP=$(find ~/Library/Developer/Xcode/DerivedData/MMTToolForHUD-* \
  -name MMTToolForHUD_Example.app -path "*Debug-iphonesimulator*" | head -1)
xcrun simctl install booted "$APP"
```

## Running

```bash
npm install         # appium, wdio and the xcuitest driver
npm run appium      # terminal 1: Appium server on http://127.0.0.1:4723
npm test            # terminal 2: run the suite
```

## Configuration

Capabilities live in [`wdio.conf.js`](wdio.conf.js):

| Capability | Value | Notes |
|---|---|---|
| `appium:automationName` | `XCUITest` | iOS driver |
| `appium:bundleId` | `org.cocoapods.demo.MMTToolForHUD-Example` | Uses the installed app |
| `appium:deviceName` | `iPhone 16 Pro` | Change to your simulator |
| `appium:udid` | commented | Uncomment and set for multi-simulator setups |

## Selectors

All elements are addressed by stable accessibility identifiers in the
`MMTToolForHUD.<area>.<element>` format; use the `~id` shorthand:

```js
await $('~MMTToolForHUD.demo.toast.bottom').click();   // demo button
await $('~MMTToolForHUD.toast.item').waitForDisplayed({ timeout: 5000 });
await $('~MMTToolForHUD.hud.progress.bar');            // percent in label
```

See the [main README](../README.md#ui-automation--appium) for the full
identifier reference.

## Coverage

The bundled spec [`specs/hud.spec.js`](specs/hud.spec.js) verifies:

- Toast show, text assertion and auto-dismiss
- Toast stacking from multiple triggers
- Loading HUD with text and timed dismissal
- Success status icon and auto-dismiss
- Bar and ring progress running to completion, ending in a toast
