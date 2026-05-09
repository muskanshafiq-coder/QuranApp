//
//  SleepPopupBarViewController.swift
//  Quran App
//

import UIKit
import LNPopupController

/// Custom popup bar for Sleep: story image, title, pause, forward (no moon).
final class SleepPopupBarViewController: LNPopupCustomBarViewController {

    var onPause: (() -> Void)?
    var onForward: (() -> Void)?

    private let playerBarView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.isOpaque = true
        return v
    }()

    private let playerStackView: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 10
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// Story/album art for the currently playing story (image of the story).
    private let storyImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 6
        v.isOpaque = true
        return v
    }()

    /// Title of the story, shown next to the image.
    private let titleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 15, weight: .medium)
        l.textColor = .label
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return l
    }()

    private lazy var pauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "pause.fill"), for: .normal)
        b.addTarget(self, action: #selector(pauseTapped), for: .touchUpInside)
        return b
    }()

    private lazy var forwardButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "forward.fill"), for: .normal)
        b.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        return b
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        updateButtonTint()

        let barHeight: CGFloat = 50
        let verticalInset: CGFloat = 4

        view.addSubview(playerBarView)
        playerBarView.addSubview(playerStackView)
        playerStackView.addArrangedSubview(storyImageView)
        playerStackView.addArrangedSubview(titleLabel)
        playerStackView.addArrangedSubview(UIView())
        playerStackView.addArrangedSubview(pauseButton)
        playerStackView.addArrangedSubview(forwardButton)

        NSLayoutConstraint.activate([
            playerBarView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            playerBarView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            playerBarView.topAnchor.constraint(equalTo: view.topAnchor),
            playerBarView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            playerStackView.leadingAnchor.constraint(equalTo: playerBarView.leadingAnchor, constant: 10),
            playerStackView.trailingAnchor.constraint(equalTo: playerBarView.trailingAnchor, constant: -10),
            playerStackView.topAnchor.constraint(equalTo: playerBarView.topAnchor, constant: verticalInset),
            playerStackView.bottomAnchor.constraint(equalTo: playerBarView.bottomAnchor, constant: -verticalInset),
            storyImageView.widthAnchor.constraint(equalToConstant: 26),
            storyImageView.heightAnchor.constraint(equalToConstant: 26),
            pauseButton.widthAnchor.constraint(equalToConstant: 32),
            forwardButton.widthAnchor.constraint(equalToConstant: 32),
            view.heightAnchor.constraint(equalToConstant: barHeight)
        ])

        preferredContentSize = CGSize(width: 0, height: barHeight)
    }

    override func popupItemDidUpdate() {
        super.popupItemDidUpdate()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateButtonTint()
        }
    }

    private func updateButtonTint() {
        let white = UIColor.white
        let dark = UIColor(white: 0.2, alpha: 1)
        pauseButton.tintColor = traitCollection.userInterfaceStyle == .dark ? white : dark
        forwardButton.tintColor = traitCollection.userInterfaceStyle == .dark ? white : dark
    }

    @objc private func pauseTapped() {
        onPause?()
    }

    @objc private func forwardTapped() {
        onForward?()
    }

    func setStoryImage(_ image: UIImage?) {
        storyImageView.image = image
    }

    func setTitle(_ title: String?) {
        titleLabel.text = title
    }

    func updatePauseState(isPlaying: Bool) {
        pauseButton.setImage(UIImage(systemName: isPlaying ? "pause.fill" : "play.fill"), for: .normal)
    }
}
