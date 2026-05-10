//
//  ReciterSurahPopupContentViewController.swift
//  new project
//
//  Owns a `ReciterSurahAudioPlayer` and hosts `ReciterSurahNowPlayingView`
//  as the LNPopupController content. Configures the popup item (title,
//  subtitle, image, progress, bar buttons) and wires the custom popup bar.
//
//  Mirrors `SleepPlayContentViewController` in shape and lifecycle.
//

import UIKit
import SwiftUI
import Combine
import LNPopupController

final class ReciterSurahPopupContentViewController: UIViewController {
    private let session: ReciterPlaybackSession
    private let selectedThemeColorManager: SelectedThemeColorManager
    private let player = ReciterSurahAudioPlayer()
    private var playerSubscription: AnyCancellable?
    private weak var customBar: ReciterSurahPopupBarViewController?

    private lazy var pauseBarButton = UIBarButtonItem(
        image: UIImage(systemName: "pause.fill"),
        style: .plain,
        target: self,
        action: #selector(togglePlayPauseTapped)
    )
    private lazy var forwardBarButton = UIBarButtonItem(
        image: UIImage(systemName: "forward.fill"),
        style: .plain,
        target: self,
        action: #selector(forwardTapped)
    )

    init(session: ReciterPlaybackSession, selectedThemeColorManager: SelectedThemeColorManager) {
        self.session = session
        self.selectedThemeColorManager = selectedThemeColorManager
        super.init(nibName: nil, bundle: nil)
        configurePopupItem()
        playerSubscription = player.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePopupProgress()
                self?.updatePauseButtonAppearance()
            }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let nowPlayingView = ReciterSurahNowPlayingView(
            detail: session.detail,
            surah: session.surah,
            player: player,
            onMinimize: { [weak self] in self?.minimizePopup() }
        )
        .environmentObject(selectedThemeColorManager)
        let hosting = UIHostingController(rootView: nowPlayingView)
        addChild(hosting)
        hosting.view.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(hosting.view)
        NSLayoutConstraint.activate([
            hosting.view.topAnchor.constraint(equalTo: view.topAnchor),
            hosting.view.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            hosting.view.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            hosting.view.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
        hosting.didMove(toParent: self)

        player.onDidPlayToEnd = { [weak self] in
            self?.handlePlaybackFinished()
        }
        if let url = session.surah.audio.flatMap({ URL(string: $0) }) {
            player.load(url: url)
        }

        wireCustomBarIfNeeded()
        loadPopupImage()
        updatePauseButtonAppearance()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wireCustomBarIfNeeded()
    }

    deinit {
        player.onDidPlayToEnd = nil
        player.stop()
    }

    // MARK: - Popup configuration

    private func configurePopupItem() {
        popupItem.title = surahDisplayLine
        popupItem.subtitle = reciterDisplayName
        popupItem.progress = 0
        popupItem.barButtonItems = [pauseBarButton, forwardBarButton]
    }

    private var surahDisplayLine: String {
        let en = session.surah.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return en.lowercased().hasPrefix("surah") ? en : "Surah \(en)"
    }

    private var arabicSurahLine: String {
        (session.surah.nameAr ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var reciterDisplayName: String {
        let en = session.detail.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return en
    }

    private func updatePopupProgress() {
        guard player.duration > 0 else {
            popupItem.progress = 0
            return
        }
        popupItem.progress = Float(min(1, max(0, player.currentTime / player.duration)))
    }

    private func updatePauseButtonAppearance() {
        let symbol = player.isPlaying ? "pause.fill" : "play.fill"
        pauseBarButton.image = UIImage(systemName: symbol)
        customBar?.updatePlayState(isPlaying: player.isPlaying)
    }

    // MARK: - Custom bar wiring

    private func wireCustomBarIfNeeded() {
        guard let bar = popupPresentationContainer?
                .popupBar
                .customBarViewController as? ReciterSurahPopupBarViewController else {
            return
        }
        customBar = bar
        bar.onPlayPause = { [weak self] in self?.player.togglePlayPause() }
        bar.onForward = { [weak self] in self?.handleForwardFromMiniBar() }
        bar.setTitles(
            english: surahDisplayLine,
            arabic: arabicSurahLine,
            reciter: reciterDisplayName
        )
        bar.updatePlayState(isPlaying: player.isPlaying)
        applyCachedPortraitToCustomBarIfPossible()
    }

    private func handleForwardFromMiniBar() {
        // From the mini bar we only support "play next from queue" when
        // something is queued; otherwise fall back to a 15s skip.
        if let next = ReciterPlaybackQueueCoordinator.shared.dequeueNext() {
            ReciterPlaybackPopupCoordinator.shared.present(session: next, openFullScreen: false)
        } else {
            player.skip(seconds: 15)
        }
    }

    @objc private func togglePlayPauseTapped() {
        player.togglePlayPause()
    }

    @objc private func forwardTapped() {
        handleForwardFromMiniBar()
    }

    private func handlePlaybackFinished() {
        if let next = ReciterPlaybackQueueCoordinator.shared.dequeueNext() {
            ReciterPlaybackPopupCoordinator.shared.present(session: next, openFullScreen: false)
        }
    }

    private func minimizePopup() {
        popupPresentationContainer?.closePopup(animated: true)
    }

    // MARK: - Popup artwork

    private func loadPopupImage() {
        let portraitURL = session.detail.image
            .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? nil : $0 }
            .flatMap { URL(string: $0) }

        guard let url = portraitURL else { return }
        Task { [weak self] in
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                guard let image = UIImage(data: data) else { return }
                await MainActor.run { self?.applyPopupImage(image) }
            } catch {}
        }
    }

    private func applyPopupImage(_ image: UIImage) {
        popupItem.image = image
        customBar?.setPortraitImage(image)
    }

    private func applyCachedPortraitToCustomBarIfPossible() {
        if let image = popupItem.image {
            customBar?.setPortraitImage(image)
        }
    }
}
