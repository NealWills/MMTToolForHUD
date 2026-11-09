//
//  MMTToolForHUDContainerView.swift
//  MMTToolForHUD
//

import UIKit

/// Full-window HUD container responsible for centering the content panel
/// and implementing the touch interception policy.
final class MMTToolForHUDContainerView: UIView {

    var interactionStyle: MMTToolForHUDConfig.InteractionStyle = .blockHUD

    /// Presentation state owned by the presenter (per window).
    var isDismissing = false
    var autoDismissWork: DispatchWorkItem?
    var scheduledDismissWork: DispatchWorkItem?

    let contentView = MMTToolForHUDContentView()

    private let hudMargin: CGFloat

    init(config: MMTToolForHUDConfig) {
        hudMargin = config.hudMargin
        interactionStyle = config.interactionStyle
        super.init(frame: .zero)
        backgroundColor = .clear
        contentView.apply(config: config)
        contentView.translatesAutoresizingMaskIntoConstraints = true
        addSubview(contentView)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func apply(config: MMTToolForHUDConfig) {
        interactionStyle = config.interactionStyle
        contentView.apply(config: config)
        setNeedsLayout()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, bounds.height > 0 else { return }
        let maxWidth = min(bounds.width, bounds.height) - hudMargin * 2
        let size = contentView.preferredSize(maxWidth: maxWidth)
        // Assign bounds + center instead of frame: show/hide animations scale
        // contentView via transform, and assigning frame while a non-identity
        // transform is applied makes UIKit derive bounds = frame / scale,
        // which visually inflates the panel ("pop larger" glitch).
        contentView.bounds.size = size
        contentView.center = CGPoint(x: bounds.midX, y: bounds.midY)
        contentView.setNeedsLayout()
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard isUserInteractionEnabled else { return nil }
        switch interactionStyle {
        case .passThrough:
            return nil
        case .blockAll:
            return self
        case .blockHUD:
            let hitArea = contentView.frame.insetBy(dx: -12, dy: -12)
            return hitArea.contains(point) ? self : nil
        }
    }
}
