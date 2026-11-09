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
}
