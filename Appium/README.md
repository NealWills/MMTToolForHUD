# MMTToolForHUD Appium tests

End-to-end tests for the [MMTToolForHUD](../README.md) example app, using
**Appium 4** + **WebdriverIO 10** with the **XCUITest** driver.

## Prerequisites

- Node.js 22.23.4+, 24.22.1+, or 26.12.1+ (Node.js 23 and 25 are
  unsupported), and npm 10+
- Xcode with a compatible iOS Simulator runtime and command-line tools
- CocoaPods for the example app
- An available iOS simulator; the default is `iPhone 18 Pro`

List available simulators with `xcrun simctl list devices available`. From
the repository root, build the example app for the desired simulator:

```bash
cd Example
pod install
xcodebuild -workspace MMTToolForHUD.xcworkspace \
  -scheme MMTToolForHUD-Example -configuration Debug \
  -destination 'platform=iOS Simulator,name=iPhone 18 Pro' \
  -derivedDataPath ./build/appium build
```

## Running

From the `Example` directory:

```bash
cd ../Appium
npm ci
IOS_APP_PATH=../Example/build/appium/Build/Products/Debug-iphonesimulator/MMTToolForHUD_Example.app npm test
```

WebdriverIO starts and stops the local Appium server automatically at
`http://127.0.0.1:4723/`. Appium installs the app on the selected simulator
when `IOS_APP_PATH` is provided; without it, the app must already be installed.
The first run can take longer while WebDriverAgent is built.

The server and XCUITest driver are installed as project dependencies, without
changing the global Appium installation. The npm scripts unset `APPIUM_HOME`
so Appium uses this project's driver. Run `npm run doctor` to check the driver
prerequisites. For standalone server debugging, use `npm run appium`; stop it
before running `npm test`, which starts its own server on the same port.

## Configuration

Capabilities live in [`wdio.conf.js`](wdio.conf.js):

| Setting | Default | Notes |
|---|---|---|
| `IOS_DEVICE_NAME` | `iPhone 18 Pro` | Simulator name |
| `IOS_UDID` | unset | Select an exact simulator when several are available |
| `IOS_APP_PATH` | unset | Absolute or relative path to the built `.app` |
| `appium:bundleId` | `org.cocoapods.demo.MMTToolForHUD-Example` | Example app bundle ID |

For example:

```bash
IOS_DEVICE_NAME="iPhone 17" IOS_UDID="<simulator-udid>" \
  IOS_APP_PATH=/path/to/MMTToolForHUD_Example.app npm test
```

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

- Bottom, top and center toast positions
- Success / error / info toast stacking
- Long-text wrapping and dismiss-all
- Toast auto-dismiss
- Spinner-only loading
- Loading text and timed dismissal
- Modal block-all loading and restoration to HUD-only interception
- Success and error status flashes
- Bar and ring progress completion
- Custom HUD/toast shadows
- Custom spinner and status icon colors
- Floating version information
- One pass/fail screenshot for every test
- JSON and Markdown reports under `reports/`
