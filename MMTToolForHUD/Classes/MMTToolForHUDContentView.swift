//
//  MMTToolForHUDContentView.swift
//  MMTToolForHUD
//

import UIKit

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

/// HUD content view: a dark rounded panel rendering a spinner, a ring or bar
/// progress indicator, or a status icon, plus optional multi-line text,
/// depending on the current mode.
final class MMTToolForHUDContentView: UIView {

    // MARK: - Mode

    enum Mode {
        case spinner
        case ring
        case bar
        case symbol(name: String)
    }

    private(set) var mode: Mode = .spinner
    private(set) var progress: Float = 0
    private var text: String?

    // MARK: - Layout constants

    private let padding: CGFloat = 22
    private let spacing: CGFloat = 12
    private var iconArea: CGFloat { 54 }
    private var barSize: CGSize {
        CGSize(width: config.barProgressWidth, height: config.barProgressHeight)
    }

    private var config = MMTToolForHUDConfig()

    // MARK: - Subviews

    private let spinner = UIActivityIndicatorView(style: .large)
    private let ringView = MMTToolForHUDRingView()
    private let barView = MMTToolForHUDBarView()
    private let symbolView = UIImageView()
    private let percentLabel = UILabel()
    private let textLabel = UILabel()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = config.hudBackgroundColor
        layer.cornerRadius = config.cornerRadius
        layer.masksToBounds = true

        spinner.hidesWhenStopped = false
        spinner.translatesAutoresizingMaskIntoConstraints = true

        percentLabel.font = .monospacedDigitSystemFont(ofSize: 13, weight: .semibold)
        percentLabel.textAlignment = .center

        textLabel.textAlignment = .center
        textLabel.numberOfLines = 0

        symbolView.contentMode = .center
        symbolView.tintColor = config.tintColor

        [spinner, ringView, barView, symbolView, percentLabel, textLabel]
            .forEach { $0.translatesAutoresizingMaskIntoConstraints = true; addSubview($0) }

        // Accessibility identifiers for UI automation (XCUITest / Appium).
        accessibilityIdentifier = MMTToolForHUDAccessibilityID.panel
        spinner.accessibilityIdentifier = MMTToolForHUDAccessibilityID.spinner
        ringView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.progressRing
        ringView.isAccessibilityElement = true
        barView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.progressBar
        barView.isAccessibilityElement = true
        symbolView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.statusIcon
        symbolView.isAccessibilityElement = true
        percentLabel.isAccessibilityElement = false
        textLabel.accessibilityIdentifier = MMTToolForHUDAccessibilityID.text

        apply(mode: .spinner, text: nil, progress: 0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func apply(config: MMTToolForHUDConfig) {
        self.config = config
        backgroundColor = config.hudBackgroundColor
        layer.cornerRadius = config.cornerRadius
        tintColor = config.tintColor
        spinner.color = config.tintColor
        symbolView.tintColor = config.tintColor
        textLabel.textColor = config.textColor
        textLabel.font = config.textFont
        percentLabel.textColor = config.tintColor
        ringView.configure(tint: config.tintColor,
                           track: config.progressTrackColor,
                           lineWidth: config.ringProgressLineWidth)
        barView.configure(tint: config.tintColor, track: config.progressTrackColor)
        setNeedsLayout()
    }

    /// Switches the mode and updates the content. The progress value only
    /// applies in ring / bar modes.
    func apply(mode: Mode, text: String?, progress: Float, animated: Bool) {
        self.mode = mode
        self.text = text?.isEmpty == true ? nil : text
        if mode == .ring || mode == .bar {
            self.progress = min(max(progress, 0), 1)
        } else {
            self.progress = 0
        }

        spinner.isHidden = mode != .spinner
        ringView.isHidden = mode != .ring
        barView.isHidden = mode != .bar
        symbolView.isHidden = true
        percentLabel.isHidden = mode != .ring

        switch mode {
        case .spinner:
            spinner.startAnimating()
        case .ring:
            ringView.setProgress(self.progress, animated: animated)
            percentLabel.text = Self.percentText(self.progress)
            ringView.accessibilityLabel = Self.percentText(self.progress)
        case .bar:
            barView.setProgress(self.progress, animated: animated)
            barView.accessibilityLabel = Self.percentText(self.progress)
        case .symbol(let name):
            let font = UIFont.systemFont(ofSize: 34, weight: .medium)
            let image = UIImage(systemName: name)?
                .withConfiguration(UIImage.SymbolConfiguration(font: font))
            symbolView.image = image
            symbolView.isHidden = false
            symbolView.accessibilityLabel = name == "checkmark.circle.fill" ? "Success" : "Error"
        }

        reloadText()
        setNeedsLayout()
    }

    /// Updates the progress (must currently be in ring / bar mode).
    func setProgress(_ value: Float, animated: Bool) {
        progress = min(max(value, 0), 1)
        switch mode {
        case .ring:
            ringView.setProgress(progress, animated: animated)
            percentLabel.text = Self.percentText(progress)
            ringView.accessibilityLabel = Self.percentText(progress)
        case .bar:
            barView.setProgress(progress, animated: animated)
            barView.accessibilityLabel = Self.percentText(progress)
        default:
            break
        }
        reloadText()
        setNeedsLayout()
    }

    private func reloadText() {
        if mode == .bar {
            let pct = Self.percentText(progress)
            if let text {
                textLabel.text = "\(text)  \(pct)"
            } else {
                textLabel.text = pct
            }
        } else {
            textLabel.text = text
        }
        textLabel.isHidden = textLabel.text?.isEmpty != false
    }

    private static func percentText(_ progress: Float) -> String {
        "\(Int((progress * 100).rounded()))%"
    }

    // MARK: - Sizing

    /// Computes the panel's preferred size for the given maximum width.
    func preferredSize(maxWidth: CGFloat) -> CGSize {
        let available = max(maxWidth - padding * 2, 0)
        var contentWidth: CGFloat = 0
        var height = padding

        switch mode {
        case .spinner, .ring, .symbol:
            contentWidth = iconArea
            height += iconArea
        case .bar:
            contentWidth = barSize.width
            height += barSize.height
        }

        if !textLabel.isHidden, let raw = textLabel.text {
            let attributed = NSAttributedString(string: raw, attributes: [.font: textLabel.font!])
            let bounds = attributed.boundingRect(
                with: CGSize(width: available, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil)
            contentWidth = max(contentWidth, ceil(bounds.width))
            height += spacing + ceil(bounds.height)
        }

        return CGSize(width: contentWidth + padding * 2, height: height + padding)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        let contentWidth = bounds.width - padding * 2
        var y = padding

        func centeredInContent(_ size: CGSize) -> CGRect {
            CGRect(x: padding + (contentWidth - size.width) / 2, y: y, width: size.width, height: size.height)
        }

        switch mode {
        case .spinner:
            let size = CGSize(width: iconArea, height: iconArea)
            spinner.frame = centeredInContent(size)
            y += size.height
        case .ring:
            let side = config.ringProgressRadius * 2
            let size = CGSize(width: side, height: side)
            ringView.frame = CGRect(x: padding + (contentWidth - side) / 2,
                                    y: y + (iconArea - side) / 2,
                                    width: side, height: side)
            percentLabel.frame = ringView.frame
            y += iconArea
        case .bar:
            barView.frame = centeredInContent(barSize)
            y += barSize.height
        case .symbol:
            let size = CGSize(width: iconArea, height: iconArea)
            symbolView.frame = centeredInContent(size)
            y += size.height
        }

        if !textLabel.isHidden {
            y += spacing
            let textSize = textLabel.intrinsicContentSize
            let width = min(ceil(textSize.width), contentWidth)
            let height = max(ceil(textSize.height), textLabel.font.lineHeight)
            textLabel.frame = CGRect(x: padding + (contentWidth - width) / 2,
                                     y: y,
                                     width: max(width, 1),
                                     height: max(height, 1))
            y += height
        }
    }

    override var intrinsicContentSize: CGSize {
        preferredSize(maxWidth: .greatestFiniteMagnitude)
    }
}

// MARK: - Ring progress

extension MMTToolForHUDContentView.Mode: Equatable {}

/// Ring progress implemented with CAShapeLayers; the center is reserved for
/// the percentage text.
final class MMTToolForHUDRingView: UIView {

    private let trackLayer = CAShapeLayer()
    private let fillLayer = CAShapeLayer()
    private var tint: UIColor = .white
    private var lineWidth: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        trackLayer.fillColor = nil
        trackLayer.strokeColor = UIColor(white: 1, alpha: 0.28).cgColor
        fillLayer.fillColor = nil
        fillLayer.strokeColor = tint.cgColor
        fillLayer.transform = CATransform3DMakeRotation(-.pi / 2, 0, 0, 1)

        layer.addSublayer(trackLayer)
        layer.addSublayer(fillLayer)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(tint: UIColor, track: UIColor, lineWidth: CGFloat) {
        self.tint = tint
        self.lineWidth = lineWidth
        trackLayer.strokeColor = track.cgColor
        fillLayer.strokeColor = tint.cgColor
        setNeedsLayout()
    }

    func setProgress(_ progress: Float, animated: Bool) {
        let target = CGFloat(min(max(progress, 0), 1))
        if animated, fillLayer.path != nil {
            let animation = CABasicAnimation(keyPath: "strokeEnd")
            animation.fromValue = fillLayer.strokeEnd
            animation.toValue = target
            animation.duration = 0.2
            animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
            fillLayer.add(animation, forKey: "strokeEnd")
        }
        // Disable implicit actions so the model value applies immediately
        // (the visual change is driven by the CABasicAnimation above).
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        fillLayer.strokeEnd = target
        CATransaction.commit()
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let side = min(bounds.width, bounds.height)
        let rect = bounds.insetBy(dx: (bounds.width - side) / 2, dy: (bounds.height - side) / 2)
        let path = UIBezierPath(ovalIn: rect)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        trackLayer.frame = bounds
        trackLayer.lineWidth = lineWidth
        trackLayer.path = path.cgPath
        fillLayer.frame = bounds
        fillLayer.lineWidth = lineWidth
        fillLayer.path = path.cgPath
        CATransaction.commit()
    }
}

// MARK: - Bar progress

/// Rounded bar progress implemented with UIViews so UIKit animations apply.
final class MMTToolForHUDBarView: UIView {

    private let trackView = UIView()
    private let fillView = UIView()
    private(set) var progress: Float = 0

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        trackView.backgroundColor = UIColor(white: 1, alpha: 0.28)
        fillView.backgroundColor = .white
        [trackView, fillView].forEach { addSubview($0) }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(tint: UIColor, track: UIColor) {
        fillView.backgroundColor = tint
        trackView.backgroundColor = track
        setNeedsLayout()
    }

    func setProgress(_ value: Float, animated: Bool) {
        progress = min(max(value, 0), 1)
        let applyLayout = { self.setNeedsLayout(); self.layoutIfNeeded() }
        if animated {
            UIView.animate(withDuration: 0.2, delay: 0, options: [.curveEaseInOut]) {
                applyLayout()
            }
        } else {
            applyLayout()
        }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        trackView.frame = bounds
        trackView.layer.cornerRadius = bounds.height / 2
        fillView.frame = CGRect(x: 0, y: 0,
                                width: bounds.width * CGFloat(progress),
                                height: bounds.height)
        fillView.layer.cornerRadius = bounds.height / 2
        fillView.clipsToBounds = true
    }
}
