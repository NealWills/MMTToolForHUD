// End-to-end coverage for the MMTToolForHUD example app.
// All selectors use the "accessibility id" strategy (`~identifier`); the
// stable identifiers are defined by MMTToolForHUDAccessibilityID in the
// library and the "demo.*" identifiers in the example app.

describe('MMTToolForHUD demo app', () => {
    const ids = {
        toast: '~MMTToolForHUD.toast',
        hudText: '~MMTToolForHUD.text',
        progressBar: '~MMTToolForHUD.progress-bar',
        progressRing: '~MMTToolForHUD.progress-ring',
    };

    beforeEach(async () => {
        // Re-launch to a clean state before each test.
        await driver.terminateApp('org.cocoapods.demo.MMTToolForHUD-Example');
        await driver.activateApp('org.cocoapods.demo.MMTToolForHUD-Example');
    });

    it('shows a toast that auto-dismisses', async () => {
        await $('~demo.toast.bottom').click();
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('This is a bottom toast');

        await toast.waitUntil(
            async () => !(await toast.isDisplayed()),
            { timeout: 8000, timeoutMsg: 'toast should auto-dismiss' },
        );
    });

    it('stacks toasts from different demo buttons', async () => {
        await $('~demo.toast.icons').click();
        const toasts = await $$(ids.toast);
        await toasts[0].waitForDisplayed({ timeout: 5000 });
        expect(toasts.length).toBeGreaterThanOrEqual(3);
    });

    it('shows loading HUD with text and auto-dismisses it', async () => {
        await $('~demo.loading.text').click();
        const label = await $(ids.hudText);
        await label.waitForDisplayed({ timeout: 5000 });
        await expect(label).toHaveText('Loading, please wait…');

        await label.waitUntil(
            async () => !(await label.isDisplayed()),
            { timeout: 8000, timeoutMsg: 'loading HUD should dismiss after 2s' },
        );
    });

    it('shows the success status icon and auto-dismisses', async () => {
        await $('~demo.status.success').click();
        const icon = await $('~MMTToolForHUD.status-icon');
        await icon.waitForDisplayed({ timeout: 5000 });
        await expect(icon).toHaveAttribute('label', 'Success');
        await icon.waitUntil(
            async () => !(await icon.isDisplayed()),
            { timeout: 8000 },
        );
    });

    it('runs bar progress to completion and shows a toast', async () => {
        await $('~demo.progress.bar').click();
        const bar = await $(ids.progressBar);
        await bar.waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });

    it('runs ring progress to completion', async () => {
        await $('~demo.progress.ring').click();
        const ring = await $(ids.progressRing);
        await ring.waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });
});
