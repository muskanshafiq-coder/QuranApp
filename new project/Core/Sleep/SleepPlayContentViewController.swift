//
//  SleepPlayContentViewController.swift
//  Quran App
//

import UIKit
import SwiftUI
import Combine
import LNPopupController

/// UIKit content controller for LNPopupController: hosts full SleepPlayView and provides popup bar item (title, subtitle, image, progress, pause, forward).
final class SleepPlayContentViewController: UIViewController {
    private let item: SleepAudioItem
    private let playback: SleepPlaybackManager
    private weak var viewModel: SleepViewModel?
    private var progressCancellable: AnyCancellable?
    private weak var customBar: SleepPopupBarViewController?
    private lazy var pauseBarButton = UIBarButtonItem(
        image: UIImage(systemName: "pause.fill"),
        style: .plain,
        target: self,
        action: #selector(togglePlayPause)
    )
    private lazy var forwardBarButton = UIBarButtonItem(
        image: UIImage(systemName: "forward.fill"),
        style: .plain,
        target: self,
        action: #selector(skipForward)
    )

    init(item: SleepAudioItem, playback: SleepPlaybackManager, viewModel: SleepViewModel) {
        self.item = item
        self.playback = playback
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        configurePopupItem()
        progressCancellable = playback.objectWillChange
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updatePopupProgress()
                self?.updatePauseButtonAppearance()
                self?.syncPopupSubtitleFromPlayback()
            }
    }

    @objc private func togglePlayPause() {
        playback.togglePlayPause()
    }

    @objc private func skipForward() {
        playback.skipForward()
    }

    private func updatePauseButtonAppearance() {
        pauseBarButton.image = UIImage(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
        customBar?.updatePauseState(isPlaying: playback.isPlaying)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        let playItem = item
        guard let vm = self.viewModel else { return }
        let playView = SleepPlayView(
            viewModel: vm,
            item: playItem,
            onDownload: { [weak self] in self?.viewModel?.downloadItem(playItem) },
            onRemoveDownload: { [weak self] in self?.viewModel?.removeDownload(for: playItem) },
            onAddToFavorite: { [weak self] in self?.viewModel?.addToFavorites(playItem) },
            onShare: { [weak self] in self?.viewModel?.shareItem(playItem) },
            sharedPlayback: playback,
            onMinimize: { [weak self] in self?.minimizePopup() },
            onForward: { [weak self] in
                guard let self, let vm = self.viewModel else { return }
                if !vm.playNext() { self.playback.skipForward() }
            }
        )
        let hosting = UIHostingController(rootView: playView)
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
        updatePopupProgress()
        updatePauseButtonAppearance()
        wireCustomBarIfNeeded()
        loadPopupImage()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        wireCustomBarIfNeeded()
        updateCustomBarImage()
    }

    private func wireCustomBarIfNeeded() {
        guard let bar = popupPresentationContainer?.popupBar.customBarViewController as? SleepPopupBarViewController else { return }
        customBar = bar
        bar.onPause = { [weak self] in self?.playback.togglePlayPause() }
        bar.onForward = { [weak self] in
            guard let self, let vm = self.viewModel else { return }
            if !vm.playNext() { self.playback.skipForward() }
        }
        bar.setTitle(item.title)
        bar.updatePauseState(isPlaying: playback.isPlaying)
        updateCustomBarImage()
    }

    private func updateCustomBarImage() {
        guard let bar = popupPresentationContainer?.popupBar.customBarViewController as? SleepPopupBarViewController else { return }
        if let name = item.localImageName, let img = UIImage(named: name) {
            bar.setStoryImage(img)
        } else if let url = item.imageURL, let cachedURL = StoryImageCache.shared.cachedFileURL(for: url), let img = UIImage(contentsOfFile: cachedURL.path) {
            bar.setStoryImage(img)
        } else if let img = popupItem.image {
            bar.setStoryImage(img)
        }
    }

    /// Call after presenting so mini bar shows this content VC's title and image (e.g. when switching via forward).
    func refreshBarContent() {
        wireCustomBarIfNeeded()
        updateCustomBarImage()
        loadPopupImage()
    }

    deinit {
        let vm = viewModel
        let itemId = item.id
        Task { @MainActor in
            if vm?.selectedPlayItem?.id == itemId {
                vm?.selectedPlayItem = nil
            }
        }
    }

    private func configurePopupItem() {
        popupItem.title = item.title
        popupItem.subtitle = item.subtitle
        popupItem.progress = 0
        popupItem.barButtonItems = [pauseBarButton, forwardBarButton]
    }

    private func updatePopupProgress() {
        popupItem.progress = Float(playback.progress)
    }

    /// `nowPlayingArtistLine` after `load()`; until then keep list `item.subtitle`.
    private func syncPopupSubtitleFromPlayback() {
        let fromPlayback = playback.nowPlayingArtistLine
        popupItem.subtitle = fromPlayback.isEmpty ? item.subtitle : fromPlayback
    }

    private func loadPopupImage() {
        if let name = item.localImageName, let image = UIImage(named: name) {
            applyPopupImage(image)
            return
        }
        if let url = item.imageURL,
           let cachedURL = StoryImageCache.shared.cachedFileURL(for: url),
           let image = UIImage(contentsOfFile: cachedURL.path) {
            applyPopupImage(image)
            return
        }
        guard let url = item.imageURL else { return }
        Task {
            do {
                let (data, _) = try await URLSession.shared.data(from: url)
                if let image = UIImage(data: data) {
                    await MainActor.run { self.applyPopupImage(image) }
                }
            } catch {}
        }
    }

    private func applyPopupImage(_ image: UIImage) {
        popupItem.image = image
        (popupPresentationContainer?.popupBar.customBarViewController as? SleepPopupBarViewController)?.setStoryImage(image)
    }

    private func minimizePopup() {
        popupPresentationContainer?.closePopup(animated: true)
    }
}
