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
        MMTToolForHUD.dismiss(in: window, animated: false)
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
        XCTAssertEqual(config.spinnerColor, .white)
        XCTAssertEqual(config.successIconColor, .systemGreen)
        XCTAssertEqual(config.errorIconColor, .systemRed)
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
        MMTToolForHUD.dismiss(in: window) { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testDismissWithoutAnimationImmediately() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.dismiss(in: window, animated: false)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    func testDismissAfterDelay() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.dismiss(after: 0.3, in: window)
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

        MMTToolForHUD.updateProgress(0.75, in: window)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 0.75, accuracy: 0.001)
    }

    func testProgressClampedToClosedRange() {
        MMTToolForHUD.showProgress(1.8, in: window)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 1.0, accuracy: 0.001)

        MMTToolForHUD.updateProgress(-0.5, in: window)
        XCTAssertEqual(MMTToolForHUD.currentProgress ?? -1, 0.0, accuracy: 0.001)
    }

    func testProgressNilAfterDismiss() {
        MMTToolForHUD.showProgress(0.5, in: window)
        MMTToolForHUD.dismiss(in: window, animated: false)
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

    func testToastContainersAreIndependentPerWindow() {
        let otherWindow = UIWindow(frame: UIScreen.main.bounds)

        MMTToolForHUDToast.show("toast A", duration: 5, in: window)
        MMTToolForHUDToast.show("toast B", duration: 5, in: otherWindow)

        XCTAssertEqual(window.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 1)
        XCTAssertEqual(otherWindow.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 1)

        // Clearing one window leaves the other untouched.
        MMTToolForHUDToast.dismissAll(in: window)
        let expectation = expectation(description: "window A cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { expectation.fulfill() }
        wait(for: [expectation], timeout: 3)
        XCTAssertEqual(window.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 0)
        XCTAssertEqual(otherWindow.subviews.compactMap { $0 as? MMTToolForHUDToastContainerView }.count, 1)
    }

    func testHUDsOnSeparateWindowsAreIndependent() {
        let otherWindow = UIWindow(frame: UIScreen.main.bounds)

        MMTToolForHUD.showLoading("on window A", in: window)
        MMTToolForHUD.showLoading("on window B", in: otherWindow)

        XCTAssertTrue(MMTToolForHUD.isVisible(in: window))
        XCTAssertTrue(MMTToolForHUD.isVisible(in: otherWindow))

        MMTToolForHUD.dismiss(in: window, animated: false)
        XCTAssertFalse(MMTToolForHUD.isVisible(in: window))
        XCTAssertTrue(MMTToolForHUD.isVisible(in: otherWindow))

        MMTToolForHUD.dismiss(in: otherWindow, animated: false)
        XCTAssertFalse(MMTToolForHUD.isVisible)
    }

    // MARK: - Presenter state machine

    func testUpdateProgressIgnoredWhenNotVisible() {
        MMTToolForHUD.updateProgress(0.5)
        XCTAssertNil(MMTToolForHUD.currentProgress)
    }

    func testUpdateProgressIgnoredForSpinnerMode() {
        MMTToolForHUD.showLoading(in: window)
        MMTToolForHUD.updateProgress(0.5, in: window)
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
        MMTToolForHUD.dismiss(in: window) { expectation.fulfill() }
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

    func testLoadingPanelWidthNeverShrinksWhileVisible() {
        // First presentation: long text widens the panel.
        MMTToolForHUD.showLoading("a considerably longer loading message", in: window)
        MMTToolForHUD.dismiss(after: 2, in: self.window)

        let sticky = expectation(description: "width stays sticky")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let panel = self.window.subviews
                .compactMap { $0 as? MMTToolForHUDContainerView }
                .first?.contentView
            let wide = panel?.bounds.width ?? 0
            XCTAssertGreaterThan(wide, 76, "long text should widen the panel")

            // Same presentation, shorter text: width must not shrink.
            MMTToolForHUD.showLoading("done", in: self.window)
            MMTToolForHUD.showLoading(nil, in: self.window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertEqual(panel?.bounds.width ?? 0, wide, accuracy: 1.0,
                               "panel width must stay at its high-water mark")
                sticky.fulfill()
            }
        }
        wait(for: [sticky], timeout: 5)
    }

    func testFreshPresentationResetsPanelWidth() {
        MMTToolForHUD.showLoading("a considerably longer loading message", in: window)
        let reset = expectation(description: "fresh panel starts narrow")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            MMTToolForHUD.dismiss(in: self.window, animated: false)
            MMTToolForHUD.showLoading(nil, in: self.window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                let panel = self.window.subviews
                    .compactMap { $0 as? MMTToolForHUDContainerView }
                    .first?.contentView
                XCTAssertEqual(panel?.bounds.width ?? 0, 76, accuracy: 1.0,
                               "a fresh panel should start from its natural width")
                reset.fulfill()
            }
        }
        wait(for: [reset], timeout: 5)
    }

    func testTextStaysCenteredAcrossTextChanges() {
        MMTToolForHUD.showLoading("Downloading 100%", in: window)
        let centered = expectation(description: "label frame stays put")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            let panel = self.window.subviews
                .compactMap { $0 as? MMTToolForHUDContainerView }
                .first?.contentView
            let textLabel = panel?.subviews.first { $0 is UILabel && !$0.isHidden } as? UILabel
            let original = try! XCTUnwrap(textLabel).frame

            // Shorter text on the same panel: the label frame must not move
            // or resize; only the rendered text changes (centered in place).
            MMTToolForHUD.showLoading("Done 100%", in: self.window)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                XCTAssertEqual(textLabel?.frame, original,
                               "label must keep its frame so text stays centered")
                centered.fulfill()
            }
        }
        wait(for: [centered], timeout: 5)
    }

    // MARK: - Content view sizing

    func testPreferredSizeSpinnerOnly() {
        let contentView = MMTToolForHUDContentView()
        contentView.apply(config: MMTToolForHUDConfig())
        contentView.apply(mode: .spinner, text: nil, progress: 0, animated: false)
        let size = contentView.preferredSize(maxWidth: 300)
        // padding(16) * 2 + icon area(44)
        XCTAssertEqual(size.width, 76, accuracy: 0.5)
        XCTAssertEqual(size.height, 76, accuracy: 0.5)
    }

    func testPreferredSizeGrowsWithText() {
        let contentView = MMTToolForHUDContentView()
        contentView.apply(config: MMTToolForHUDConfig())

        contentView.apply(mode: .spinner, text: nil, progress: 0, animated: false)
        let withoutText = contentView.preferredSize(maxWidth: 300)

        contentView.apply(mode: .spinner, text: "Loading data", progress: 0, animated: false)
        let withText = contentView.preferredSize(maxWidth: 300)

        XCTAssertEqual(withoutText.width, 76, accuracy: 0.5)
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
        // padding(16) * 2 + bar width(132); bar mode always adds a percent
        // text line below the bar, so the height exceeds bar + paddings.
        XCTAssertEqual(size.width, 164, accuracy: 0.5)
        XCTAssertGreaterThan(size.height, 37)
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
            .filter { $0.accessibilityIdentifier?.hasPrefix("MMTToolForHUD.demo.") == true }
        XCTAssertGreaterThanOrEqual(buttons.count, 14)
        XCTAssertEqual(Set(buttons.compactMap { $0.accessibilityIdentifier }).count, buttons.count)
        // Every identifier follows the MMTToolForHUD.<area>.<element> format.
        for identifier in buttons.compactMap({ $0.accessibilityIdentifier }) {
            let segments = identifier.split(separator: ".")
            XCTAssertGreaterThanOrEqual(segments.count, 3, "identifier \(identifier) should be hierarchical")
        }
    }
}

// MARK: - Test helpers

private extension UIView {
    func recursiveSubviews() -> [UIView] {
        subviews + subviews.flatMap { $0.recursiveSubviews() }
    }
}

// MARK: - Performance testing

/// Automated performance benchmarks with budget assertions and JSON/Markdown
/// report output. Run via `scripts/run-performance-tests.sh`, which passes
/// PERF_REPORT_DIR to the test process.
final class MMTToolForHUDPerformanceTests: XCTestCase {

    private var window: UIWindow!
    private var originalConfig: MMTToolForHUDConfig!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
        originalConfig = MMTToolForHUD.config
        // Deterministic timing: disable animations and auto-dismiss.
        MMTToolForHUD.updateConfig {
            $0.isAnimationEnabled = false
            $0.statusAutoDismissDelay = 60
        }
    }

    override func tearDown() {
        MMTToolForHUD.config = originalConfig
        MMTToolForHUDToast.dismissAll()
        MMTToolForHUD.dismiss(in: window, animated: false)
        window = nil
        super.tearDown()
    }

    // MARK: Benchmark harness

    struct Benchmark: Codable {
        let name: String
        let iterations: Int
        let averageMs: Double
        let maxMs: Double
        let budgetMs: Double
        var passed: Bool { averageMs <= budgetMs }
    }

    private func benchmark(_ name: String,
                           budgetMs: Double,
                           iterations: Int,
                           warmup: Int = 3,
                           _ body: () -> Void) {
        for _ in 0..<warmup { body() }

        var maxMs = 0.0
        let start = CFAbsoluteTimeGetCurrent()
        for _ in 0..<iterations {
            let t0 = CFAbsoluteTimeGetCurrent()
            body()
            maxMs = max(maxMs, (CFAbsoluteTimeGetCurrent() - t0) * 1000)
        }
        let totalMs = (CFAbsoluteTimeGetCurrent() - start) * 1000
        let averageMs = totalMs / Double(iterations)

        Self.collected.append(Benchmark(name: name,
                                         iterations: iterations,
                                         averageMs: averageMs,
                                         maxMs: maxMs,
                                         budgetMs: budgetMs))
        XCTAssertLessThanOrEqual(averageMs, budgetMs,
                                 "\(name): average \(String(format: "%.3f", averageMs))ms exceeded budget \(budgetMs)ms")
    }

    private static var collected: [Benchmark] = []

    // MARK: Report

    private func writeReport(memoryDeltaKb: Int64?) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd HH.mm.ss"
        let stamp = formatter.string(from: Date())

        let reportDir = ProcessInfo.processInfo.environment["PERF_REPORT_DIR"]
            ?? NSTemporaryDirectory()
        let url = URL(fileURLWithPath: reportDir)
        try? FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)

        struct Report: Codable {
            let generatedAt: String
            let device: String
            let benchmarks: [Benchmark]
            let memoryDeltaKb: Int64?
        }
        var sysinfo = utsname()
        uname(&sysinfo)
        let device = withUnsafeBytes(of: &sysinfo.machine) { bytes in
            String(decoding: bytes.prefix(while: { $0 != 0 }), as: UTF8.self)
        }
        let report = Report(generatedAt: stamp,
                            device: device,
                            benchmarks: Self.collected,
                            memoryDeltaKb: memoryDeltaKb)

        if let data = try? JSONEncoder().encode(report) {
            let containerDir = url.appendingPathComponent("perf-report-\(stamp).json")
            try? data.write(to: containerDir)
        }

        var markdown = """
        # MMTToolForHUD performance report

        Generated: \(stamp) · Device: \(device)

        | Benchmark | Iterations | Average | Max | Budget | Status |
        |---|---:|---:|---:|---:|---|
        """
        for b in Self.collected {
            markdown += "\n| \(b.name) | \(b.iterations) | \(String(format: "%.3f", b.averageMs))ms | \(String(format: "%.3f", b.maxMs))ms | \(String(format: "%.1f", b.budgetMs))ms | \(b.passed ? "PASS" : "FAIL") |"
        }
        if let delta = memoryDeltaKb {
            markdown += "\n\nMemory footprint delta after stress cycles: \(delta) KB (informational, no budget)."
        }
        try? markdown.data(using: .utf8)?
            .write(to: url.appendingPathComponent("perf-report-\(stamp).md"))

        // Always emit the report on stdout between sentinels so the runner
        // script can extract it reliably from the build log.
        let json = (try? JSONEncoder().encode(report))
            .flatMap { String(data: $0, encoding: .utf8) } ?? "{}"
        print("\n===== MMTToolForHUD PERFORMANCE-BEGIN =====\n\(markdown)\n===== MMTToolForHUD PERFORMANCE-JSON =====\n\(json)\n===== MMTToolForHUD PERFORMANCE-END =====")
    }

    // MARK: Memory helper

    private func physFootprintKb() -> Int64? {
        var info = task_vm_info_data_t()
        var count = mach_msg_type_number_t(
            MemoryLayout<task_vm_info_data_t>.size / MemoryLayout<integer_t>.size)
        let result = withUnsafeMutablePointer(to: &info) { pointer in
            pointer.withMemoryRebound(to: integer_t.self, capacity: Int(count)) {
                task_info(mach_task_self_, task_flavor_t(TASK_VM_INFO), $0, &count)
            }
        }
        guard result == KERN_SUCCESS else { return nil }
        return Int64(info.phys_footprint) / 1024
    }

    // MARK: Benchmarks

    func testPerformanceReport() {
        Self.collected = []

        benchmark("showLoading + layout + dismiss (per cycle)",
                  budgetMs: 15, iterations: 50) {
            MMTToolForHUD.showLoading("Loading, please wait…", in: self.window)
            self.window.layoutIfNeeded()
            MMTToolForHUD.dismiss(in: self.window, animated: false)
        }

        MMTToolForHUD.showProgress(0, text: "Downloading", in: window)
        window.layoutIfNeeded()
        benchmark("updateProgress (per call)",
                  budgetMs: 2, iterations: 200, warmup: 10) {
            MMTToolForHUD.updateProgress(Float.random(in: 0...1), in: self.window)
        }
        MMTToolForHUD.dismiss(in: window, animated: false)

        let contentView = MMTToolForHUDContentView()
        contentView.apply(config: MMTToolForHUD.config)
        contentView.apply(mode: .spinner,
                          text: "A fairly long loading message that wraps and exercises text measurement",
                          progress: 0,
                          animated: false)
        benchmark("preferredSize with long text (per call)",
                  budgetMs: 1, iterations: 500, warmup: 10) {
            _ = contentView.preferredSize(maxWidth: 300)
        }

        benchmark("toast present + remove (per cycle)",
                  budgetMs: 5, iterations: 100) {
            MMTToolForHUDToast.show("perf", duration: 60, in: self.window)
            if let item = self.window.subviews
                .compactMap({ $0 as? MMTToolForHUDToastContainerView })
                .flatMap({ $0.stack.arrangedSubviews })
                .compactMap({ $0 as? MMTToolForHUDToastItemView })
                .first {
                MMTToolForHUDToastManager.shared.removeItem(item, animated: false)
            }
        }

        // Informational memory stress: many full cycles must not grow the
        // footprint (containers and work items must be released).
        let beforeKb = physFootprintKb()
        for _ in 0..<300 {
            MMTToolForHUD.showLoading("stress", in: window)
            MMTToolForHUD.dismiss(in: window, animated: false)
            MMTToolForHUDToast.show("stress", duration: 60, in: window)
            MMTToolForHUDToast.dismissAll()
        }
        let afterKb = physFootprintKb()

        writeReport(memoryDeltaKb: (beforeKb != nil && afterKb != nil) ? afterKb! - beforeKb! : nil)
    }

    // MARK: XCTest-native baselines (curves visible in Xcode)

    func testShowDismissBaseline() {
        measure {
            MMTToolForHUD.showLoading("Loading", in: window)
            window.layoutIfNeeded()
            MMTToolForHUD.dismiss(in: window, animated: false)
        }
    }

    func testProgressUpdateBaseline() {
        MMTToolForHUD.showProgress(0, text: "Downloading", in: window)
        measure {
            for i in 1...25 {
                MMTToolForHUD.updateProgress(Float(i) / 25, in: window)
            }
        }
        MMTToolForHUD.dismiss(in: window, animated: false)
    }
}

// MARK: - Review fixes regression

final class MMTToolForHUDReviewFixTests: XCTestCase {

    private var window: UIWindow!

    override func setUp() {
        super.setUp()
        window = UIWindow(frame: UIScreen.main.bounds)
        window.makeKeyAndVisible()
    }

    override func tearDown() {
        MMTToolForHUD.dismiss(in: window, animated: false)
        MMTToolForHUDToast.dismissAll()
        window = nil
        super.tearDown()
    }

    /// Getters must be readable from background threads without racing
    /// main-thread mutations.
    func testGettersAreThreadSafe() {
        let expectation = expectation(description: "background read")
        DispatchQueue.global().async {
            let config = MMTToolForHUD.config
            XCTAssertGreaterThan(config.animationDuration, 0)
            _ = MMTToolForHUD.isVisible
            _ = MMTToolForHUD.currentProgress
            _ = MMTToolForHUDToast.isVisible
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 3)
    }

    /// The status icon tint comes from the presentation payload, not from
    /// string matching on the symbol name.
    func testStatusIconTintMatchesConfiguration() {
        MMTToolForHUD.updateConfig {
            $0.successIconColor = .systemGreen
            $0.errorIconColor = .systemRed
        }
        MMTToolForHUD.showSuccess("ok", in: window)
        var panel = window.subviews.compactMap { $0 as? MMTToolForHUDContainerView }.first?.contentView
        XCTAssertEqual(panel?.subviews.first { $0 is UIImageView && !$0.isHidden }?.tintColor, .systemGreen)

        MMTToolForHUD.showError("bad", in: window)
        panel = window.subviews.compactMap { $0 as? MMTToolForHUDContainerView }.first?.contentView
        XCTAssertEqual(panel?.subviews.first { $0 is UIImageView && !$0.isHidden }?.tintColor, .systemRed)
    }

    /// Canceling the bookkeeping must happen even when the item was already
    /// detached from its container (externally removed container).
    func testAutoRemoveBookkeepingClearedForDetachedItems() {
        MMTToolForHUDToast.show("detached", duration: 60, in: window)
        let item = window.subviews
            .compactMap { $0 as? MMTToolForHUDToastContainerView }
            .flatMap { $0.stack.arrangedSubviews }
            .compactMap { $0 as? MMTToolForHUDToastItemView }
            .first
        // Simulate an external removal of the whole container.
        item?.superview?.superview?.removeFromSuperview()
        if let item {
            MMTToolForHUDToastManager.shared.removeItem(item, animated: false)
        }
        XCTAssertEqual(MMTToolForHUDToastManager.shared.pendingAutoRemoveCount, 0)
    }
}
