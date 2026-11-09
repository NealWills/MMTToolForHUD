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

        addSection("Toast")
        addButton("Toast · bottom") { MMTToolForHUDToast.show("This is a bottom toast") }
        addButton("Toast · top") { MMTToolForHUDToast.show("Top notice, great for notification-style messages", position: .top) }
        addButton("Toast · center") { MMTToolForHUDToast.show("Centered toast", position: .center) }
        addButton("Toast · success / error / info") {
            MMTToolForHUDToast.success("Saved successfully")
            MMTToolForHUDToast.error("Network error")
            MMTToolForHUDToast.info("Update available")
        }
        addButton("Toast · long text wrapping") {
            MMTToolForHUDToast.show("This is a fairly long toast message used to demonstrate automatic line wrapping and self-sizing layout without any extra configuration.", duration: 4)
        }
        addButton("Toast · dismiss all") { MMTToolForHUDToast.dismissAll() }

        addSection("Loading")
        addButton("Loading · spinner only") {
            MMTToolForHUD.showLoading()
            MMTToolForHUD.dismiss(after: 2)
        }
        addButton("Loading · with text") {
            MMTToolForHUD.showLoading("Loading, please wait…")
            MMTToolForHUD.dismiss(after: 2)
        }
        addButton("Loading · block whole screen") {
            MMTToolForHUD.updateConfig { $0.interactionStyle = .blockAll }
            MMTToolForHUD.showLoading("Modal loading…")
            MMTToolForHUD.dismiss(after: 2) {
                MMTToolForHUDToast.info("Interception restored to HUD area only")
                MMTToolForHUD.updateConfig { $0.interactionStyle = .blockHUD }
            }
        }

        addSection("Status")
        addButton("Success") { MMTToolForHUD.showSuccess("Submitted successfully") }
        addButton("Error") { MMTToolForHUD.showError("Network error, please try again later") }

        addSection("Progress")
        addButton("Bar progress · simulated download") { self.simulateProgress(style: .bar) }
        addButton("Ring progress · simulated download") { self.simulateProgress(style: .ring) }

        addSection("Custom configuration")
        addButton("Blue rounded HUD") {
            MMTToolForHUD.updateConfig {
                $0.hudBackgroundColor = UIColor.systemBlue.withAlphaComponent(0.92)
                $0.cornerRadius = 24
            }
            MMTToolForHUD.showLoading("Custom style")
            MMTToolForHUD.dismiss(after: 1.5) {
                MMTToolForHUD.updateConfig {
                    $0.hudBackgroundColor = UIColor(white: 0.11, alpha: 0.82)
                    $0.cornerRadius = 16
                }
            }
        }
    }

    private func addSection(_ title: String) {
        let label = UILabel()
        label.text = title
        label.font = .systemFont(ofSize: 13, weight: .semibold)
        label.textColor = .secondaryLabel
        label.textAlignment = .left
        stack.addArrangedSubview(label)
    }

    private func addButton(_ title: String, handler: @escaping () -> Void) {
        let button = DemoButton(title: title, handler: handler)
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

/// A button carrying its tap handler, avoiding one selector per use case.
private final class DemoButton: UIButton {

    private let handler: () -> Void

    init(title: String, handler: @escaping () -> Void) {
        self.handler = handler
        super.init(frame: .zero)

        setTitle(title, for: .normal)
        setTitleColor(.label, for: .normal)
        titleLabel?.font = .systemFont(ofSize: 15, weight: .medium)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12
        addTarget(self, action: #selector(tapped), for: .touchUpInside)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    @objc private func tapped() {
        handler()
    }
}
