//
//  ReciterSurahPopupBarViewController.swift
//  new project
//
//  Custom LNPopupController bar for the "now playing surah" experience —
//  reciter portrait, English + Arabic surah titles on a single line, the
//  reciter name as subtitle, and play/pause + forward controls.
//  Mirrors `SleepPopupBarViewController` so both content types feel consistent.
//

import UIKit
import LNPopupController

final class ReciterSurahPopupBarViewController: LNPopupCustomBarViewController {

    var onPlayPause: (() -> Void)?
    var onForward: (() -> Void)?

    private let containerView: UIView = {
        let v = UIView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.layer.cornerRadius = 12
        v.clipsToBounds = true
        v.isOpaque = true
        return v
    }()

    private let rootStack: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.spacing = 10
        v.alignment = .center
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let portraitImageView: UIImageView = {
        let v = UIImageView()
        v.translatesAutoresizingMaskIntoConstraints = false
        v.contentMode = .scaleAspectFill
        v.clipsToBounds = true
        v.layer.cornerRadius = 18
        v.isOpaque = true
        v.backgroundColor = UIColor.tertiarySystemFill
        return v
    }()

    /// Vertical stack: titles row (top) + reciter name (bottom).
    private let textStack: UIStackView = {
        let v = UIStackView()
        v.axis = .vertical
        v.alignment = .fill
        v.spacing = 1
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    /// Horizontal row holding English (leading) and Arabic (trailing) titles.
    private let titlesRow: UIStackView = {
        let v = UIStackView()
        v.axis = .horizontal
        v.alignment = .firstBaseline
        v.distribution = .fill
        v.spacing = 8
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let englishTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 14, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        l.setContentCompressionResistancePriority(.defaultLow - 1, for: .horizontal)
        l.setContentHuggingPriority(.defaultLow, for: .horizontal)
        return l
    }()

    private let arabicTitleLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingHead
        l.textAlignment = .right
        l.semanticContentAttribute = .forceRightToLeft
        l.setContentCompressionResistancePriority(.required, for: .horizontal)
        l.setContentHuggingPriority(.required, for: .horizontal)
        return l
    }()

    private let reciterLabel: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 12, weight: .regular)
        l.textColor = .secondaryLabel
        l.numberOfLines = 1
        l.lineBreakMode = .byTruncatingTail
        return l
    }()

    private lazy var playPauseButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "pause.fill", withConfiguration: Self.controlSymbolConfig), for: .normal)
        b.addTarget(self, action: #selector(playPauseTapped), for: .touchUpInside)
        return b
    }()

    private lazy var forwardButton: UIButton = {
        let b = UIButton(type: .system)
        b.setImage(UIImage(systemName: "forward.fill", withConfiguration: Self.controlSymbolConfig), for: .normal)
        b.addTarget(self, action: #selector(forwardTapped), for: .touchUpInside)
        return b
    }()

    private static let controlSymbolConfig = UIImage.SymbolConfiguration(pointSize: 22, weight: .regular)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        updateButtonTint()

        let barHeight: CGFloat = 56
        let verticalInset: CGFloat = 6

        view.addSubview(containerView)
        containerView.addSubview(rootStack)

        titlesRow.addArrangedSubview(englishTitleLabel)
        titlesRow.addArrangedSubview(arabicTitleLabel)

        textStack.addArrangedSubview(titlesRow)
        textStack.addArrangedSubview(reciterLabel)

        rootStack.addArrangedSubview(portraitImageView)
        rootStack.addArrangedSubview(textStack)
        rootStack.addArrangedSubview(playPauseButton)
        rootStack.addArrangedSubview(forwardButton)

        NSLayoutConstraint.activate([
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            containerView.topAnchor.constraint(equalTo: view.topAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            rootStack.leadingAnchor.constraint(equalTo: containerView.leadingAnchor, constant: 10),
            rootStack.trailingAnchor.constraint(equalTo: containerView.trailingAnchor, constant: -10),
            rootStack.topAnchor.constraint(equalTo: containerView.topAnchor, constant: verticalInset),
            rootStack.bottomAnchor.constraint(equalTo: containerView.bottomAnchor, constant: -verticalInset),
            portraitImageView.widthAnchor.constraint(equalToConstant: 36),
            portraitImageView.heightAnchor.constraint(equalToConstant: 36),
            playPauseButton.widthAnchor.constraint(equalToConstant: 36),
            forwardButton.widthAnchor.constraint(equalToConstant: 36),
            view.heightAnchor.constraint(equalToConstant: barHeight)
        ])

        preferredContentSize = CGSize(width: 0, height: barHeight)
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateButtonTint()
        }
    }

    private func updateButtonTint() {
        let dark = traitCollection.userInterfaceStyle == .dark
        let color: UIColor = dark ? .white : UIColor(white: 0.15, alpha: 1)
        playPauseButton.tintColor = color
        forwardButton.tintColor = color
    }

    @objc private func playPauseTapped() { onPlayPause?() }
    @objc private func forwardTapped() { onForward?() }

    // MARK: - Public configuration

    func setPortraitImage(_ image: UIImage?) {
        portraitImageView.image = image
    }

    func setTitles(english: String?, arabic: String?, reciter: String?) {
        englishTitleLabel.text = english
        englishTitleLabel.isHidden = (english?.isEmpty ?? true)

        arabicTitleLabel.text = arabic
        arabicTitleLabel.isHidden = (arabic?.isEmpty ?? true)

        reciterLabel.text = reciter
        reciterLabel.isHidden = (reciter?.isEmpty ?? true)
    }

    func updatePlayState(isPlaying: Bool) {
        let symbol = isPlaying ? "pause.fill" : "play.fill"
        playPauseButton.setImage(UIImage(systemName: symbol, withConfiguration: Self.controlSymbolConfig), for: .normal)
    }
}
