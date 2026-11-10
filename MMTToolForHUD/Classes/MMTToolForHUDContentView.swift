//
//  MMTToolForHUDContentView.swift
//  MMTToolForHUD
//

import UIKit

/// HUD content view: a dark rounded panel rendering a spinner, a ring or bar
/// progress indicator, or a status icon, plus optional multi-line text,
/// depending on the current mode.
///
/// The public accessibility identifiers it exposes live in
/// `MMTToolForHUDAccessibilityID` (MMTToolForHUDAPI.swift).
final class MMTToolForHUDContentView: UIView {

    // MARK: - Mode

    enum Mode {
        case spinner
        case ring
        case bar
        case symbol(name: String, tint: UIColor, label: String)
    }

    private(set) var mode: Mode = .spinner
    private(set) var progress: Float = 0
    private var text: String?

    // MARK: - Layout constants

    private var padding: CGFloat = 16
    private var spacing: CGFloat = 6
    private var iconArea: CGFloat { 44 }
    private var barSize: CGSize {
        CGSize(width: config.barProgressWidth, height: config.barProgressHeight)
    }

    private var config = MMTToolForHUDConfig()
    /// Width high-water mark: while this panel is alive its width never
    /// shrinks on content updates, avoiding jitter when text changes
    /// (e.g. "Downloading 45%" -> "Done 100%"). A fresh panel starts over.
    private var stickyMaxWidth: CGFloat = 0

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
        spinner.isAccessibilityElement = true
        spinner.accessibilityLabel = "Loading"
        ringView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.progressRing
        ringView.isAccessibilityElement = true
        barView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.progressBar
        barView.isAccessibilityElement = true
        symbolView.accessibilityIdentifier = MMTToolForHUDAccessibilityID.statusIcon
        symbolView.isAccessibilityElement = true
        percentLabel.isAccessibilityElement = false
        textLabel.accessibilityIdentifier = MMTToolForHUDAccessibilityID.text

        // Apply the default configuration so fonts/colors are always set
        // before any sizing call (preferredSize reads textLabel.font).
        apply(config: config)
        apply(mode: .spinner, text: nil, progress: 0, animated: false)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Configuration

    func apply(config: MMTToolForHUDConfig) {
        self.config = config
        padding = config.hudPadding
        spacing = config.hudTextSpacing
        backgroundColor = config.hudBackgroundColor
        layer.cornerRadius = config.cornerRadius
        tintColor = config.tintColor
        spinner.color = config.spinnerColor
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
        self.progress = (mode == .ring || mode == .bar) ? Self.sanitized(progress) : 0

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
        case .symbol(let name, let tint, let label):
            let font = UIFont.systemFont(ofSize: 34, weight: .medium)
            let image = UIImage(systemName: name)?
                .withConfiguration(UIImage.SymbolConfiguration(font: font))
            symbolView.image = image
            symbolView.isHidden = false
            symbolView.tintColor = tint
            symbolView.accessibilityLabel = label
        }

        reloadText()
        setNeedsLayout()
        // Snap the active indicator to a sensible frame immediately: a mode
        // switch on a visible panel would otherwise animate the newly
        // active indicator from CGRect.zero (top-left corner) to its final
        // position inside the presenter's animated layout pass.
        if bounds.width > 0 {
            layoutContent()
        }
    }

    /// Updates the progress (must currently be in ring / bar mode).
    func setProgress(_ value: Float, animated: Bool) {
        progress = Self.sanitized(value)
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

    /// Clamps to 0...1 and replaces NaN / infinite values with 0 so a bad
    /// ratio (e.g. current/total with total == 0) can never crash the
    /// percent conversion.
    private static func sanitized(_ value: Float) -> Float {
        guard value.isFinite else { return 0 }
        return min(max(value, 0), 1)
    }

    // MARK: - Sizing

    /// Computes the panel's preferred size for the given maximum width.
    /// Text is measured with the same width the label will render at, so
    /// wrapped and explicit multi-line text size the panel correctly. The
    /// width never shrinks below the high-water mark recorded during this
    /// panel's lifetime.
    func preferredSize(maxWidth: CGFloat) -> CGSize {
        let available = max(maxWidth - padding * 2, 0)

        var indicatorWidth: CGFloat = 0
        var indicatorHeight: CGFloat = 0
        switch mode {
        case .spinner, .ring, .symbol:
            indicatorWidth = iconArea
            indicatorHeight = iconArea
        case .bar:
            indicatorWidth = barSize.width
            indicatorHeight = barSize.height
        }

        var textAttributed: NSAttributedString?
        if !textLabel.isHidden, let raw = textLabel.text {
            textAttributed = NSAttributedString(string: raw, attributes: [.font: textLabel.font!])
        }

        func measure(_ attributed: NSAttributedString, _ width: CGFloat) -> CGRect {
            attributed.boundingRect(
                with: CGSize(width: width, height: .greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                context: nil)
        }

        var textWidth: CGFloat = 0
        var textHeight: CGFloat = 0
        if let attributed = textAttributed {
            let natural = measure(attributed, available)
            textWidth = ceil(natural.width)
            textHeight = ceil(natural.height)
        }

        let naturalWidth = max(indicatorWidth, textWidth) + padding * 2
        if maxWidth.isFinite {
            stickyMaxWidth = max(stickyMaxWidth, min(naturalWidth, maxWidth))
        }
        let width = maxWidth.isFinite
            ? max(naturalWidth, min(stickyMaxWidth, maxWidth))
            : naturalWidth

        // When the sticky width makes the panel wider than the measurement
        // width, re-measure the text at the final inner width so wrapping
        // matches what the label renders.
        if let attributed = textAttributed {
            let inner = width - padding * 2
            if inner > available + 0.5 {
                textHeight = ceil(measure(attributed, inner).height)
            }
        }

        var height = padding + indicatorHeight
        if textAttributed != nil {
            height += spacing + max(textHeight, textLabel.font.lineHeight)
        }
        height += padding

        return CGSize(width: width, height: height)
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        layoutContent()
    }

    /// Positions the mode's indicator and text inside the current bounds.
    /// Called from layoutSubviews and directly on mode switches to seed
    /// frames without animation.
    private func layoutContent() {
        let contentWidth = bounds.width - padding * 2
        guard contentWidth > 0 else { return }
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
            // Give the label its real wrapping width so intrinsicContentSize
            // reports the height the text actually renders at (explicit
            // newlines and word wrapping both included).
            if textLabel.preferredMaxLayoutWidth != contentWidth {
                textLabel.preferredMaxLayoutWidth = contentWidth
            }
            let textSize = textLabel.intrinsicContentSize
            let height = max(ceil(textSize.height), textLabel.font.lineHeight)
            // The label always spans the full content width and centers its
            // text, so shorter text never shifts the frame — it stays put
            // instead of animating from an off-center position.
            textLabel.frame = CGRect(x: padding,
                                     y: y,
                                     width: max(contentWidth, 1),
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
    private var tint = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    private var lineWidth: CGFloat = 4

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear

        trackLayer.fillColor = nil
        trackLayer.strokeColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.28).cgColor
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
        trackView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 0.28)
        fillView.backgroundColor = UIColor(red: 1, green: 1, blue: 1, alpha: 1)
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
