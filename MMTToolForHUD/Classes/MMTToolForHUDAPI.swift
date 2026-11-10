//
//  MMTToolForHUDAPI.swift
//  MMTToolForHUD
//
//  Created by nealwills on 2026/11/10.
//

import UIKit

/// The complete public API surface of MMTToolForHUD.
///
/// Everything external code may touch lives in this file:
///
/// - `MMTToolForHUD` — loading / progress / status entry point
/// - `MMTToolForHUDToast` — toast entry point
/// - `MMTToolForHUDConfig` — appearance & behavior configuration
/// - `MMTToolForHUDProgressStyle`, `MMTToolForHUDToastPosition`,
///   `MMTToolForHUDAccessibilityID` — supporting public types
///
/// Every other file under `Classes/` is internal implementation.
// MARK: - HUD entry point

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

    private init() {}

    // MARK: - Version

    /// The current version of the MMTToolForHUD library (e.g. `"0.6.2"`),
    /// kept in sync with the podspec.
    public static let version = "0.6.2"

    /// Release notes for the current version: what changed since the
    /// previous release. Kept in sync with the version's release commit.
    public static let versionDescription = """
        Fixed multi-line text measurement for explicit newlines and \
        word-wrapped text, sanitized NaN / infinite progress values, \
        anchored the panel top edge so indicators never shift when text \
        changes line count, and seeded indicator frames to remove the \
        fly-in-from-corner transition when a loading HUD switches to progress.
        """

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
}

// MARK: - Toast entry point

/// Toast entry point: stackable, auto-dismissing, never blocks touches.
///
///     MMTToolForHUDToast.show("Saved")
///     MMTToolForHUDToast.success("Submitted")
///     MMTToolForHUDToast.error("Network error", position: .top)
///     MMTToolForHUDToast.dismissAll()
///
/// All APIs are thread-safe: calls from non-main threads are dispatched
/// to the main thread automatically.
public final class MMTToolForHUDToast {

    private init() {}

    // MARK: - Presenting

    /// Shows a plain-text toast.
    /// - Parameters:
    ///   - text: Message text; multi-line is supported.
    ///   - duration: How long the toast stays visible; defaults to
    ///     `config.toastDuration`.
    ///   - position: Where the toast appears; defaults to
    ///     `config.toastPosition`.
    public static func show(_ text: String,
                            duration: TimeInterval? = nil,
                            position: MMTToolForHUDToastPosition? = nil,
                            in window: UIWindow? = nil) {
        MMTToolForHUD.onMain {
            MMTToolForHUDToastManager.shared.show(text: text, icon: nil,
                                                  duration: duration, position: position, window: window)
        }
    }

    /// Shows a success toast (green checkmark icon).
    public static func success(_ text: String,
                               duration: TimeInterval? = nil,
                               position: MMTToolForHUDToastPosition? = nil,
                               in window: UIWindow? = nil) {
        MMTToolForHUD.onMain {
            MMTToolForHUDToastManager.shared.show(text: text,
                                                  icon: ("checkmark.circle.fill",
                                                         UIColor(red: 52 / 255, green: 199 / 255, blue: 89 / 255, alpha: 1)),
                                                  duration: duration, position: position, window: window)
        }
    }

    /// Shows an error toast (red cross icon).
    public static func error(_ text: String,
                             duration: TimeInterval? = nil,
                             position: MMTToolForHUDToastPosition? = nil,
                             in window: UIWindow? = nil) {
        MMTToolForHUD.onMain {
            MMTToolForHUDToastManager.shared.show(text: text,
                                                  icon: ("xmark.circle.fill",
                                                         UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)),
                                                  duration: duration, position: position, window: window)
        }
    }

    /// Shows an info toast (blue info icon).
    public static func info(_ text: String,
                            duration: TimeInterval? = nil,
                            position: MMTToolForHUDToastPosition? = nil,
                            in window: UIWindow? = nil) {
        MMTToolForHUD.onMain {
            MMTToolForHUDToastManager.shared.show(text: text,
                                                  icon: ("info.circle.fill",
                                                         UIColor(red: 0, green: 122 / 255, blue: 1, alpha: 1)),
                                                  duration: duration, position: position, window: window)
        }
    }

    /// Removes all visible toasts immediately (animated). Pass a window to
    /// only clear the toasts on that window; nil clears every window.
    public static func dismissAll(in window: UIWindow? = nil) {
        MMTToolForHUD.onMain {
            MMTToolForHUDToastManager.shared.dismissAll(in: window)
        }
    }

    // MARK: - State / configuration

    /// Whether any toast is currently visible on any window.
    public static var isVisible: Bool {
        MMTToolForHUD.onMainSync { MMTToolForHUDToastManager.shared.hasVisibleToast(in: nil) }
    }

    /// Whether a toast is visible on the given window.
    public static func isVisible(in window: UIWindow?) -> Bool {
        MMTToolForHUD.onMainSync { MMTToolForHUDToastManager.shared.hasVisibleToast(in: window) }
    }

    /// Alias of the global configuration; identical to `MMTToolForHUD.config`.
    public static var config: MMTToolForHUDConfig {
        get { MMTToolForHUD.config }
        set { MMTToolForHUD.config = newValue }
    }
}

// MARK: - Configuration

/// Appearance and behavior configuration for the HUD and toast.
///
/// Read and write the global configuration via `MMTToolForHUD.config` /
/// `MMTToolForHUDToast.config`. Changes only apply to HUDs and toasts
/// presented afterwards.
///
/// All default colors are fixed RGB values created with
/// `UIColor(red:green:blue:alpha:)`; they render identically in light and
/// dark mode and are never swapped by the system.
public struct MMTToolForHUDConfig {

    // MARK: - General

    /// Whether show / hide animations are enabled.
    public var isAnimationEnabled = true
    /// Duration of the show / hide animation, in seconds.
    public var animationDuration: TimeInterval = 0.25
    /// Delay before `showSuccess` / `showError` auto-dismisses, in seconds.
    public var statusAutoDismissDelay: TimeInterval = 1.6
    /// Touch interception policy (HUD only; toasts never block touches).
    public var interactionStyle = InteractionStyle.blockHUD
    /// Corner radius of the HUD panel.
    public var cornerRadius: CGFloat = 16
    /// Padding between the HUD panel edge and its content.
    public var hudPadding: CGFloat = 16
    /// Vertical spacing between the HUD indicator and its text.
    public var hudTextSpacing: CGFloat = 6
    /// Minimum distance between the HUD panel and the screen edges.
    public var hudMargin: CGFloat = 28

    // MARK: - HUD colors & fonts

    /// HUD background color.
    public var hudBackgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.9)
    /// Tint of the bar / ring progress indicator and its percent label.
    public var tintColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    /// Render color of the loading spinner.
    public var spinnerColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    /// Render color of the success status icon.
    public var successIconColor = UIColor(red: 52 / 255, green: 199 / 255, blue: 89 / 255, alpha: 1)
    /// Render color of the error status icon.
    public var errorIconColor = UIColor(red: 1, green: 59 / 255, blue: 48 / 255, alpha: 1)
    /// HUD text color.
    public var textColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    /// HUD text font.
    public var textFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    // MARK: - Progress

    /// Default style used by `showProgress` when none is specified.
    public var progressStyle = MMTToolForHUDProgressStyle.bar
    /// Width of the bar-style progress indicator.
    public var barProgressWidth: CGFloat = 132
    /// Thickness of the bar-style progress indicator.
    public var barProgressHeight: CGFloat = 5
    /// Radius of the ring-style progress indicator.
    public var ringProgressRadius: CGFloat = 21
    /// Line width of the ring-style progress indicator.
    public var ringProgressLineWidth: CGFloat = 4
    /// Color of the progress track.
    public var progressTrackColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.28)

    // MARK: - Toast

    /// Default toast duration, in seconds.
    public var toastDuration: TimeInterval = 2.0
    /// Default toast position.
    public var toastPosition = MMTToolForHUDToastPosition.bottom
    /// Distance between toasts and the safe-area edges.
    public var toastMargin: CGFloat = 20
    /// Vertical spacing between stacked toasts.
    public var toastSpacing: CGFloat = 10
    /// Toast background color.
    public var toastBackgroundColor = UIColor(red: 0.06, green: 0.06, blue: 0.06, alpha: 0.92)
    /// Toast corner radius.
    public var toastCornerRadius: CGFloat = 8
    /// Toast text color.
    public var toastTextColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    /// Toast text font.
    public var toastFont = UIFont.systemFont(ofSize: 14, weight: .medium)

    /// Touch interception policy.
    public enum InteractionStyle {
        /// Intercepts touches on the HUD panel only; everything else passes through.
        case blockHUD
        /// Intercepts touches on the entire screen (for strictly modal loading).
        case blockAll
        /// Fully pass-through; user interaction is never blocked.
        case passThrough
    }

    public init() {}
}

// MARK: - Supporting public types

/// Progress presentation style.
public enum MMTToolForHUDProgressStyle {
    /// Horizontal progress bar.
    case bar
    /// Circular progress ring.
    case ring
}

/// Toast presentation position.
public enum MMTToolForHUDToastPosition {
    /// Top (below the safe area).
    case top
    /// Vertically centered.
    case center
    /// Bottom (above the safe area).
    case bottom
}

/// Stable accessibility identifiers exposed to UI automation
/// (XCUITest / Appium). Query them with the "accessibility id" strategy.
/// Format: `MMTToolForHUD.<area>.<element>[.<detail>]`.
public enum MMTToolForHUDAccessibilityID {
    /// The HUD panel container.
    public static let panel = "MMTToolForHUD.hud.panel"
    /// The loading spinner inside the HUD panel.
    public static let spinner = "MMTToolForHUD.hud.spinner"
    /// The ring-style progress indicator.
    public static let progressRing = "MMTToolForHUD.hud.progress.ring"
    /// The bar-style progress indicator.
    public static let progressBar = "MMTToolForHUD.hud.progress.bar"
    /// The success / error status icon.
    public static let statusIcon = "MMTToolForHUD.hud.status.icon"
    /// The HUD text label.
    public static let text = "MMTToolForHUD.hud.text"
    /// A toast view (every toast shares this identifier).
    public static let toast = "MMTToolForHUD.toast.item"
}
