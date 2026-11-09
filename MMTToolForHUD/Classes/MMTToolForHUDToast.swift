//
//  MMTToolForHUDToast.swift
//  MMTToolForHUD
//

import UIKit

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
                                                  icon: ("checkmark.circle.fill", .systemGreen),
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
                                                  icon: ("xmark.circle.fill", .systemRed),
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
                                                  icon: ("info.circle.fill", .systemBlue),
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
        MMTToolForHUDToastManager.shared.hasVisibleToast(in: nil)
    }

    /// Whether a toast is visible on the given window.
    public static func isVisible(in window: UIWindow?) -> Bool {
        MMTToolForHUDToastManager.shared.hasVisibleToast(in: window)
    }

    /// Alias of the global configuration; identical to `MMTToolForHUD.config`.
    public static var config: MMTToolForHUDConfig {
        get { MMTToolForHUD.config }
        set { MMTToolForHUD.config = newValue }
    }
}

// MARK: - Toast manager

/// Creates the per-position toast containers and handles stacking and
/// automatic removal.
final class MMTToolForHUDToastManager {

    static let shared = MMTToolForHUDToastManager()

    /// One container per (window, position); detached containers are purged
    /// on access. Only the container attached to the target window is ever
    /// touched.
    private var containers: [MMTToolForHUDToastContainerView] = []
    private var autoRemoveWorkItems: [ObjectIdentifier: DispatchWorkItem] = [:]

    private func purgeDetachedContainers() {
        containers.removeAll { $0.window == nil }
    }

    func hasVisibleToast(in window: UIWindow?) -> Bool {
        purgeDetachedContainers()
        let candidates: [MMTToolForHUDToastContainerView]
        if let window {
            candidates = containers.filter { $0.window === window }
        } else {
            candidates = containers
        }
        return candidates.contains { $0.stack.arrangedSubviews.isEmpty == false }
    }

    var config: MMTToolForHUDConfig { MMTToolForHUD.presenter.config }

    // MARK: Presenting

    func show(text: String,
              icon: (name: String, color: UIColor)?,
              duration: TimeInterval?,
              position: MMTToolForHUDToastPosition?,
              window: UIWindow?) {
        let config = self.config
        let position = position ?? config.toastPosition
        let duration = duration ?? config.toastDuration
        guard let targetWindow = window ?? MMTToolForHUDWindowFinder.frontWindow() else { return }

        let container = ensureContainer(position: position, in: targetWindow, config: config)

        let maxWidth = targetWindow.bounds.width - config.toastMargin * 2
        let item = MMTToolForHUDToastItemView(text: text, icon: icon, config: config, maxWidth: maxWidth)
        container.stack.addArrangedSubview(item)

        let offset: CGFloat = position == .bottom ? 14 : -14
        item.transform = CGAffineTransform(translationX: 0, y: offset)
        item.alpha = 0
        container.layoutIfNeeded()

        if config.isAnimationEnabled {
            UIView.animate(
                withDuration: config.animationDuration,
                delay: 0,
                usingSpringWithDamping: 0.8,
                initialSpringVelocity: 0.4,
                options: [.allowUserInteraction]) {
                item.alpha = 1
                item.transform = .identity
            }
        } else {
            item.alpha = 1
            item.transform = .identity
        }

        let work = DispatchWorkItem { [weak self, weak item] in
            guard let self, let item else { return }
            self.removeItem(item, animated: self.config.isAnimationEnabled)
        }
        autoRemoveWorkItems[ObjectIdentifier(item)] = work
        DispatchQueue.main.asyncAfter(deadline: .now() + duration, execute: work)
    }

    // MARK: Removing

    func removeItem(_ item: MMTToolForHUDToastItemView, animated: Bool) {
        guard item.superview != nil else { return }

        let workKey = ObjectIdentifier(item)
        if let work = autoRemoveWorkItems[workKey] {
            work.cancel()
            autoRemoveWorkItems[workKey] = nil
        }

        guard let stack = item.superview as? UIStackView,
              let container = stack.superview as? MMTToolForHUDToastContainerView else { return }

        let finish = { [weak self, weak container] in
            stack.removeArrangedSubview(item)
            item.removeFromSuperview()
            guard let self, let container, container.stack.arrangedSubviews.isEmpty else { return }
            container.removeFromSuperview()
            self.containers.removeAll { $0 === container }
        }

        if animated {
            // Exit along the same axis the toast entered from:
            // bottom toasts drop back down, top/center toasts slide back up.
            let offset: CGFloat = container.position == .bottom ? 10 : -10
            UIView.animate(
                withDuration: config.animationDuration,
                delay: 0,
                options: [.curveEaseIn, .allowUserInteraction]) {
                item.alpha = 0
                item.transform = CGAffineTransform(translationX: 0, y: offset)
            } completion: { _ in
                finish()
            }
        } else {
            finish()
        }
    }

    func dismissAll(in window: UIWindow?) {
        purgeDetachedContainers()
        let targets: [MMTToolForHUDToastContainerView]
        if let window {
            targets = containers.filter { $0.window === window }
        } else {
            targets = containers
        }
        let items = targets
            .flatMap { $0.stack.arrangedSubviews }
            .compactMap { $0 as? MMTToolForHUDToastItemView }
        for item in items {
            removeItem(item, animated: config.isAnimationEnabled)
        }
    }

    // MARK: Containers

    private func ensureContainer(position: MMTToolForHUDToastPosition,
                                 in window: UIWindow,
                                 config: MMTToolForHUDConfig) -> MMTToolForHUDToastContainerView {
        purgeDetachedContainers()
        if let existing = containers.first(where: { $0.window === window && $0.position == position }) {
            return existing
        }

        let container = MMTToolForHUDToastContainerView(position: position,
                                                        margin: config.toastMargin,
                                                        spacing: config.toastSpacing)
        window.addSubview(container)
        container.pin(to: window)
        containers.append(container)
        return container
    }
}

// MARK: - Container view

/// Full-screen transparent container stacking toasts vertically in a
/// UIStackView; fully pass-through to touches.
final class MMTToolForHUDToastContainerView: UIView {

    let stack = UIStackView()
    let position: MMTToolForHUDToastPosition
    private let margin: CGFloat

    init(position: MMTToolForHUDToastPosition, margin: CGFloat, spacing: CGFloat) {
        self.position = position
        self.margin = margin
        super.init(frame: .zero)

        backgroundColor = .clear
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = spacing
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func pin(to window: UIWindow) {
        guard superview === window else { return }
        translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            leadingAnchor.constraint(equalTo: window.leadingAnchor),
            trailingAnchor.constraint(equalTo: window.trailingAnchor),
            topAnchor.constraint(equalTo: window.topAnchor),
            bottomAnchor.constraint(equalTo: window.bottomAnchor),

            stack.centerXAnchor.constraint(equalTo: centerXAnchor),
            stack.widthAnchor.constraint(lessThanOrEqualTo: widthAnchor,
                                         constant: -margin * 2),
        ])

        switch position {
        case .top:
            NSLayoutConstraint.activate([
                stack.topAnchor.constraint(equalTo: window.safeAreaLayoutGuide.topAnchor,
                                           constant: margin),
            ])
        case .center:
            NSLayoutConstraint.activate([
                stack.centerYAnchor.constraint(equalTo: window.centerYAnchor),
            ])
        case .bottom:
            NSLayoutConstraint.activate([
                stack.bottomAnchor.constraint(equalTo: window.safeAreaLayoutGuide.bottomAnchor,
                                              constant: -margin),
            ])
        }
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        nil
    }
}

// MARK: - Toast item

/// Capsule-shaped toast view: optional icon + multi-line text.
final class MMTToolForHUDToastItemView: UIView {

    private static let iconSize: CGFloat = 18
    private static let iconSpacing: CGFloat = 7
    private static let horizontalPadding: CGFloat = 18
    private static let verticalPadding: CGFloat = 11

    private let label: UILabel
    private let cornerRadius: CGFloat

    init(text: String, icon: (name: String, color: UIColor)?, config: MMTToolForHUDConfig, maxWidth: CGFloat) {
        let label = UILabel()
        label.text = text
        label.textColor = config.toastTextColor
        label.font = config.toastFont
        label.numberOfLines = 0
        label.preferredMaxLayoutWidth = max(maxWidth
            - Self.horizontalPadding * 2
            - (icon == nil ? 0 : Self.iconSize + Self.iconSpacing), 40)
        self.label = label
        self.cornerRadius = config.toastCornerRadius

        super.init(frame: .zero)

        backgroundColor = config.toastBackgroundColor
        layer.cornerCurve = .continuous

        // Accessibility identity for UI automation (XCUITest / Appium).
        isAccessibilityElement = true
        accessibilityIdentifier = MMTToolForHUDAccessibilityID.toast
        accessibilityLabel = text

        let content = UIStackView()
        content.axis = .horizontal
        content.alignment = .center
        content.spacing = Self.iconSpacing
        content.translatesAutoresizingMaskIntoConstraints = false

        if let icon {
            let iconView = UIImageView(image: UIImage(systemName: icon.name))
            iconView.tintColor = icon.color
            iconView.contentMode = .scaleAspectFit
            iconView.translatesAutoresizingMaskIntoConstraints = false
            content.addArrangedSubview(iconView)
            NSLayoutConstraint.activate([
                iconView.widthAnchor.constraint(equalToConstant: Self.iconSize),
                iconView.heightAnchor.constraint(equalToConstant: Self.iconSize),
            ])
        }
        content.addArrangedSubview(label)

        addSubview(content)
        NSLayoutConstraint.activate([
            content.leadingAnchor.constraint(equalTo: leadingAnchor,
                                             constant: Self.horizontalPadding),
            content.trailingAnchor.constraint(equalTo: trailingAnchor,
                                              constant: -Self.horizontalPadding),
            content.topAnchor.constraint(equalTo: topAnchor,
                                         constant: Self.verticalPadding),
            content.bottomAnchor.constraint(equalTo: bottomAnchor,
                                            constant: -Self.verticalPadding),
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        layer.cornerRadius = cornerRadius
    }
}
