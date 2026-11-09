//
//  MMTToolForHUDConfig.swift
//  MMTToolForHUD
//
//  Created by nealwills on 2026/11/09.
//

import UIKit

/// Appearance and behavior configuration for the HUD and toast.
///
/// Read and write the global configuration via `MMTToolForHUD.config` /
/// `MMTToolForHUDToast.config`. Changes only apply to HUDs and toasts
/// presented afterwards.
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
    public var hudBackgroundColor = UIColor(white: 0.11, alpha: 0.82)
    /// HUD tint color (spinner / progress / status icon).
    public var tintColor: UIColor = .white
    /// HUD text color.
    public var textColor: UIColor = .white
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
    public var progressTrackColor = UIColor(white: 1, alpha: 0.28)

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
    public var toastBackgroundColor = UIColor(white: 0.11, alpha: 0.88)
    /// Toast corner radius.
    public var toastCornerRadius: CGFloat = 8
    /// Toast text color.
    public var toastTextColor: UIColor = .white
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
