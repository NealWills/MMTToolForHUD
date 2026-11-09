// WebdriverIO configuration for Appium tests against the MMTToolForHUD
// example app running on an iOS simulator.
//
// Setup:
//   1. npm install                      (in this directory)
//   2. Build and install the example app:
//        cd Example && pod install
//        xcodebuild -workspace MMTToolForHUD.xcworkspace -scheme MMTToolForHUD-Example \
//          -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build
//        xcrun simctl install booted <path-to-derived-data>/MMTToolForHUD_Example.app
//   3. Start Appium: npm run appium
//   4. Run the suite: npm test

exports.config = {
    runner: 'local',
    specs: ['./specs/**/*.spec.js'],
    maxInstances: 1,
    capabilities: [{
        platformName: 'iOS',
        'appium:automationName': 'XCUITest',
        // Use the already-installed example app.
        'appium:bundleId': 'org.cocoapods.demo.MMTToolForHUD-Example',
        // Fill in your simulator name / UDID:
        'appium:deviceName': 'iPhone 16 Pro',
        // 'appium:udid': 'SIMULATOR-UDID',
        'appium:newCommandTimeout': 120,
        'appium:wdaLaunchTimeout': 120000,
        'appium:showXcodeLog': false,
    }],
    logLevel: 'warn',
    bail: 0,
    waitforTimeout: 10000,
    connectionRetryTimeout: 120000,
    connectionRetryCount: 3,
    framework: 'mocha',
    mochaOpts: {
        ui: 'bdd',
        timeout: 60000,
    },
    reporters: ['spec'],
};
