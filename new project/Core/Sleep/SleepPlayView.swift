//
//  SleepPlayView.swift
//

import SwiftUI
import AVFoundation
import AVKit
import Combine
import UIKit
import MediaPlayer

/// Full-screen audio play view: artwork, title, progress, play/pause, skip, volume.
struct SleepPlayView: View {
    @ObservedObject var viewModel: SleepViewModel
    let item: SleepAudioItem
    let onDownload: () -> Void
    let onRemoveDownload: (() -> Void)?
    let onAddToFavorite: () -> Void
    let onShare: () -> Void
    /// When provided, use this manager (e.g. shared for popup) and do not pause on disappear; chevron triggers onMinimize.
    var sharedPlayback: SleepPlaybackManager?
    /// Called when user taps chevron in popup mode to minimize to bar; nil when used in sheet.
    var onMinimize: (() -> Void)?
    /// When provided, called on forward tap (e.g. try next story); otherwise playback.skipForward().
    var onForward: (() -> Void)?
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme
    @StateObject private var privatePlayback = SleepPlaybackManager()
    private var resolvedPlayback: SleepPlaybackManager { sharedPlayback ?? privatePlayback }

    var body: some View {
        SleepPlayViewContent(
            viewModel: viewModel,
            item: item,
            playback: resolvedPlayback,
            onDownload: onDownload,
            onRemoveDownload: onRemoveDownload,
            onAddToFavorite: onAddToFavorite,
            onShare: onShare,
            onMinimize: onMinimize,
            onForward: onForward,
            dismiss: dismiss,
            sharedPlayback: sharedPlayback,
            colorScheme: colorScheme
        )
        .onDisappear {
            if sharedPlayback == nil { resolvedPlayback.pause() }
        }
    }
}

/// Inner content that observes playback so shared manager updates propagate.
private struct SleepPlayViewContent: View {
    @ObservedObject var viewModel: SleepViewModel
    let item: SleepAudioItem
    @ObservedObject var playback: SleepPlaybackManager
    let onDownload: () -> Void
    let onRemoveDownload: (() -> Void)?
    let onAddToFavorite: () -> Void
    let onShare: () -> Void
    var onMinimize: (() -> Void)?
    var onForward: (() -> Void)?
    let dismiss: DismissAction
    let sharedPlayback: SleepPlaybackManager?
    let colorScheme: ColorScheme

    @State private var storyDetail: StoryDetailDTO?
    /// Cached translation options (Core Data) so globe menu appears instantly.
    @State private var cachedTranslations: [StoryTranslationDTO] = []
    @State private var selectedLanguageCode: String = ""
    @GestureState private var dragY: CGFloat = 0

    private var currentTranslation: StoryTranslationDTO? {
        let list = (storyDetail?.translations ?? cachedTranslations)
        return list.first { $0.language == selectedLanguageCode }
    }

    private var displayTitle: String {
        currentTranslation?.title ?? item.title
    }

    /// Prefer `author` from `GET /stories/item/{id}`; fall back to list item (`StoryDTO.author` → `item.subtitle`).
    private var displaySubtitle: String {
        if let a = storyDetail?.author?.trimmingCharacters(in: .whitespacesAndNewlines), !a.isEmpty {
            return a
        }
        return item.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var minimizeAction: () -> Void {
        if let onMinimize { return onMinimize }
        return { dismiss() }
    }

    var body: some View {
        let clampedDrag: CGFloat = max(0, dragY)
        let dragProgress: CGFloat = min(1, clampedDrag / 320) // 0 → 1 as user drags down
        let dragProgressD = Double(dragProgress)

        ZStack {
            VStack(spacing: 24) {
                // Artwork
                artworkView
                    .frame(width: 280, height: 280)
                    .padding(.top, 22)
                    .scaleEffect(1 - (0.06 * dragProgress))
                    .opacity(1 - (0.10 * dragProgressD))
                    .padding(.top, 40)

                // Title + author (API `story.author`)
                VStack(alignment: .leading, spacing: 6) {
                    HStack(alignment: .center) {
                        Text(displayTitle)
                            .font(.system(size: 18, weight: .bold, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                            .lineLimit(1)
                        Spacer()
                        Menu {
                            let isFavorite = viewModel.isFavorite(item)
                            let downloadState = viewModel.downloadState(for: item)
                            if downloadState == .downloaded {
                                Button { onRemoveDownload?() } label: {
                                    Label("sleep_option_remove_from_downloads", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            } else if downloadState == .downloading {
                                Button { } label: {
                                    Label("sleep_option_downloading", systemImage: "arrow.down.circle")
                                }
                                .disabled(true)
                            } else {
                                Button { onDownload() } label: {
                                    Label("sleep_option_download", systemImage: "arrow.down.circle")
                                }
                            }
                            Button { onAddToFavorite() } label: {
                                Label(
                                    isFavorite ? "sleep_option_remove_from_favorites" : "sleep_option_add_to_favorite",
                                    systemImage: isFavorite ? "bookmark.slash" : "bookmark"
                                )
                            }
                            Button { onShare() } label: {
                                Label("sleep_option_share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                                .font(.system(size: 20))
                                .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                        }
                    }
                    if !displaySubtitle.isEmpty {
                        Text(displaySubtitle)
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.65) : .black.opacity(0.55))
                            .lineLimit(1)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.top, 20)
                .padding(.horizontal, 32)
                .opacity(1 - (0.25 * dragProgressD))

                // Progress
                VStack(spacing: 8) {
                    SmallThumbSlider(
                        value: Binding(
                            get: { playback.progress },
                            set: { playback.seek(to: $0) }
                        ),
                        range: 0...1,
                        tint: (colorScheme == .dark ? .white : .black)
                    )
                    .frame(height: 25)
                    HStack {
                        Text(playback.currentTimeFormatted)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                        Spacer()
                        Text(playback.durationFormatted)
                            .font(.system(size: 12, weight: .medium, design: .monospaced))
                            .foregroundColor(colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                    }
                }
                .padding(.horizontal, 32)
                .opacity(1 - (0.35 * dragProgressD))

                // Playback controls
                HStack(spacing: 40) {
                    Button { playback.skipBackward() } label: {
                        Image(systemName: "backward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    Button { playback.togglePlayPause() } label: {
                        Image(systemName: playback.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 44))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    Button {
                        if let onForward = onForward { onForward() } else { playback.skipForward() }
                    } label: {
                        Image(systemName: "forward.fill")
                            .font(.system(size: 28))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                }
                .padding(.top, 8)
                .opacity(1 - (0.10 * dragProgressD))

                // Volume
                HStack(spacing: 12) {
                    Image(systemName: "speaker.fill")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                    SmallThumbSlider(
                        value: Binding(
                            get: { Double(playback.volume) },
                            set: { playback.volume = Float($0) }
                        ),
                        range: 0...1,
                        tint: (colorScheme == .dark ? .white : .black)
                    )
                    .frame(height: 30)
                    Image(systemName: "speaker.wave.3.fill")
                        .font(.system(size: 14))
                        .foregroundColor(colorScheme == .dark ? .white.opacity(0.6) : .black.opacity(0.6))
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)
                .opacity(1 - (0.55 * dragProgressD))

                // Language: globe + current language; AirPlay
                HStack(spacing: 34) {
                    let translations = storyDetail?.translations ?? cachedTranslations
                    if !translations.isEmpty {
                        languageGlobeButton(translations: translations)
                    } else {
                        Color.clear.frame(width: 70, height: 52)
                    }

                    VStack(spacing: 6) {
                        AirPlayRoutePicker(tint: colorScheme == .dark ? .white : .black)
                            .frame(width: 44, height: 28)
                        Text("sleep_option_airplay")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundColor(colorScheme == .dark ? .white : .black)
                    }
                    .frame(minWidth: 70)
                }
                .padding(.top, 18)
                .opacity(1 - (0.65 * dragProgressD))

                Spacer(minLength: 40)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .offset(y: clampedDrag)
            .scaleEffect(1 - (0.08 * dragProgress))
            .clipped()
            .gesture(
                // Prevent accidental "drag" recognition when the user taps controls (pause/play).
                // Small touch movement can otherwise trigger the gesture and slightly shrink the artwork.
                DragGesture(minimumDistance: 12, coordinateSpace: .global)
                    .updating($dragY) { value, state, _ in
                        // Dead-zone: ignore minor downward movement so artwork doesn't animate on taps.
                        let deadZone: CGFloat = 10
                        state = max(0, value.translation.height - deadZone)
                    }
                    .onEnded { value in
                        let translation = max(0, value.translation.height)
                        let shouldMinimize = translation > 140 || value.predictedEndTranslation.height > 220
                        if shouldMinimize {
                            minimizeAction()
                        }
                    }
                
                
            )
            .animation(.interactiveSpring(response: 0.45, dampingFraction: 0.86), value: dragY)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        // Important: keep the blurred backdrop out of layout measuring.
        .background(blurredArtworkBackground)
        .background(Color.black.ignoresSafeArea())
        .clipShape(RoundedRectangle(cornerRadius: 32, style: .continuous))

        .onAppear {
            // Synchronous cache read so globe menu can render immediately.
            let store = SleepStoryTranslationsCacheStore.shared
            let cached = store.cachedTranslations(storyId: item.id)
            if !cached.isEmpty {
                cachedTranslations = cached
            }
            if let code = store.cachedSelectedLanguageCode(storyId: item.id), !code.isEmpty {
                selectedLanguageCode = code
            } else if selectedLanguageCode.isEmpty, let first = cached.first {
                selectedLanguageCode = first.language
            }

            // Initial load: prefer cached translation URL if available; resolve to local download if present.
            let fallbackURL = URL(string: "https://www.learningcontainer.com/wp-content/uploads/2020/02/Kalimba.mp3")!
            let remoteURL: URL = {
                if let t = currentTranslation, let urlStr = t.files.first?.fileUrl, let u = URL(string: urlStr) {
                    return u
                }
                return item.audioURL ?? fallbackURL
            }()
            let playable = SleepAudioDownloadStore.shared.resolvePlayableURL(
                storyId: item.id,
                languageCode: selectedLanguageCode.isEmpty ? nil : selectedLanguageCode,
                remoteURL: remoteURL
            ) ?? remoteURL
            print("[SleepPlayView] onAppear: storyId=\(item.id) selectedLang=\(selectedLanguageCode.isEmpty ? "default" : selectedLanguageCode) remote=\(remoteURL.absoluteString) playable=\(playable.absoluteString) isFile=\(playable.isFileURL) path=\(playable.isFileURL ? playable.path : "-")")
            playback.load(
                url: playable,
                title: displayTitle,
                subtitle: displaySubtitle,
                imageURL: item.imageURL,
                localImageName: item.localImageName
            )
        }
        .task(id: item.id) {
            await loadStoryDetailAndSelectLanguage()
        }
    }

    @ViewBuilder
    private func languageGlobeButton(translations: [StoryTranslationDTO]) -> some View {
        Menu {
            ForEach(translations, id: \.id) { trans in
                Button {
                    selectedLanguageCode = trans.language
                    SleepStoryTranslationsCacheStore.shared.saveSelectedLanguageCode(trans.language, storyId: item.id)
                    if let urlStr = trans.files.first?.fileUrl, let url = URL(string: urlStr) {
                        let playable = SleepAudioDownloadStore.shared.resolvePlayableURL(
                            storyId: item.id,
                            languageCode: trans.language,
                            remoteURL: url
                        ) ?? url
                        print("[SleepPlayView] language change: storyId=\(item.id) lang=\(trans.language) remote=\(url.absoluteString) playable=\(playable.absoluteString) isFile=\(playable.isFileURL) path=\(playable.isFileURL ? playable.path : "-")")
                        playback.load(
                            url: playable,
                            title: trans.title,
                            subtitle: displaySubtitle,
                            imageURL: item.imageURL,
                            localImageName: item.localImageName
                        )
                    }
                } label: {
                    HStack {
                        Text(languageDisplayName(trans.language))
                        if trans.language == selectedLanguageCode {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
        } label: {
            VStack(spacing: 6) {
                Image(systemName: "globe")
                    .font(.system(size: 22))
                Text(languageDisplayName(selectedLanguageCode))
                    .font(.system(size: 12, weight: .medium, design: .rounded))
            }
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .frame(width: 70, height: 52)
        }
    }

    private func languageDisplayName(_ code: String) -> String {
        switch code.lowercased() {
        case "en": return "English"
        case "ar": return "Arabic"
        case "ur": return "Urdu"
        case "fr": return "French"
        case "tr": return "Turkish"
        case "id": return "Indonesian"
        case "ms": return "Malay"
        default: return code.uppercased()
        }
    }

    private func loadStoryDetailAndSelectLanguage() async {
        // 1) Load cached translations + previously selected language (instant).
        let cached = SleepStoryTranslationsCacheStore.shared.cachedTranslations(storyId: item.id)
        await MainActor.run {
            cachedTranslations = cached
            if let cachedLang = SleepStoryTranslationsCacheStore.shared.cachedSelectedLanguageCode(storyId: item.id),
               !cachedLang.isEmpty {
                selectedLanguageCode = cachedLang
            } else if let first = cached.first {
                selectedLanguageCode = first.language
            }
        }

        // 2) Refresh from API, then upsert Core Data only if changed.
        do {
            let detail = try await IslamicCloudAPIClient.shared.fetchStoryDetail(storyId: item.id)
            await SleepStoryTranslationsCacheStore.shared.upsertTranslationsIfChanged(storyId: item.id, translations: detail.translations)
            await MainActor.run {
                storyDetail = detail
                cachedTranslations = detail.translations
                // Prefer previously-selected language if it still exists in API result.
                if let cachedLang = SleepStoryTranslationsCacheStore.shared.cachedSelectedLanguageCode(storyId: item.id),
                   detail.translations.contains(where: { $0.language == cachedLang }) {
                    selectedLanguageCode = cachedLang
                } else if let first = detail.translations.first, selectedLanguageCode.isEmpty {
                    selectedLanguageCode = first.language
                }
                let authorLine = detail.author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                if !authorLine.isEmpty {
                    playback.updateArtistLine(authorLine)
                }
                // List API often omits `author`; cards read subtitle from cache after detail fetch.
                SleepStoryAuthorCache.shared.saveAuthor(detail.author, for: item.id)
                NotificationCenter.default.post(name: .sleepStoryAuthorDidCache, object: nil)
            }
        } catch {
            // Not an API story or network error; keep storyDetail nil, initial URL already loaded in onAppear
        }
    }

    private var artworkView: some View {
        Group {
            if let url = item.imageURL {
                // 1. Check Core Data cache
                if let data = SleepImageCacheStore.shared.fetchImageData(for: url.absoluteString),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                }
                // 2. Load from remote and save
                else {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .onAppear {
                                    Task.detached(priority: .background) {
                                        if let (data, _) = try? await URLSession.shared.data(from: url),
                                           !data.isEmpty {
                                            SleepImageCacheStore.shared.saveImageInBackground(data: data, for: url.absoluteString)
                                        }
                                    }
                                }
                        case .failure:
                            placeholderArtwork
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            placeholderArtwork
                        }
                    }
                }
            } else if let name = item.localImageName, let image = UIImage(named: name) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                placeholderArtwork
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .clipped()
        .cornerRadius(16)
    }

    private var placeholderArtwork: some View {
        LinearGradient(
            colors: [
                Color(red: 0.35, green: 0.25, blue: 0.5),
                Color(red: 0.25, green: 0.18, blue: 0.35)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    /// Very light tint (lavender/pink) when artwork color hasn’t loaded yet — avoids stark white.
    private var veryLightFallback: Color {
        Color(red: 0.97, green: 0.94, blue: 0.98)
    }

    /// Full-bleed blurred artwork + white wash = very light shade of the image from API.
    @ViewBuilder
    private var blurredArtworkBackground: some View {
        Group {
            if let url = item.imageURL {
                // Check Core Data cache
                if let data = SleepImageCacheStore.shared.fetchImageData(for: url.absoluteString),
                   let uiImage = UIImage(data: data) {
                    Image(uiImage: uiImage)
                        .resizable()
                        .scaledToFill()
                } else {
                    AsyncImage(url: url) { phase in
                        if let image = phase.image {
                            image.resizable().scaledToFill()
                        } else {
                            veryLightFallback
                        }
                    }
                }
            } else if let name = item.localImageName, let image = UIImage(named: name) {
                Image(uiImage: image).resizable().scaledToFill()
            } else {
                veryLightFallback
            }
        }
        // Make it "very very zoomed" so it turns into a blur/bokeh texture.
        .scaleEffect(10.0)
        .blur(radius: 75)
        // Important: keep the transformed backdrop from impacting parent layout.
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .ignoresSafeArea()
        .overlay(colorScheme == .dark ? Color.black.opacity(0.35) : Color.white.opacity(0.18))
        .clipped()
    }
}

/// Native iOS route picker (AirPlay / Bluetooth output options).
private struct AirPlayRoutePicker: UIViewRepresentable {
    let tint: UIColor

    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView(frame: .zero)
        v.prioritizesVideoDevices = false
        v.backgroundColor = .clear
        v.tintColor = tint.withAlphaComponent(0.85)
        v.activeTintColor = tint
        return v
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tint.withAlphaComponent(0.85)
        uiView.activeTintColor = tint
    }
}

/// UISlider wrapper to get a small thumb (no big dot).
private struct SmallThumbSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: UIColor

    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }

    func makeUIView(context: Context) -> UISlider {
        let s = UISlider(frame: .zero)
        s.minimumValue = Float(range.lowerBound)
        s.maximumValue = Float(range.upperBound)
        s.value = Float(value)
        s.minimumTrackTintColor = tint
        s.maximumTrackTintColor = tint.withAlphaComponent(0.25)
        s.setThumbImage(Self.thumbImage(color: tint, diameter: 8), for: .normal)
        s.setThumbImage(Self.thumbImage(color: tint, diameter: 10), for: .highlighted)
        s.setContentHuggingPriority(.required, for: .vertical)
        s.setContentCompressionResistancePriority(.required, for: .vertical)
        s.setContentHuggingPriority(.defaultLow, for: .horizontal)
        s.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        s.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return s
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.minimumValue = Float(range.lowerBound)
        uiView.maximumValue = Float(range.upperBound)
        if abs(Double(uiView.value) - value) > 0.0001 {
            uiView.value = Float(value)
        }
        uiView.minimumTrackTintColor = tint
        uiView.maximumTrackTintColor = tint.withAlphaComponent(0.25)
        uiView.setThumbImage(Self.thumbImage(color: tint, diameter: 8), for: .normal)
        uiView.setThumbImage(Self.thumbImage(color: tint, diameter: 10), for: .highlighted)
    }

    final class Coordinator: NSObject {
        var value: Binding<Double>
        init(value: Binding<Double>) { self.value = value }

        @objc func changed(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }
    }

    private static func thumbImage(color: UIColor, diameter: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
            ctx.cgContext.setFillColor(color.withAlphaComponent(0.9).cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
    }
}

// (Intentionally removed RoundedCorner: player is not presented as a sheet.)

// MARK: - Playback manager using AVPlayer

final class SleepPlaybackManager: ObservableObject {
    @Published var isPlaying = false
    @Published var currentTime: TimeInterval = 0
    @Published var duration: TimeInterval = 0
    @Published var progress: Double = 0
    @Published var volume: Float = 0.8 {
        didSet { player?.volume = volume }
    }
    /// Non-nil when the asset failed to load or play (e.g. incompatible format).
    @Published var playbackError: String?

    var currentTimeFormatted: String {
        formatTime(currentTime)
    }
    var durationFormatted: String {
        formatTime(duration)
    }

    private var player: AVPlayer?
    private var timeObserver: Any?
    private var statusObserver: NSKeyValueObservation?
    private var routeChangeObserver: NSObjectProtocol?
    
    private var currentTitle: String = ""
    private var currentSubtitle: String = ""
    /// Synced to lock screen artist + popup bar subtitle (`story.author` from detail when available).
    @Published private(set) var nowPlayingArtistLine: String = ""
    private var currentImageURL: URL? = nil
    private var currentLocalImageName: String? = nil
    private var currentArtwork: MPMediaItemArtwork?
    private var imageLoadTask: Task<Void, Never>?
    private var isRemoteCommandSetup: Bool = false

    init() {
        routeChangeObserver = NotificationCenter.default.addObserver(
            forName: AVAudioSession.routeChangeNotification,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            guard let self else { return }
            // Switching routes (AirPlay/Bluetooth) can pause the player; nudge it to resume.
            if self.isPlaying {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
                    self.player?.play()
                }
            }
        }
    }

    deinit {
        if let obs = routeChangeObserver {
            NotificationCenter.default.removeObserver(obs)
        }
    }

    private static func logPlayback(_ message: String) {
        print("[SleepPlayback] \(message)")
    }

    private static func logPlaybackError(_ label: String, _ error: Error?) {
        guard let err = error as NSError? else {
            logPlayback("\(label): nil")
            return
        }
        logPlayback("\(label): domain=\(err.domain), code=\(err.code), \(err.localizedDescription)")
        if let underlying = err.userInfo[NSUnderlyingErrorKey] as? NSError {
            logPlayback("  underlying: domain=\(underlying.domain), code=\(underlying.code), \(underlying.localizedDescription)")
        }
        if !err.userInfo.isEmpty {
            logPlayback("  userInfo: \(err.userInfo)")
        }
    }

    func load(
        url: URL,
        title: String? = nil,
        subtitle: String? = nil,
        imageURL: URL? = nil,
        localImageName: String? = nil
    ) {
        Self.logPlayback("load(url:) → \(url.absoluteString) (isFileURL=\(url.isFileURL)) path=\(url.isFileURL ? url.path : "-")")
        self.currentTitle = title ?? "sleep_now_playing_unknown_title"
        let sub = (subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        self.currentSubtitle = sub
        self.nowPlayingArtistLine = sub
        self.currentImageURL = imageURL
        self.currentLocalImageName = localImageName
        self.currentArtwork = nil
        imageLoadTask?.cancel()
        imageLoadTask = nil

        // Preload artwork for lock screen / Now Playing.
        if let localImageName,
           let uiImage = UIImage(named: localImageName) {
            self.currentArtwork = Self.makeArtwork(from: uiImage)
            self.updateNowPlayingInfo()
        } else if let imageURL {
            let urlToLoad = imageURL
            imageLoadTask = Task.detached(priority: .utility) { [weak self] in
                guard let self else { return }
                do {
                    let (data, _) = try await URLSession.shared.data(from: urlToLoad)
                    guard !Task.isCancelled else { return }
                    guard let uiImage = UIImage(data: data) else { return }
                    await MainActor.run {
                        guard self.currentImageURL == urlToLoad else { return }
                        self.currentArtwork = Self.makeArtwork(from: uiImage)
                        self.updateNowPlayingInfo()
                    }
                } catch {
                    // Best-effort: artwork is optional.
                }
            }
        }

        setupRemoteCommands()
        playbackError = nil
        statusObserver?.invalidate()
        if let oldPlayer = player, let observer = timeObserver {
            oldPlayer.removeTimeObserver(observer)
        }
        player?.pause()
        player = nil
        timeObserver = nil

        do {
            try AVAudioSession.sharedInstance().setCategory(
                .playback,
                mode: .default,
                options: [
                    .allowAirPlay,
                    .allowBluetooth,
                    .allowBluetoothA2DP
                ]
            )
            try AVAudioSession.sharedInstance().setActive(true)
            Self.logPlayback("AVAudioSession configured: .playback, active=true")
        } catch {
            Self.logPlaybackError("AVAudioSession failed", error)
            playbackError = error.localizedDescription
        }

        var assetOptions: [String: Any] = [
            AVURLAssetPreferPreciseDurationAndTimingKey: true
        ]
        if !url.isFileURL {
            assetOptions["AVURLAssetHTTPHeaderFieldsKey"] = ["Content-Type": "audio/mpeg"]
        }
        let asset = AVURLAsset(url: url, options: assetOptions)
        let item = AVPlayerItem(asset: asset)
        let newPlayer = AVPlayer(playerItem: item)
        // Ensure the player is ready to play immediately once loaded
        newPlayer.automaticallyWaitsToMinimizeStalling = true
        newPlayer.allowsExternalPlayback = true
        
        player = newPlayer
        newPlayer.volume = volume

        duration = 0
        currentTime = 0
        progress = 0
        isPlaying = false

        statusObserver = item.observe(\.status, options: [.new, .initial]) { [weak self] playerItem, _ in
            DispatchQueue.main.async {
                guard let self = self else { return }
                switch playerItem.status {
                case .unknown:
                    Self.logPlayback("AVPlayerItem.status → unknown")
                case .readyToPlay:
                    Self.logPlayback("AVPlayerItem.status → readyToPlay, starting playback")
                    newPlayer.play()
                    self.isPlaying = true
                    self.updateNowPlayingInfo()
                case .failed:
                    Self.logPlayback("AVPlayerItem.status → failed")
                    Self.logPlaybackError("AVPlayerItem.error", playerItem.error)
                    if let err = playerItem.error as NSError? {
                        Self.logPlayback("  full description: \(err.description)")
                    }
                    let msg = playerItem.error?.localizedDescription ?? "sleep_playback_error_cannot_play"
                    self.playbackError = msg
                    self.isPlaying = false
                @unknown default:
                    Self.logPlayback("AVPlayerItem.status → unknown default")
                    break
                }
            }
        }

        item.asset.loadValuesAsynchronously(forKeys: ["duration"]) { [weak self] in
            guard let self = self else { return }
            var error: NSError?
            let status = item.asset.statusOfValue(forKey: "duration", error: &error)
            if status != .loaded {
                Self.logPlaybackError("AVAsset duration load failed", error)
            }
            guard status == .loaded else { return }
            let sec = CMTimeGetSeconds(item.asset.duration)
            DispatchQueue.main.async {
                self.duration = sec.isFinite && !sec.isNaN ? sec : 0
                self.updateNowPlayingInfo()
            }
        }

        let interval = CMTime(seconds: 0.5, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserver = player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            guard let self = self else { return }
            let sec = time.seconds
            self.currentTime = sec.isFinite && !sec.isNaN ? sec : 0
            if self.duration > 0 {
                self.progress = self.currentTime / self.duration
            }
        }
    }

    /// Updates lock screen / Control Center artist line without reloading the asset (e.g. after story detail fetch).
    func updateArtistLine(_ text: String) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        currentSubtitle = t
        nowPlayingArtistLine = t
        updateNowPlayingInfo()
    }

    func togglePlayPause() {
        if isPlaying {
            pause()
        } else {
            play()
        }
    }

    func play() {
        player?.play()
        isPlaying = true
        updateNowPlayingInfo()
    }

    func pause() {
        player?.pause()
        isPlaying = false
        updateNowPlayingInfo()
    }

    func seek(to progressValue: Double) {
        let sec = progressValue * duration
        player?.seek(to: CMTime(seconds: sec, preferredTimescale: 600))
        currentTime = sec
        progress = progressValue
        updateNowPlayingInfo()
    }

    private static func makeArtwork(from image: UIImage) -> MPMediaItemArtwork {
        // MPMediaItemArtwork calls the requestHandler to produce an image for the system size.
        let boundsSize = image.size == .zero ? CGSize(width: 300, height: 300) : image.size
        return MPMediaItemArtwork(boundsSize: boundsSize) { _ in
            image
        }
    }

    private func updateNowPlayingInfo() {
        var info = [String: Any]()
        info[MPMediaItemPropertyTitle] = currentTitle
        info[MPMediaItemPropertyArtist] = currentSubtitle
        if duration > 0 {
            info[MPMediaItemPropertyPlaybackDuration] = duration
            info[MPNowPlayingInfoPropertyElapsedPlaybackTime] = currentTime
        }
        info[MPNowPlayingInfoPropertyPlaybackRate] = isPlaying ? 1.0 : 0.0

        if let artwork = currentArtwork {
            info[MPMediaItemPropertyArtwork] = artwork
        }
        
        MPNowPlayingInfoCenter.default().nowPlayingInfo = info
    }

    private func setupRemoteCommands() {
        guard !isRemoteCommandSetup else { return }
        isRemoteCommandSetup = true
        let center = MPRemoteCommandCenter.shared()
        center.playCommand.isEnabled = true
        center.playCommand.addTarget { [weak self] _ in
            self?.play()
            return .success
        }
        center.pauseCommand.isEnabled = true
        center.pauseCommand.addTarget { [weak self] _ in
            self?.pause()
            return .success
        }
        center.changePlaybackPositionCommand.isEnabled = true
        center.changePlaybackPositionCommand.addTarget { [weak self] event in
            guard let self = self, let timeEvent = event as? MPChangePlaybackPositionCommandEvent else { return .commandFailed }
            let position = timeEvent.positionTime
            self.player?.seek(to: CMTime(seconds: position, preferredTimescale: 600))
            self.currentTime = position
            self.updateNowPlayingInfo()
            return .success
        }
    }

    func skipForward() {
        seek(to: min(1, progress + 0.05))
    }

    func skipBackward() {
        seek(to: max(0, progress - 0.05))
    }

    private func formatTime(_ seconds: TimeInterval) -> String {
        let s = Int(seconds) % 60
        let m = Int(seconds) / 60
        return String(format: "%02d:%02d", m, s)
    }
}
