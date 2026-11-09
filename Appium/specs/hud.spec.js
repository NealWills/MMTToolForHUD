// End-to-end coverage for the MMTToolForHUD example app.
// All selectors use the "accessibility id" strategy (`~identifier`), in the
// MMTToolForHUD.<area>.<element> format defined by
// MMTToolForHUDAccessibilityID in the library and the
// MMTToolForHUD.demo.* identifiers in the example app.

describe('MMTToolForHUD demo app', () => {
    const ids = {
        toast: '~MMTToolForHUD.toast.item',
        hudText: '~MMTToolForHUD.hud.text',
        progressBar: '~MMTToolForHUD.hud.progress.bar',
        progressRing: '~MMTToolForHUD.hud.progress.ring',
        statusIcon: '~MMTToolForHUD.hud.status.icon',
        toastBottomButton: '~MMTToolForHUD.demo.toast.bottom',
        toastIconsButton: '~MMTToolForHUD.demo.toast.icons',
        loadingTextButton: '~MMTToolForHUD.demo.loading.text',
        successButton: '~MMTToolForHUD.demo.status.success',
        progressBarButton: '~MMTToolForHUD.demo.progress.bar',
        progressRingButton: '~MMTToolForHUD.demo.progress.ring',
    };

    beforeEach(async () => {
        // Re-launch to a clean state before each test.
        await driver.terminateApp('org.cocoapods.demo.MMTToolForHUD-Example');
        await driver.activateApp('org.cocoapods.demo.MMTToolForHUD-Example');
    });

    it('shows a toast that auto-dismisses', async () => {
        await $(ids.toastBottomButton).click();
        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 5000 });
        await expect(toast).toHaveText('This is a bottom toast');

        await toast.waitUntil(
            async () => !(await toast.isDisplayed()),
            { timeout: 8000, timeoutMsg: 'toast should auto-dismiss' },
        );
    });

    it('stacks toasts from different demo buttons', async () => {
        await $(ids.toastIconsButton).click();
        const toasts = await $$(ids.toast);
        await toasts[0].waitForDisplayed({ timeout: 5000 });
        expect(toasts.length).toBeGreaterThanOrEqual(3);
    });

    it('shows loading HUD with text and auto-dismisses it', async () => {
        await $(ids.loadingTextButton).click();
        const label = await $(ids.hudText);
        await label.waitForDisplayed({ timeout: 5000 });
        await expect(label).toHaveText('Loading, please wait…');

        await label.waitUntil(
            async () => !(await label.isDisplayed()),
            { timeout: 8000, timeoutMsg: 'loading HUD should dismiss after 2s' },
        );
    });

    it('shows the success status icon and auto-dismisses', async () => {
        await $(ids.successButton).click();
        const icon = await $(ids.statusIcon);
        await icon.waitForDisplayed({ timeout: 5000 });
        await expect(icon).toHaveAttribute('label', 'Success');
        await icon.waitUntil(
            async () => !(await icon.isDisplayed()),
            { timeout: 8000 },
        );
    });

    it('runs bar progress to completion and shows a toast', async () => {
        await $(ids.progressBarButton).click();
        const bar = await $(ids.progressBar);
        await bar.waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });

    it('runs ring progress to completion', async () => {
        await $(ids.progressRingButton).click();
        const ring = await $(ids.progressRing);
        await ring.waitForDisplayed({ timeout: 5000 });

        const toast = await $(ids.toast);
        await toast.waitForDisplayed({ timeout: 20000 });
        await expect(toast).toHaveText('Download complete');
    });
});
