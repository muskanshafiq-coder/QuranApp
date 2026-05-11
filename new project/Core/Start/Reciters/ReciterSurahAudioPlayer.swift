//
//  ReciterSurahAudioPlayer.swift
//

import Foundation
import Combine
import AVFoundation

final class ReciterSurahAudioPlayer: ObservableObject {
    @Published var currentTime: Double = 0
    @Published var duration: Double = 0
    @Published var isPlaying = false
    @Published var playbackRate: Float = 1
    /// When advancing to the next surah, pick a random playable surah instead of the list order.
    @Published var shuffleSurahsEnabled: Bool = false
    /// 0 = off, 1 = repeat current surah, 2 = repeat / advance through all surahs (wrap).
    @Published var surahRepeatMode: Int = 0

    private var player: AVPlayer?
    private var observedItem: AVPlayerItem?
    private var timeObserver: Any?
    private var statusObservation: NSKeyValueObservation?
    private var endObserver: NSObjectProtocol?
    /// Called on the main queue when the current `AVPlayerItem` plays to end.
    var onDidPlayToEnd: (() -> Void)?

    deinit {
        tearDown()
    }

    func load(url: URL) {
        tearDown()
        let item = AVPlayerItem(url: url)
        observedItem = item
        let p = AVPlayer(playerItem: item)
        player = p

        endObserver = NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: item,
            queue: .main
        ) { [weak self] _ in
            self?.isPlaying = false
            if let d = self?.duration, d > 0 {
                self?.currentTime = d
            }
            self?.onDidPlayToEnd?()
        }

        statusObservation = item.observe(\.status, options: [.new]) { [weak self] it, _ in
            guard it.status == .readyToPlay else { return }
            let secs = it.duration.seconds
            guard secs.isFinite, secs > 0 else { return }
            DispatchQueue.main.async {
                self?.duration = secs
            }
        }

        // Finer than 0.2s so reciter follow-scroll can interpolate smoothly with `scrollTo` anchors.
        let interval = CMTime(seconds: 1.0 / 30.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = p.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] t in
            guard let self else { return }
            self.currentTime = t.seconds
            self.isPlaying = p.rate > 0.01
        }

        configureSession()
        p.play()
        p.rate = playbackRate
        isPlaying = true
    }

    func togglePlayPause() {
        guard let p = player else { return }
        if p.rate > 0.01 {
            p.pause()
            isPlaying = false
        } else {
            p.play()
            p.rate = playbackRate
            isPlaying = true
        }
    }

    /// Seek to the start of the current item and resume playback (used for repeat-one / repeat-all on end).
    func restartFromBeginningAndPlay() {
        guard let p = player else { return }
        let t = CMTime(seconds: 0, preferredTimescale: 600)
        p.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] finished in
            guard finished, let self else { return }
            DispatchQueue.main.async {
                self.currentTime = 0
                p.play()
                p.rate = self.playbackRate
                self.isPlaying = true
            }
        }
    }

    func setPlaybackRate(_ rate: Float) {
        let clamped = max(0.5, min(2, rate))
        playbackRate = clamped
        guard let p = player, p.rate > 0.01 else { return }
        p.rate = clamped
    }

    /// Cycles common speeds for the UI label (0.75 → 1 → 1.25 → 1.5 → 2 → 0.75).
    func cyclePlaybackRate() {
        let steps: [Float] = [0.75, 1, 1.25, 1.5, 2]
        if let i = steps.firstIndex(where: { abs($0 - playbackRate) < 0.01 }),
           i + 1 < steps.count {
            setPlaybackRate(steps[i + 1])
        } else {
            setPlaybackRate(steps[0])
        }
    }

    func seek(to seconds: Double) {
        guard let p = player else { return }
        let t = CMTime(seconds: max(0, seconds), preferredTimescale: 600)
        p.seek(to: t, toleranceBefore: .zero, toleranceAfter: .zero) { [weak self] _ in
            self?.currentTime = CMTimeGetSeconds(t)
        }
    }

    func skip(seconds: Double) {
        let maxT = duration > 0 ? duration : currentTime + abs(seconds)
        let t = min(max(0, currentTime + seconds), maxT)
        seek(to: t)
    }

    func stop() {
        tearDown()
    }

    /// Uniform time split: 1…ayahCount. Approximate when the API has no per-ayah timestamps.
    func activeAyahNumber(ayahCount: Int) -> Int {
        guard ayahCount > 0 else { return 1 }
        let d = duration
        guard d > 0 else { return 1 }
        let t = min(max(0, currentTime), d - 1e-6)
        let zeroBased = Int(floor((t / d) * Double(ayahCount)))
        return min(ayahCount, max(1, zeroBased + 1))
    }

    /// Linear model over the whole surah: used to move the scroll anchor smoothly within each ayah’s time slice.
    /// `anchorY` is the SwiftUI `UnitPoint.y` for `scrollTo(_:anchor:)` (horizontal center).
    func smoothFollowScrollTarget(ayahCount: Int) -> (ayah: Int, anchorY: CGFloat)? {
        guard ayahCount > 0 else { return nil }
        let d = duration
        guard d > 0 else { return nil }
        let t = min(max(0, currentTime), d)
        let p = (t / d) * Double(ayahCount)
        let idx0 = min(ayahCount - 1, max(0, Int(floor(p))))
        let frac = CGFloat(p - Double(idx0))
        let ayah = idx0 + 1
        // As `frac` advances through this ayah’s segment, move the anchor downward so the list tracks continuously.
        let anchorY = 0.20 + frac * 0.58
        return (ayah, anchorY)
    }

    func seekToEstimatedStartOfAyah(ayahNumber: Int, ayahCount: Int) {
        guard ayahCount > 0, ayahNumber >= 1, ayahNumber <= ayahCount else { return }
        let d = duration
        guard d > 0 else { return }
        let i = ayahNumber - 1
        seek(to: (Double(i) / Double(ayahCount)) * d)
    }

    func seekToPreviousAyahSegment(activeAyah: Int, ayahCount: Int) {
        if activeAyah <= 1 {
            seek(to: 0)
        } else {
            seekToEstimatedStartOfAyah(ayahNumber: activeAyah - 1, ayahCount: ayahCount)
        }
    }

    func seekToNextAyahSegment(activeAyah: Int, ayahCount: Int) {
        if activeAyah >= ayahCount {
            let d = duration
            if d > 0 { seek(to: max(0, d - 0.25)) }
        } else {
            seekToEstimatedStartOfAyah(ayahNumber: activeAyah + 1, ayahCount: ayahCount)
        }
    }

    private func configureSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {}
    }

    private func tearDown() {
        if let t = timeObserver, let p = player {
            p.removeTimeObserver(t)
            timeObserver = nil
        }
        if let o = endObserver {
            NotificationCenter.default.removeObserver(o)
            endObserver = nil
        }
        statusObservation?.invalidate()
        statusObservation = nil
        onDidPlayToEnd = nil
        player?.pause()
        player = nil
        observedItem = nil
        currentTime = 0
        duration = 0
        isPlaying = false
    }
}
