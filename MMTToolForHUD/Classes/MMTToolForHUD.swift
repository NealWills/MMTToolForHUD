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
/// All APIs are thread-safe: calls from non-main threads are dispatched
/// to the main thread automatically.
public final class MMTToolForHUD {

    static let presenter = MMTToolForHUDPresenter()

    private init() {}

    // MARK: - Configuration

    /// Global configuration; changes only apply to HUDs presented afterwards.
    public static var config: MMTToolForHUDConfig {
        get { presenter.config }
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

    /// Shows a loading spinner, optionally with text. If a HUD is already
    /// visible its content is replaced in place; call `dismiss()` to hide it.
    public static func showLoading(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .spinner, text: text, progress: 0, window: window)
        }
    }

    // MARK: - Progress

    /// Shows progress; `style` defaults to `config.progressStyle`.
    /// Progress is clamped to 0.0...1.0.
    public static func showProgress(_ progress: Float,
                                    text: String? = nil,
                                    style: MMTToolForHUDProgressStyle? = nil,
                                    in window: UIWindow? = nil) {
        onMain {
            let mode: MMTToolForHUDContentView.Mode = (style ?? presenter.config.progressStyle) == .ring ? .ring : .bar
            presenter.show(mode: mode, text: text, progress: progress, window: window)
        }
    }

    /// Updates the progress of the visible HUD; ignored when nothing is
    /// shown. Passing nil as text keeps the current text.
    public static func updateProgress(_ progress: Float, text: String? = nil) {
        onMain {
            presenter.updateProgress(progress, text: text)
        }
    }

    // MARK: - Status

    /// Shows a success status (checkmark) that auto-dismisses after
    /// `config.statusAutoDismissDelay` seconds.
    public static func showSuccess(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .symbol(name: "checkmark.circle.fill"),
                           text: text, progress: 0, window: window,
                           autoDismissAfter: presenter.config.statusAutoDismissDelay)
        }
    }

    /// Shows an error status (cross) that auto-dismisses after
    /// `config.statusAutoDismissDelay` seconds.
    public static func showError(_ text: String? = nil, in window: UIWindow? = nil) {
        onMain {
            presenter.show(mode: .symbol(name: "xmark.circle.fill"),
                           text: text, progress: 0, window: window,
                           autoDismissAfter: presenter.config.statusAutoDismissDelay)
        }
    }

    // MARK: - Dismissal

    /// Dismisses the visible HUD. `completion` runs on the main thread after
    /// the HUD is fully removed.
    public static func dismiss(animated: Bool = true, completion: (() -> Void)? = nil) {
        onMain {
            presenter.dismiss(animated: animated, completion: completion)
        }
    }

    /// Dismisses the visible HUD after a delay.
    public static func dismiss(after delay: TimeInterval,
                               animated: Bool = true,
                               completion: (() -> Void)? = nil) {
        onMain {
            presenter.scheduleDismiss(after: delay, animated: animated, completion: completion)
        }
    }

    // MARK: - State

    /// Whether a HUD is currently visible (still true while the hide
    /// animation is running).
    public static var isVisible: Bool { presenter.isVisible }

    /// The current progress value, or nil when no progress HUD is shown.
    public static var currentProgress: Float? { presenter.currentProgress }

    // MARK: - Utilities

    static func onMain(_ work: @escaping () -> Void) {
        if Thread.isMainThread {
            work()
        } else {
            DispatchQueue.main.async(execute: work)
        }
    }
}

// MARK: - Presentation controller

/// Creates, updates, dismisses and auto-dismisses the single shared HUD.
final class MMTToolForHUDPresenter {

    var config = MMTToolForHUDConfig()

    private var containerView: MMTToolForHUDContainerView?
    private var autoDismissWork: DispatchWorkItem?
    private var scheduledDismissWork: DispatchWorkItem?
    private var isDismissing = false

    var isVisible: Bool { containerView?.superview != nil && !isDismissing }

    var currentProgress: Float? {
        guard let containerView, containerView.superview != nil,
              containerView.contentView.mode == .ring || containerView.contentView.mode == .bar
        else { return nil }
        return containerView.contentView.progress
    }

    // MARK: Showing

    func show(mode: MMTToolForHUDContentView.Mode,
              text: String?,
              progress: Float,
              window: UIWindow?,
              autoDismissAfter: TimeInterval? = nil) {
        cancelAutoDismiss()

        guard let targetWindow = window ?? MMTToolForHUDWindowFinder.frontWindow() else { return }

        if isDismissing {
            finishDismissImmediately()
        }

        if let existing = containerView {
            if existing.window === targetWindow {
                existing.apply(config: config)
                existing.contentView.apply(mode: mode, text: text, progress: progress, animated: true)
                scheduleAutoDismissIfNeeded(after: autoDismissAfter)
                return
            }
            // The target window changed; discard the old container.
            finishDismissImmediately()
        }

        let container = MMTToolForHUDContainerView(config: config)
        container.frame = targetWindow.bounds
        container.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        container.contentView.apply(mode: mode, text: text, progress: progress, animated: false)
        targetWindow.addSubview(container)
        containerView = container
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

        scheduleAutoDismissIfNeeded(after: autoDismissAfter)
    }

    func updateProgress(_ progress: Float, text: String?) {
        guard let container = containerView, container.superview != nil, !isDismissing else { return }
        guard container.contentView.mode == .ring || container.contentView.mode == .bar else { return }
        if let text {
            container.contentView.apply(mode: container.contentView.mode,
                                        text: text,
                                        progress: progress,
                                        animated: true)
        } else {
            container.contentView.setProgress(progress, animated: true)
        }
        // The text change may resize the panel.
        container.setNeedsLayout()
    }

    // MARK: Dismissing

    func dismiss(animated: Bool, completion: (() -> Void)? = nil) {
        cancelAutoDismiss()
        guard let container = containerView, container.superview != nil else {
            completion?()
            return
        }
        guard animated, config.isAnimationEnabled else {
            finishDismissImmediately()
            completion?()
            return
        }

        isDismissing = true
        UIView.animate(
            withDuration: config.animationDuration,
            delay: 0,
            options: [.allowUserInteraction, .curveEaseIn]) {
            container.alpha = 0
            container.contentView.transform = CGAffineTransform(scaleX: 0.92, y: 0.92)
        } completion: { _ in
            container.removeFromSuperview()
            if self.containerView === container {
                self.containerView = nil
                self.isDismissing = false
            }
            completion?()
        }
    }

    func scheduleDismiss(after delay: TimeInterval, animated: Bool, completion: (() -> Void)?) {
        scheduledDismissWork?.cancel()
        let work = DispatchWorkItem {
            self.dismiss(animated: animated, completion: completion)
        }
        scheduledDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    // MARK: Internals

    private func scheduleAutoDismissIfNeeded(after delay: TimeInterval?) {
        guard let delay else { return }
        let work = DispatchWorkItem { [weak self] in
            self?.dismiss(animated: true, completion: nil)
        }
        autoDismissWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + delay, execute: work)
    }

    private func cancelAutoDismiss() {
        autoDismissWork?.cancel()
        autoDismissWork = nil
        scheduledDismissWork?.cancel()
        scheduledDismissWork = nil
    }

    private func finishDismissImmediately() {
        containerView?.removeFromSuperview()
        containerView = nil
        isDismissing = false
    }
}
