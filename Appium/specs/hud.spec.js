// End-to-end coverage for every interactive control in the MMTToolForHUD example app.
// All selectors use the stable accessibility identifier strategy (`~identifier`)
// defined by MMTToolForHUDAccessibilityID and the demo controls.

describe('MMTToolForHUD demo app', () => {
    const fs = require('node:fs');
    const path = require('node:path');
    const screenshotDir = path.resolve(__dirname, '../reports/screenshots');
    const reportEntries = [];
    const testStarts = new Map();
    const bundleId = 'org.cocoapods.demo.MMTToolForHUD-Example';

    const ids = {
        toast: '~MMTToolForHUD.toast.item',
        hudText: '~MMTToolForHUD.hud.text',
        progressBar: '~MMTToolForHUD.hud.progress.bar',
        progressRing: '~MMTToolForHUD.hud.progress.ring',
        statusIcon: '~MMTToolForHUD.hud.status.icon',
        spinner: '~MMTToolForHUD.hud.spinner',

        toastBottomButton: '~MMTToolForHUD.demo.toast.bottom',
        toastTopButton: '~MMTToolForHUD.demo.toast.top',
        toastCenterButton: '~MMTToolForHUD.demo.toast.center',
        toastIconsButton: '~MMTToolForHUD.demo.toast.icons',
        toastLongTextButton: '~MMTToolForHUD.demo.toast.long-text',
        toastDismissAllButton: '~MMTToolForHUD.demo.toast.dismiss-all',

        loadingSpinnerButton: '~MMTToolForHUD.demo.loading.spinner',
        loadingTextButton: '~MMTToolForHUD.demo.loading.text',
        loadingBlockAllButton: '~MMTToolForHUD.demo.loading.block-all',

        successButton: '~MMTToolForHUD.demo.status.success',
        errorButton: '~MMTToolForHUD.demo.status.error',

        progressBarButton: '~MMTToolForHUD.demo.progress.bar',
        progressRingButton: '~MMTToolForHUD.demo.progress.ring',

        shadowButton: '~MMTToolForHUD.demo.shadow.hud-toast',
        colorsButton: '~MMTToolForHUD.demo.config.colors',
        versionButton: '~MMTToolForHUD.demo.version',
    };

    async function takeScreenshot(name) {
        fs.mkdirSync(screenshotDir, { recursive: true });
        await driver.saveScreenshot(path.join(screenshotDir, name));
    }

    async function clickControl(selector) {
        for (let attempt = 0; attempt < 12; attempt += 1) {
            let control = await $(selector);
            try {
                if (await control.isDisplayed()) {
                    await control.click();
                    return control;
                }
            } catch {
                // The element was refreshed during scrolling; re-query on the next pass.
            }

            const size = await driver.getWindowSize();
            const x = Math.round(size.width * 0.5);
            const startY = Math.round(size.height * 0.75);
            const endY = Math.round(size.height * 0.25);
            await driver.performActions([{
                type: 'pointer',
                id: 'finger',
                parameters: { pointerType: 'touch' },
                actions: [
                    { type: 'pointerMove', duration: 0, x, y: startY },
                    { type: 'pointerDown', button: 0 },
                    { type: 'pointerMove', duration: 350, x, y: endY },
                    { type: 'pointerUp', button: 0 },
                ],
            }]);
            await driver.pause(350);
            await driver.releaseActions();
        }

        const control = await $(selector);
        await control.waitForDisplayed({ timeout: 5000 });
        await control.click();
        return control;
    }

    async function waitForDismissal(selector, timeoutMsg) {
        await driver.waitUntil(
            async () => (await $$(selector)).length === 0,
            { timeout: 8000, timeoutMsg },
        );
    }

    async function waitForText(selector, text, timeout = 5000) {
        await driver.waitUntil(
            async () => {
                const elements = await $$(selector);
                if (elements.length === 0) {
                    return false;
                }
                try {
                    return (await elements[0].getText()) === text;
                } catch {
                    return false;
                }
            },
            { timeout, timeoutMsg: `expected "${text}"` },
        );
    }

    function testFileName(title) {
        return `${title
            .toLowerCase()
            .replace(/[^a-z0-9]+/g, '-')
            .replace(/^-|-$/g, '')}.png`;
    }

    function writeReports(deviceInfo) {
        const reportDir = path.resolve(__dirname, '../reports');
        fs.mkdirSync(reportDir, { recursive: true });

        const report = {
            library: 'MMTToolForHUD',
            generatedAt: new Date().toISOString(),
            simulator: deviceInfo?.name || 'Unknown',
            framework: 'Appium 4 + WebDriverIO 10',
            tests: reportEntries,
        };

        fs.writeFileSync(
            path.join(reportDir, 'appium-report.json'),
            `${JSON.stringify(report, null, 2)}\n`,
        );
        fs.writeFileSync(
            path.join(reportDir, 'appium-shadow-report.json'),
            `${JSON.stringify(report, null, 2)}\n`,
        );

        const rows = reportEntries.map((entry) =>
            `| ${entry.name} | ${entry.status} | ${entry.durationMs}ms | ${entry.screenshot ? `[Screenshot](screenshots/${entry.screenshot})` : 'None'} |`
        ).join('\n');
        const markdown = [
            '# MMTToolForHUD Appium Report',
            '',
            `Generated: ${report.generatedAt}`,
            '',
            `Simulator: ${report.simulator}`,
            '',
            '| Test | Status | Duration | Screenshot |',
            '|---|---|---:|---|',
            rows,
            '',
        ].join('\n');

        fs.writeFileSync(path.join(reportDir, 'appium-report.md'), markdown);
        fs.writeFileSync(path.join(reportDir, 'appium-shadow-report.md'), markdown);
    }

    beforeEach(async function () {
        await driver.terminateApp(bundleId);
        await driver.activateApp(bundleId);
        await $(ids.toastBottomButton).waitForDisplayed({ timeout: 10000 });
        testStarts.set(this.currentTest.fullTitle(), Date.now());
    });

    afterEach(async function () {
        const title = this.currentTest.fullTitle();
        const name = this.currentTest.title;
        const passed = this.currentTest.state === 'passed';
        const screenshot = testFileName(name);

        try {
            await takeScreenshot(screenshot);
        } catch (error) {
            console.warn(`Could not capture screenshot for "${title}": ${error.message}`);
        }

        reportEntries.push({
            name,
            status: passed ? 'PASS' : 'FAIL',
            durationMs: Date.now() - (testStarts.get(title) || Date.now()),
            screenshot,
        });
    });

    after(async () => {
        const deviceInfo = await driver.executeScript('mobile: deviceInfo', []);
        writeReports(deviceInfo);
    });

    it('shows a bottom toast that auto-dismisses', async () => {
        await clickControl(ids.toastBottomButton);
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('This is a bottom toast');
        await waitForDismissal(ids.toast, 'toast should auto-dismiss');
    });

    it('shows a top-position toast', async () => {
        await clickControl(ids.toastTopButton);
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('Top notice, great for notification-style messages');
    });

    it('shows a center-position toast', async () => {
        await clickControl(ids.toastCenterButton);
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('Centered toast');
    });

    it('stacks success, error and info toasts', async () => {
        await clickControl(ids.toastIconsButton);

        const toasts = await $$(ids.toast);
        expect(toasts.length).toBeGreaterThanOrEqual(3);
        const texts = [];
        for (let index = 0; index < toasts.length; index += 1) {
            await toasts[index].waitForDisplayed({ timeout: 5000 });
            texts.push(await toasts[index].getText());
        }
        expect(texts).toEqual(expect.arrayContaining([
            'Saved successfully',
            'Network error',
            'Update available',
        ]));
    });

    it('shows a wrapping long-text toast', async () => {
        await clickControl(ids.toastLongTextButton);
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText(
            'This is a fairly long toast message used to demonstrate automatic line wrapping and self-sizing layout without any extra configuration.',
        );
    });

    it('dismisses every visible toast', async () => {
        await clickControl(ids.toastIconsButton);
        const toasts = await $$(ids.toast);
        expect(toasts.length).toBeGreaterThanOrEqual(3);
        await toasts[0].waitForDisplayed({ timeout: 5000 });
        await clickControl(ids.toastDismissAllButton);
        await waitForDismissal(ids.toast, 'dismiss-all should remove every toast');
    });

    it('shows a spinner-only loading HUD and auto-dismisses it', async () => {
        await clickControl(ids.loadingSpinnerButton);
        await $(ids.spinner).waitForDisplayed({ timeout: 5000 });
        await waitForDismissal(ids.spinner, 'spinner-only loading HUD should dismiss after 2s');
    });

    it('shows loading HUD with text and auto-dismisses it', async () => {
        await clickControl(ids.loadingTextButton);
        const label = await $(ids.hudText);
        await label.waitForDisplayed({ timeout: 5000 });
        await expect(label).toHaveText('Loading, please wait…');
        await waitForDismissal(ids.hudText, 'loading HUD should dismiss after 2s');
    });

    it('blocks the whole screen and restores HUD-only interception', async () => {
        await clickControl(ids.loadingBlockAllButton);
        const label = await $(ids.hudText);
        await label.waitForDisplayed({ timeout: 5000 });
        await expect(label).toHaveText('Modal loading…');
        await waitForDismissal(ids.hudText, 'modal loading HUD should dismiss after 2s');

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('Interception restored to HUD area only');
    });

    it('shows the success status icon and auto-dismisses', async () => {
        await clickControl(ids.successButton);
        const icon = await $(ids.statusIcon);
        await icon.waitForDisplayed({ timeout: 5000 });
        await expect(icon).toHaveAttribute('label', 'Success');
        await waitForDismissal(ids.statusIcon, 'success status should auto-dismiss');
    });

    it('shows the error status icon and auto-dismisses', async () => {
        await clickControl(ids.errorButton);
        const icon = await $(ids.statusIcon);
        await icon.waitForDisplayed({ timeout: 5000 });
        await expect(icon).toHaveAttribute('label', 'Error');
        await expect(await $(ids.hudText)).toHaveText('Network error, please try again later');
        await waitForDismissal(ids.statusIcon, 'error status should auto-dismiss');
    });

    it('runs bar progress to completion and shows a toast', async () => {
        await clickControl(ids.progressBarButton);
        await $(ids.progressBar).waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });

    it('runs ring progress to completion', async () => {
        await clickControl(ids.progressRingButton);
        await $(ids.progressRing).waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });

    it('shows configurable HUD and toast shadows', async () => {
        await clickControl(ids.shadowButton);

        const hudText = await $(ids.hudText);
        await hudText.waitForDisplayed({ timeout: 5000 });
        await expect(hudText).toHaveText('Custom shadow');

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('Toast shadow');
    });

    it('applies custom spinner and status icon colors in sequence', async () => {
        await clickControl(ids.colorsButton);
        await browser.pause(1500);

        let source = await driver.getPageSource();
        expect(source).toContain('Success is green');
        expect(source).toContain('Success');

        await browser.pause(2000);
        source = await driver.getPageSource();
        expect(source).toContain('Error is red');
        expect(source).toContain('Error');
    });

    it('shows version information from the floating info button', async () => {
        await $(ids.versionButton).waitForDisplayed({ timeout: 5000 });
        await $(ids.versionButton).click();

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        const text = await toast.getText();
        expect(text).toContain('MMTToolForHUD');
    });
});
