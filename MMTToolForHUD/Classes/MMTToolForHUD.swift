//
//  MMTToolForHUD.swift
//  MMTToolForHUD
//
//  Created by nealwills on 2026/11/09.
//

import UIKit

/// Main HUD entry point: loading / progress / status presentation.
///
///     MMTToolForHUD.showLoading("Loading...")
///     MMTToolForHUD.showProgress(0.3, text: "Downloading")
///     MMTToolForHUD.updateProgress(0.8)
///     MMTToolForHUD.showSuccess("Saved")       // auto-dismisses
///     MMTToolForHUD.dismiss()
///
/// Every show / dismiss call targets a specific window (defaults to the
/// front window) and only manages the HUD attached to that window, so
/// multiple windows can display independent HUDs.
///
/// All APIs are thread-safe: calls from non-main threads are dispatched
/// to the main thread automatically.
public final class MMTToolForHUD {

    static let presenter = MMTToolForHUDPresenter()

    private init() {}

    // MARK: - Configuration

    /// Global configuration; changes only apply to HUDs presented afterwards.
    ///
    /// - Note: this is a value type. Writing `MMTToolForHUD.config.someField = x`
    ///   mutates a temporary copy and has no effect; use `updateConfig(_:)`
    ///   or assign a complete value instead.
    public static var config: MMTToolForHUDConfig {
        get { onMainSync { presenter.config } }
        set { onMain { presenter.config = newValue } }
    }

    /// Modifies the global configuration in place.
    public static func updateConfig(_ mutate: @escaping (inout MMTToolForHUDConfig) -> Void) {
        onMain {
            var config = presenter.config
            mutate(&config)
            presenter.config = config
        }
    }

    // MARK: - Loading

    /// Shows a loading spinner, optionally with text, on the given window.
    /// If a HUD is already visible there its content is replaced in place;
    /// call `dismiss(in:)` to hide it.
    public static func showLoading(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .spinner, text: text, progress: 0, window: window)
        }
    }

    // MARK: - Progress

    /// Shows progress on the given window; `style` defaults to
    /// `config.progressStyle`. Progress is clamped to 0.0...1.0.
    public static func showProgress(_ progress: Float,
                                    text: String? = nil,
                                    style: MMTToolForHUDProgressStyle? = nil,
                                    in window: UIWindow? = nil) {
        onMain {
            let mode: MMTToolForHUDContentView.Mode = (style ?? presenter.config.progressStyle) == .ring ? .ring : .bar
            presenter.show(mode: mode, text: text, progress: progress, window: window)
        }
    }

    /// Updates the progress of the HUD on the given window (front window by
    /// default); ignored when no progress HUD is shown there. Passing nil as
    /// text keeps the current text.
    public static func updateProgress(_ progress: Float,
                                      text: String? = nil,
                                      in window: UIWindow? = nil) {
        onMain {
            presenter.updateProgress(progress, text: text, window: window)
        }
    }

    // MARK: - Status

    /// Shows a success status (checkmark) on the given window that
    /// auto-dismisses after `config.statusAutoDismissDelay` seconds.
    public static func showSuccess(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .symbol(name: "checkmark.circle.fill",
                                         tint: presenter.config.successIconColor,
                                         label: "Success"),
                           text: text, progress: 0, window: window,
                           autoDismissAfter: presenter.config.statusAutoDismissDelay)
        }
    }

    /// Shows an error status (cross) on the given window that auto-dismisses
    /// after `config.statusAutoDismissDelay` seconds.
    public static func showError(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .symbol(name: "xmark.circle.fill",
                                         tint: presenter.config.errorIconColor,
                                         label: "Error"),
                           text: text, progress: 0, window: window,
                           autoDismissAfter: presenter.config.statusAutoDismissDelay)
        }
    }

    // MARK: - Dismissal

    /// Dismisses the HUD on the given window (front window by default).
    /// `completion` runs on the main thread after the HUD is fully removed.
    public static func dismiss(in window: UIWindow? = nil,
                               animated: Bool = true,
                               completion: (() -> Void)? = nil) {
        onMain {
            presenter.dismiss(window: window, animated: animated, completion: completion)
        }
    }

    /// Dismisses the HUD on the given window after a delay.
    public static func dismiss(after delay: TimeInterval,
                               in window: UIWindow? = nil,
                               animated: Bool = true,
                               completion: (() -> Void)? = nil) {
        onMain {
            presenter.scheduleDismiss(after: delay, window: window,
                                      animated: animated, completion: completion)
        }
    }

    // MARK: - State

    /// Whether a HUD is visible on any window.
    public static var isVisible: Bool { onMainSync { presenter.hasVisibleHUD } }

    /// Whether a HUD is visible on the given window (front window by default).
    public static func isVisible(in window: UIWindow? = nil) -> Bool {
        onMainSync { presenter.isVisible(window: window) }
    }

    /// The progress of the visible HUD on any window, or nil.
    public static var currentProgress: Float? { onMainSync { presenter.currentProgress(window: nil) } }

    /// The progress of the HUD on the given window, or nil.
    public static func currentProgress(in window: UIWindow? = nil) -> Float? {
        onMainSync { presenter.currentProgress(window: window) }
    }

    // MARK: - Utilities

    static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }

    /// Reads main-thread-confined state safely from any thread.
    static func onMainSync<T>(_ work: () -> T) -> T {
        if Thread.isMainThread {
            return work()
        }
        return DispatchQueue.main.sync(execute: work)
    }
}

// MARK: - Presentation controller

/// Manages one HUD container per window: creation, updates, dismissal and
/// auto-dismissal only ever touch the container attached to the target window.
final class MMTToolForHUDPresenter {

    var config = MMTToolForHUDConfig()

    /// One container per window; detached containers are purged on access.
    private var containers: [MMTToolForHUDContainerView] = []

    // MARK: Lookup

    private func purgeDetachedContainers() {
        containers.removeAll { $0.window == nil }
    }

    func container(for window: UIWindow) -> MMTToolForHUDContainerView? {
        purgeDetachedContainers()
        return containers.first { $0.window === window }
    }

    private func resolveWindow(_ window: UIWindow?) -> UIWindow? {
        window ?? MMTToolForHUDWindowFinder.frontWindow()
    }

    var hasVisibleHUD: Bool {
        isVisible(window: nil)
    }

    func isVisible(window: UIWindow?) -> Bool {
        if let window {
            guard let container = container(for: window) else { return false }
            return container.superview != nil && !container.isDismissing
        }
        purgeDetachedContainers()
        return containers.contains { $0.superview != nil && !$0.isDismissing }
    }

    func currentProgress(window: UIWindow?) -> Float? {
        let target: MMTToolForHUDContainerView?
        if let window {
            target = container(for: window)
        } else {
            purgeDetachedContainers()
            target = containers.first { $0.superview != nil && !$0.isDismissing }
        }
        guard let target,
              target.contentView.mode == .ring || target.contentView.mode == .bar
        else { return nil }
        return target.contentView.progress
    }

    // MARK: Showing

    func show(mode: MMTToolForHUDContentView.Mode,
              text: String?,
              progress: Float,
              window: UIWindow?,
              autoDismissAfter: TimeInterval? = nil) {
        guard let targetWindow = resolveWindow(window) else { return }

        if let existing = container(for: targetWindow), existing.isDismissing {
            finishDismissImmediately(existing)
        }

        if let existing = container(for: targetWindow) {
            cancelAutoDismiss(existing)
            existing.apply(config: config)
            existing.contentView.apply(mode: mode, text: text, progress: progress, animated: true)
            // Animate the panel resize so width changes flow both ways.
            existing.setNeedsLayout()
            if config.isAnimationEnabled {
                UIView.animate(
                    withDuration: config.animationDuration,
                    delay: 0,
                    options: [.allowUserInteraction, .curveEaseInOut]) {
                    existing.layoutIfNeeded()
                }
            }
            scheduleAutoDismissIfNeeded(after: autoDismissAfter, for: existing)
            return
        }

        let container = MMTToolForHUDContainerView(config: config)
        container.frame = targetWindow.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.contentView.apply(mode: mode, text: text, progress: progress, animated: false)
        targetWindow.addSubview(container)
        containers.append(container)
        container.layoutIfNeeded()

        if config.isAnimationEnabled {
            container.alpha = 0
            container.contentView.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
            UIView.animate(
                withDuration: config.animationDuration,
                delay: 0,
                usingSpringWithDamping: 0.75,
                initialSpringVelocity: 0.5,
                options: [.allowUserInteraction, .curveEaseOut]) {
                container.alpha = 1
                container.contentView.transform = .identity
            }
        }

        scheduleAutoDismissIfNeeded(after: autoDismissAfter, for: container)
    }

    func updateProgress(_ progress: Float, text: String?, window: UIWindow?) {
        guard let targetWindow = resolveWindow(window),
              let container = container(for: targetWindow),
              container.superview != nil, !container.isDismissing,
              container.contentView.mode == .ring || container.contentView.mode == .bar
        else { return }
        if let text {
            container.contentView.apply(mode: container.contentView.mode,
                                        text: text,
                                        progress: progress,
                                        animated: true)
        } else {
            container.contentView.setProgress(progress, animated: true)
        }
        // The text change may resize the panel; animate it both ways.
        container.setNeedsLayout()
        if config.isAnimationEnabled {
            UIView.animate(
                withDuration: config.animationDuration,
                delay: 0,
                options: [.allowUserInteraction, .curveEaseInOut]) {
                container.layoutIfNeeded()
            }
        }
    }

    // MARK: Dismissing

    func dismiss(window: UIWindow?, animated: Bool, completion: (() -> Void)?) {
        guard let targetWindow = resolveWindow(window),
              let container = container(for: targetWindow) else {
            completion?()
            return
        }
        dismissContainer(container, animated: animated, completion: completion)
    }

    func scheduleDismiss(after delay: TimeInterval,
                         window: UIWindow?,
                         animated: Bool,
                         completion: (() -> Void)?) {
        // Attach to the container when it exists so a new show on the same
        // window cancels the pending dismissal; otherwise the work fires on
        // whatever HUD is on that window at deadline time (i.e. a show
        // after scheduling is still dismissed when the delay elapses).
        let targetWindow = resolveWindow(window)
        let targetContainer = targetWindow.flatMap { self.container(for: $0) }
        targetContainer?.scheduledDismissWork?.cancel()
        let work = DispatchWorkItem { [weak self, weak targetContainer] in
            guard let self else { return }
            if let targetContainer {
                self.dismissContainer(targetContainer, animated: animated, completion: completion)
            } else {
                self.dismiss(window: window, animated: animated, completion: completion)
            }
        }
        targetContainer?.scheduledDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func dismissContainer(_ container: MMTToolForHUDContainerView,
                                  animated: Bool,
                                  completion: (() -> Void)?) {
        cancelAutoDismiss(container)
        guard container.superview != nil else {
            completion?()
            return
        }
        guard animated, config.isAnimationEnabled else {
            finishDismissImmediately(container)
            completion?()
            return
        }

        container.isDismissing = true
        UIView.animate(
            withDuration: config.animationDuration,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn]) {
            container.alpha = 0
            container.contentView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            container.removeFromSuperview()
            self.containers.removeAll { $0 === container }
            completion?()
        }
    }

    // MARK: Internals

    private func scheduleAutoDismissIfNeeded(after delay: TimeInterval?,
                                             for container: MMTToolForHUDContainerView) {
        cancelAutoDismiss(container)
        guard let delay else { return }
        let work = DispatchWorkItem { [weak self, weak container] in
            guard let self, let container else { return }
            self.dismissContainer(container, animated: true, completion: nil)
        }
        container.autoDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelAutoDismiss(_ container: MMTToolForHUDContainerView) {
        container.autoDismissWork?.cancel()
        container.autoDismissWork = nil
        container.scheduledDismissWork?.cancel()
        container.scheduledDismissWork = nil
    }

    private func finishDismissImmediately(_ container: MMTToolForHUDContainerView) {
        container.removeFromSuperview()
        containers.removeAll { $0 === container }
    }
}
