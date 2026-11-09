//
//  Tests.swift
//  MMTToolForHUD
//
//  Created by nealwills on 11/09/2026.
//  Copyright (c) 2026 MMTToolForHUD. All rights reserved.
//

import XCTest
import UIKit
@testable import MMTToolForHUD
@testable import MMTToolForHUD_Example

final class MMTToolForHUDTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        MMTToolForHUD.dismiss(animated: false)
        MMTToolForHUDToast.dismissAll()
        window = nil
        super.tearDown()
    }

    // MARK: - Configuration

    func testConfigDefaults() {
        let config = MMTToolForHUD.config
        XCTAssertEqual(config.toastDuration, 2.0)
        XCTAssertEqual(config.animationDuration, 0.25)
        XCTAssertEqual(config.progressStyle, .bar)
        XCTAssertEqual(config.interactionStyle, .blockHUD)
        XCTAssertEqual(config.statusAutoDismissDelay, 1.6)
    }

    func testConfigSharedBetweenHUDAndToast() {
        MMTToolForHUDToast.config.toastDuration = 3.5
        defer { MMTToolForHUD.config.toastDuration = 2.0 }
        XCTAssertEqual(MMTToolForHUD.config.toastDuration, 3.5)
    }

    // MARK: - Loading

    func testShowAndDismissLoading() {
        MMTToolForHUD.showLoading("Loading", in: window)
        XCTAssertTrue(MMTToolForHUD.isVisible)

        let expectation = expectation(description: "dismissed")
        MMTToolForHUD.dismiss { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testDismissWithoutAnimationImmediately() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.dismiss(animated: false)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testDismissAfterDelay() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.dismiss(after: 0.3)
        XCTAssertTrue(MMTToolForHUD.isVisible)

        let expectation = expectation(description: "delayed dismiss")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testRepeatedShowReusesContainer() {
        MMTToolForHUD.showLoading("first", in: window)
        MMTToolForHUD.showLoading("second", in: window)
        XCTAssertTrue(MMTToolForHUD.isVisible)

        let containers = window.subviews.filter { $0 is MMTToolForHUDContainerView }
        XCTAssertEqual(containers.count, 1)
    }

    func testShowFromBackgroundThread() {
        let expectation = expectation(description: "background show")
        DispatchQueue.global().async {
            MMTToolForHUD.showLoading("from a background thread", in: self.window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                XCTAssertTrue(MMTToolForHUD.isVisible)
                expectation.fulfill()
            }
        }
        wait(for: [expectation], timeout: 3)
    }

    // MARK: - Progress

    func testShowAndUpdateProgress() {
        MMTToolForHUD.showProgress(0.2, text: "Downloading", in: window)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 0.2, accuracy: 0.001)

        MMTToolForHUD.updateProgress(0.75)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 0.75, accuracy: 0.001)
    }

    func testProgressClampedToClosedRange() {
        MMTToolForHUD.showProgress(1.8, in: window)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 1.0, accuracy: 0.001)

        MMTToolForHUD.updateProgress(-0.5)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 0.0, accuracy: 0.001)
    }

    func testProgressNilAfterDismiss() {
        MMTToolForHUD.showProgress(0.5, in: window)
        MMTToolForHUD.dismiss(animated: false)
        XCTAssertNil(MMTToolForHUD.currentProgress)
    }

    // MARK: - Status

    func testSuccessAutoDismisses() {
        MMTToolForHUD.showSuccess("OK", in: window)
        XCTAssertTrue(MMTToolForHUD.isVisible)

        let expectation = expectation(description: "auto dismissed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 5)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testLoadingCancelsAutoDismiss() {
        MMTToolForHUD.showSuccess("OK", in: window)
        MMTToolForHUD.showLoading("still visible", in: window)
        XCTAssertTrue(MMTToolForHUD.isVisible)

        // Should still be visible after the auto-dismiss delay,
        // proving the timer was cancelled.
        let expectation = expectation(description: "still visible")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.2) { expectation.fulfill() }
        wait(for: [expectation], timeout: 4)
        XCTAssertTrue(MMTToolForHUD.isVisible)
    }

    // MARK: - Toast

    func testToastShowsAndAutoDismisses() {
        MMTToolForHUDToast.show("hello", duration: 0.4, in: window)
        XCTAssertTrue(MMTToolForHUDToast.isVisible)

        let expectation = expectation(description: "toast gone")
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 4)
        XCTAssertFalse(MMTToolForHUDToast.isVisible)
    }

    func testToastStacking() {
        MMTToolForHUDToast.show("toast 1", duration: 5, in: window)
        MMTToolForHUDToast.show("toast 2", duration: 5, in: window)
        MMTToolForHUDToast.show("toast 3", duration: 5, in: window)

        let items = window.subviews
            .compactMap { $0 as? MMTToolForHUDToastContainerView }
            .flatMap { $0.stack.arrangedSubviews }
        XCTAssertEqual(items.count, 3)
    }

    func testToastDismissAll() {
        MMTToolForHUDToast.show("toast 1", duration: 5, in: window)
        MMTToolForHUDToast.show("toast 2", duration: 5, in: window)
        MMTToolForHUDToast.dismissAll()

        let expectation = expectation(description: "all removed")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)
        XCTAssertFalse(MMTToolForHUDToast.isVisible)
        let containers = window.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }
        XCTAssertTrue(containers.isEmpty)
    }

    // MARK: - Toast containers

    func testToastPositionsUseSeparateContainers() {
        MMTToolForHUDToast.show("top toast", duration: 5, position: .top, in: window)
        MMTToolForHUDToast.show("bottom toast", duration: 5, position: .bottom, in: window)

        let containers = window.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }
        XCTAssertEqual(containers.count, 2)
        XCTAssertEqual(Set(containers.map { $0.position }), [.top, .bottom])
    }

    func testToastContainerRebuiltWhenWindowChanges() {
        let otherWindow = UIWindow(frame: UIScreen.main.bounds)

        MMTToolForHUDToast.show("toast", duration: 5, in: window)
        MMTToolForHUDToast.show("toast", duration: 5, in: otherWindow)

        XCTAssertEqual(window.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 0)
        XCTAssertEqual(otherWindow.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 1)
    }

    // MARK: - Presenter state machine

    func testUpdateProgressIgnoredWhenNotVisible() {
        MMTToolForHUD.updateProgress(0.5)
        XCTAssertNil(MMTToolForHUD.currentProgress)
    }

    func testUpdateProgressIgnoredForSpinnerMode() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.updateProgress(0.5)
        XCTAssertNil(MMTToolForHUD.currentProgress)
    }

    func testStatusReplacesProgressMode() {
        MMTToolForHUD.showProgress(0.5, in: window)
        XCTAssertNotNil(MMTToolForHUD.currentProgress)

        MMTToolForHUD.showSuccess("done", in: window)
        XCTAssertNil(MMTToolForHUD.currentProgress)
        XCTAssertTrue(MMTToolForHUD.isVisible)
    }

    func testRingProgressStyleShowsRing() {
        MMTToolForHUD.showProgress(0.3, style: .ring, in: window)
        let container = window.subviews.compactMap { $0 as? MMTToolForHUDContainerView }.first
        XCTAssertNotNil(container)
        XCTAssertEqual(container?.contentView.mode, .ring)
    }

    func testDismissWhenNotVisibleStillCallsCompletion() {
        let expectation = expectation(description: "completion called")
        MMTToolForHUD.dismiss { expectation.fulfill() }
        wait(for: [expectation], timeout: 2)
    }

    // MARK: - Touch interception

    private func makeLaidOutContainer(style: MMTToolForHUDConfig.InteractionStyle)
        -> MMTToolForHUDContainerView {
        var config = MMTToolForHUDConfig()
        config.interactionStyle = style
        config.isAnimationEnabled = false
        let container = MMTToolForHUDContainerView(config: config)
        container.frame = CGRect(x: 0, y: 0, width: 390, height: 844)
        container.layoutIfNeeded()
        return container
    }

    func testHitTestBlockHUD() {
        let container = makeLaidOutContainer(style: .blockHUD)
        let panelCenter = CGPoint(x: container.contentView.center.x, y: container.contentView.center.y)
        let farCorner = CGPoint(x: 5, y: 5)

        XCTAssertNotNil(container.hitTest(panelCenter, with: nil))
        XCTAssertNil(container.hitTest(farCorner, with: nil))
    }

    func testHitTestBlockAll() {
        let container = makeLaidOutContainer(style: .blockAll)
        XCTAssertNotNil(container.hitTest(CGPoint(x: 5, y: 5), with: nil))
        XCTAssertNotNil(container.hitTest(container.contentView.center, with: nil))
    }

    func testHitTestPassThrough() {
        let container = makeLaidOutContainer(style: .passThrough)
        XCTAssertNil(container.hitTest(CGPoint(x: 5, y: 5), with: nil))
        XCTAssertNil(container.hitTest(container.contentView.center, with: nil))
    }

    // MARK: - Content view sizing

    func testPreferredSizeSpinnerOnly() {
        let contentView = MMTToolForHUDContentView()
        contentView.apply(config: MMTToolForHUDConfig())
        contentView.apply(mode: .spinner, text: nil, progress: 0, animated: false)
        let size = contentView.preferredSize(maxWidth: 300)
        // padding(22) * 2 + icon area(54)
        XCTAssertEqual(size.width, 98, accuracy: 0.5)
        XCTAssertEqual(size.height, 98, accuracy: 0.5)
    }

    func testPreferredSizeGrowsWithText() {
        let contentView = MMTToolForHUDContentView()
        contentView.apply(config: MMTToolForHUDConfig())

        contentView.apply(mode: .spinner, text: nil, progress: 0, animated: false)
        let withoutText = contentView.preferredSize(maxWidth: 300)

        contentView.apply(mode: .spinner, text: "Loading data", progress: 0, animated: false)
        let withText = contentView.preferredSize(maxWidth: 300)

        XCTAssertEqual(withoutText.width, 98, accuracy: 0.5)
        XCTAssertGreaterThan(withText.height, withoutText.height)
        XCTAssertGreaterThan(withText.width, withoutText.width)
    }

    func testPreferredSizeBarModeUsesBarWidth() {
        let contentView = MMTToolForHUDContentView()
        var config = MMTToolForHUDConfig()
        config.barProgressWidth = 132
        config.barProgressHeight = 5
        contentView.apply(config: config)
        contentView.apply(mode: .bar, text: nil, progress: 0, animated: false)
        let size = contentView.preferredSize(maxWidth: 300)
        // padding(22) * 2 + bar width(132); bar mode always adds a percent
        // text line below the bar, so the height exceeds bar + paddings.
        XCTAssertEqual(size.width, 176, accuracy: 0.5)
        XCTAssertGreaterThan(size.height, 49)
    }

    // MARK: - Accessibility identifiers (Appium contract)

    func testHUDExposesAccessibilityIdentifiers() {
        MMTToolForHUD.showLoading("Loading", in: window)

        let container = window.subviews.compactMap { $0 as? MMTToolForHUDContainerView }.first
        XCTAssertNotNil(container)
        let panel = try! XCTUnwrap(container?.contentView)
        XCTAssertEqual(panel.accessibilityIdentifier, MMTToolForHUDAccessibilityID.panel)

        let identifiers = panel.subviews
            .filter { !$0.isHidden }
            .compactMap { $0.accessibilityIdentifier }
        XCTAssertEqual(identifiers.count, 2)
        XCTAssertTrue(identifiers.contains(MMTToolForHUDAccessibilityID.spinner))
        XCTAssertTrue(identifiers.contains(MMTToolForHUDAccessibilityID.text))
    }

    func testProgressHasIndicatorIdentifier() {
        MMTToolForHUD.showProgress(0.4, text: "Downloading", in: window)
        let panel = window.subviews
            .compactMap { $0 as? MMTToolForHUDContainerView }
            .first?.contentView
        let identifiers = panel?.subviews.filter { !$0.isHidden }.map { $0.accessibilityIdentifier ?? "" } ?? []
        XCTAssertTrue(identifiers.contains(MMTToolForHUDAccessibilityID.progressBar))
    }

    func testToastHasAccessibilityIdentifierAndLabel() {
        MMTToolForHUDToast.show("Automated hello", duration: 5, in: window)
        let item = window.subviews
            .compactMap { $0 as? MMTToolForHUDToastContainerView }
            .flatMap { $0.stack.arrangedSubviews }
            .compactMap { $0 as? MMTToolForHUDToastItemView }
            .first
        XCTAssertEqual(item?.isAccessibilityElement, true)
        XCTAssertEqual(item?.accessibilityIdentifier, MMTToolForHUDAccessibilityID.toast)
        XCTAssertEqual(item?.accessibilityLabel, "Automated hello")
    }

    func testDemoButtonsExposeIdentifiersForAppium() {
        // The demo app buttons use "demo.*" identifiers; verify the
        // convention through the fully-constructed demo view hierarchy.
        let viewController = ViewController()
        viewController.loadViewIfNeeded()
        let buttons = viewController.view.recursiveSubviews()
            .compactMap { $0 as? UIButton }
            .filter { $0.accessibilityIdentifier?.hasPrefix("demo.") == true }
        XCTAssertGreaterThanOrEqual(buttons.count, 14)
        XCTAssertEqual(Set(buttons.compactMap { $0.accessibilityIdentifier }).count, buttons.count)
    }
}

// MARK: - Test helpers

private extension UIView {
    func recursiveSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.recursiveSubviews() }
    }
}
