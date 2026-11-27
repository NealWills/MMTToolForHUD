const path = require('node:path');

const deviceName = process.env.IOS_DEVICE_NAME || 'iPhone 18 Pro';
const deviceUdid = process.env.IOS_UDID;
const appPath = process.env.IOS_APP_PATH;

exports.config = {
    runner: 'local',
    hostname: '127.0.0.1',
    port: 4723,
    path: '/',
    specs: ['./specs/**/*.spec.js'],
    maxInstances: 1,
    capabilities: [{
        platformName: 'iOS',
        'appium:automationName': 'XCUITest',
        'appium:bundleId': 'org.cocoapods.demo.MMTToolForHUD-Example',
        'appium:deviceName': deviceName,
        ...(deviceUdid ? { 'appium:udid': deviceUdid } : {}),
        ...(appPath ? { 'appium:app': path.resolve(appPath) } : {}),
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
    services: [['appium', {
        args: { address: '127.0.0.1' },
        appiumStartTimeout: 60000,
    }]],
    onPrepare: async function () {
        const fs = await import('node:fs');
        fs.mkdirSync('./reports/screenshots', { recursive: true });
    },
};
