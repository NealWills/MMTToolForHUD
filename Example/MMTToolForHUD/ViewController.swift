//
//  ViewController.swift
//  MMTToolForHUD
//
//  Created by nealwills on 11/09/2026.
//  Copyright (c) 2026 nealwills. All rights reserved.
//

import UIKit
import MMTToolForHUD

class ViewController: UIViewController {

    private var progressTimer: Timer?

    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemGroupedBackground
        setupUI()
    }

    deinit {
        progressTimer?.invalidate()
    }

    // MARK: - UI

    private func setupUI() {
        scrollView.alwaysBounceVertical = true
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(scrollView)

        stack.axis = .vertical
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(stack)

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scrollView.topAnchor.constraint(equalTo: view.topAnchor),
            scrollView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            scrollView.contentLayoutGuide.widthAnchor.constraint(equalTo: view.widthAnchor),

            stack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor, constant: 20),
            stack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor, constant: -20),
            stack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor, constant: 20),
            stack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor, constant: -20),
        ])

        addSection("Toast", id: "demo.section.toast")
        addButton("Toast · bottom", id: "demo.toast.bottom") { MMTToolForHUDToast.show("This is a bottom toast") }
        addButton("Toast · top", id: "demo.toast.top") { MMTToolForHUDToast.show("Top notice, great for notification-style messages", position: .top) }
        addButton("Toast · center", id: "demo.toast.center") { MMTToolForHUDToast.show("Centered toast", position: .center) }
        addButton("Toast · success / error / info", id: "demo.toast.icons") {
            MMTToolForHUDToast.success("Saved successfully")
            MMTToolForHUDToast.error("Network error")
            MMTToolForHUDToast.info("Update available")
        }
        addButton("Toast · long text wrapping", id: "demo.toast.long-text") {
            MMTToolForHUDToast.show("This is a fairly long toast message used to demonstrate automatic line wrapping and self-sizing layout without any extra configuration.", duration: 4)
        }
        addButton("Toast · dismiss all", id: "demo.toast.dismiss-all") { MMTToolForHUDToast.dismissAll() }

        addSection("Loading", id: "demo.section.loading")
        addButton("Loading · spinner only", id: "demo.loading.spinner") {
            MMTToolForHUD.showLoading()
            MMTToolForHUD.dismiss(after: 2)
        }
        addButton("Loading · with text", id: "demo.loading.text") {
            MMTToolForHUD.showLoading("Loading, please wait…")
            MMTToolForHUD.dismiss(after: 2)
        }
        addButton("Loading · block whole screen", id: "demo.loading.block-all") {
            MMTToolForHUD.updateConfig { $0.interactionStyle = .blockAll }
            MMTToolForHUD.showLoading("Modal loading…")
            MMTToolForHUD.dismiss(after: 2) {
                MMTToolForHUDToast.info("Interception restored to HUD area only")
                MMTToolForHUD.updateConfig { $0.interactionStyle = .blockHUD }
            }
        }

        addSection("Status", id: "demo.section.status")
        addButton("Success", id: "demo.status.success") { MMTToolForHUD.showSuccess("Submitted successfully") }
        addButton("Error", id: "demo.status.error") { MMTToolForHUD.showError("Network error, please try again later") }

        addSection("Progress", id: "demo.section.progress")
        addButton("Bar progress · simulated download", id: "demo.progress.bar") { self.simulateProgress(style: .bar) }
        addButton("Ring progress · simulated download", id: "demo.progress.ring") { self.simulateProgress(style: .ring) }

        addSection("Custom configuration", id: "demo.section.config")
        addButton("Colored spinner & status icons", id: "demo.config.colors") {
            MMTToolForHUD.updateConfig {
                $0.spinnerColor = .systemOrange
                $0.successIconColor = .systemGreen
                $0.errorIconColor = .systemRed
            }
            MMTToolForHUD.showLoading("Custom colors")
            MMTToolForHUD.dismiss(after: 1.2) {
                MMTToolForHUD.showSuccess("Success is green")
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) {
                    MMTToolForHUD.showError("Error is red")
                }
            }
        }
    }

    /// Prefixes the passed identifier with the automation namespace, e.g.
    /// "demo.toast.bottom" becomes "MMTToolForHUD.demo.toast.bottom".
    private static let idPrefix = "MMTToolForHUD."

    private func addSection(_ title: String, id: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        label.accessibilityIdentifier = Self.idPrefix + id
        stack.addArrangedSubview(label)
    }

    private func addButton(_ title: String, id: String, handler: @escaping () -> Void) {
        let button = DemoButton(title: title, identifier: id, handler: handler)
        stack.addArrangedSubview(button)
        button.heightAnchor.constraint(equalToConstant: 46).isActive = true
    }

    // MARK: - Progress simulation

    private func simulateProgress(style: MMTToolForHUDProgressStyle) {
        progressTimer?.invalidate()
        MMTToolForHUD.showProgress(0, text: "Downloading", style: style)
        var progress: Float = 0
        progressTimer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { timer in
            progress += 0.015 + Float.random(in: 0...0.02)
            if progress >= 1 {
                timer.invalidate()
                MMTToolForHUD.updateProgress(1, text: "Done")
                MMTToolForHUD.dismiss(after: 0.6) {
                    MMTToolForHUDToast.success("Download complete")
                }
            } else {
                MMTToolForHUD.updateProgress(progress)
            }
        }
    }
}

// MARK: - Demo button

/// A button carrying its tap handler and a stable accessibility identifier
/// for UI automation (XCUITest / Appium).
private final class DemoButton: UIButton {

    private let handler: () -> Void

    init(title: String, identifier: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        accessibilityIdentifier = "MMTToolForHUD." + identifier
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        handler()
    }
}
