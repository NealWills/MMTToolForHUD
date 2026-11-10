//
//  MMTToolForHUDPresenter.swift
//  MMTToolForHUD
//
//  Created by nealwills on 2026/11/09.
//

import UIKit

// MARK: - Internal entry-point surface

/// Internal implementation members of the public `MMTToolForHUD` entry
/// point (declared in MMTToolForHUDAPI.swift).
extension MMTToolForHUD {

    /// Shared presentation controller owning one HUD container per window.
    static let presenter = MMTToolForHUDPresenter()

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
