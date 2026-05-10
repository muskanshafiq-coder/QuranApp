//
//  ReciterSurahNowPlayingView.swift
//

import SwiftUI
import AVFoundation

struct ReciterSurahNowPlayingView: View {
    let detail: IslamicCloudReciterDetailPayload
    let surah: IslamicCloudReciterSurahItemDTO
    let onMinimize: () -> Void

    @ObservedObject private var player: ReciterSurahAudioPlayer

    init(
        detail: IslamicCloudReciterDetailPayload,
        surah: IslamicCloudReciterSurahItemDTO,
        player: ReciterSurahAudioPlayer,
        onMinimize: @escaping () -> Void
    ) {
        self.detail = detail
        self.surah = surah
        self.onMinimize = onMinimize
        self._player = ObservedObject(wrappedValue: player)
    }

    @State private var ayahs: [AyahItem] = []
    @State private var surahMeta: SurahItem?
    @State private var translationByAyah: [Int: String] = [:]
    @State private var loadFailed = false
    @State private var isLoadingAyahs = true
    @State private var shuffleEnabled = false
    @State private var repeatMode: Int = 0
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared
    @State private var translationSheetContext: AyahTranslationSheetContext?
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    /// UIKit nav bar + SwiftUI toolbar — toggled from scroll *direction* (delta),
    /// not scroll position, so show/hide happens immediately on each reversal.
    @State private var reciterNavBarUIKitHidden = false
    /// Previous `ScrollTopMinYForNavBarPreferenceKey` sample for delta-based bar toggling.
    @State private var lastScrollContentMinY: CGFloat = .infinity
    /// Last time we flipped `reciterNavBarUIKitHidden`, used to suppress chatter
    /// while the visual transform animation is still in flight.
    @State private var lastNavBarToggleAt: Date = .distantPast
    /// Ignore scroll samples briefly after a bar visibility flip to avoid
    /// feedback loops caused by layout changes while bottom chrome transitions.
    @State private var suppressScrollUpdatesUntil: Date = .distantPast
    /// Hysteresis state: only flip bars after enough travel in one direction.
    @State private var pendingScrollDirection: Int = 0 // -1 up, +1 down
    @State private var pendingScrollTravel: CGFloat = 0

    private var reciterTitle: String {
        let t = detail.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? "" : t
    }

    private var ayahCountForMapping: Int {
        if !ayahs.isEmpty { return ayahs.count }
        if surah.ayahCount > 0 { return surah.ayahCount }
        return 1
    }

    private var activeAyahNumber: Int {
        player.activeAyahNumber(ayahCount: ayahCountForMapping)
    }

    private var displayTitleLine: String {
        if let meta = surahMeta {
            return "\(meta.nameEnglish) — \(meta.nameArabic)"
        }
        let en = surah.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return en.lowercased().hasPrefix("surah") ? en : "Surah \(en)"
    }

    private var arabicHeaderTitle: String {
        (surah.nameAr ?? surahMeta?.nameArabic ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var audioOutputLabel: String {
        AVAudioSession.sharedInstance().currentRoute.outputs.first?.portName ?? ""
    }

    private var playbackRateLabel: String {
        let r = Double(player.playbackRate)
        if abs(r - 1) < 0.001 { return "1.0x" }
        let f = abs(r * 10 - Double(Int(r * 10))) < 0.01
        return f ? String(format: "%.1fx", r) : String(format: "%.2fx", r)
    }

    var body: some View {
        AppNavigationContainer{
            ZStack {
                Color.app.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if loadFailed {
                        Text("error")
                            .foregroundColor(.white.opacity(0.7))
                            .padding()
                        Spacer()
                    } else if isLoadingAyahs, ayahs.isEmpty {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                VStack(alignment: .leading, spacing: 0) {
                                    istiadhBlock
                                        .padding(.horizontal, 16)
                                        .padding(.bottom, 16)
                                        .reportScrollTopMinYForNavigationBar()

                                    LazyVStack(alignment: .leading, spacing: 0) {
                                        ForEach(ayahs) { ayah in
                                            ReciterPlayerAyahRow(
                                                ayah: ayah,
                                                isActive: ayah.numberInSurah == activeAyahNumber,
                                                isAyahBookmarked: audioBookmarksViewModel.containsAyahBookmark(
                                                    reciterSlug: detail.slug,
                                                    surahNumber: surah.number,
                                                    ayahNumber: ayah.numberInSurah
                                                ),
                                                accentColor: selectedThemeColorManager.selectedColor,
                                                onSeekToAyah: {
                                                    player.seekToEstimatedStartOfAyah(
                                                        ayahNumber: ayah.numberInSurah,
                                                        ayahCount: ayahCountForMapping
                                                    )
                                                },
                                                onToggleAyahBookmark: { toggleAyahBookmark(ayah) },
                                                onShareAyah: { shareAyah(ayah) },
                                                onPlayAyah: { DummyPaywallPresenter.shared.present() },
                                                onShowTranslation: { presentAyahTranslationSheet(ayah) },
                                                onRepeatOption: { DummyPaywallPresenter.shared.present() }
                                            )
                                            .id(ayah.numberInSurah)
                                        }
                                    }
                                    .padding(.horizontal, 16)
                                }
                                .padding(.bottom, 220)
                            }
                            .coordinateSpace(name: ReciterNowPlayingScrollSpace.name)
                            .onChange(of: activeAyahNumber) { newVal in
                                withAnimation(.easeInOut(duration: 0.35)) {
                                    proxy.scrollTo(newVal, anchor: .center)
                                }
                            }
                            .onChange(of: ayahs.count) { count in
                                guard count > 0 else { return }
                                let n = activeAyahNumber
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    withAnimation(.easeInOut(duration: 0.35)) {
                                        proxy.scrollTo(n, anchor: .center)
                                    }
                                }
                            }
                        }
                    }
                }
                .overlay(alignment: .bottom) {
                    bottomChrome
                        .offset(y: reciterNavBarUIKitHidden ? 260 : 0)
                        .opacity(reciterNavBarUIKitHidden ? 0 : 1)
                        .allowsHitTesting(!reciterNavBarUIKitHidden)
                        .accessibilityHidden(reciterNavBarUIKitHidden)
                        .animation(.easeInOut(duration: 0.28), value: reciterNavBarUIKitHidden)
                }
                .onPreferenceChange(ScrollTopMinYForNavBarPreferenceKey.self) { minY in
                    updateNavBarVisibilityFromScroll(minY: minY)
                }
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            onMinimize()
                        } label: {
                            Image(systemName: "chevron.down")
                        }
                    }
                    ToolbarItem(placement: .principal) {
                        Text(arabicHeaderTitle)
                            .font(.custom("A Thuluth", size: 22))
                            .fontWeight(.bold)
                            .foregroundColor(selectedThemeColorManager.selectedColor)

                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            // TODO: Wire favourite toggle for the surah.
                        } label: {
                            Image(systemName: "star.fill")
                        }
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Menu {
                            Button("general_share") {}
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                    }
                }
            }
            .navigationBarUIKitHidden(reciterNavBarUIKitHidden)
            .onChange(of: surah.number) { _ in
                lastScrollContentMinY = .infinity
                reciterNavBarUIKitHidden = false
                suppressScrollUpdatesUntil = .distantPast
                pendingScrollDirection = 0
                pendingScrollTravel = 0
            }
            .task {
                await loadAyahContent()
            }
            .sheet(item: $translationSheetContext) { context in
                AyahTranslationSheet(context: context)
                    .environmentObject(selectedThemeColorManager)
            }
        }
    }

    private var bookmarkSurahTitleEn: String {
        if let meta = surahMeta {
            return meta.nameEnglish
        }
        let en = surah.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return en.lowercased().hasPrefix("surah") ? en : "Surah \(en)"
    }

    private var bookmarkSurahTitleAr: String? {
        let ar = (surah.nameAr ?? surahMeta?.nameArabic)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return ar.isEmpty ? nil : ar
    }

    private func toggleAyahBookmark(_ ayah: AyahItem) {
        let slug = detail.slug
        let surahNumber = surah.number
        let ayahNumber = ayah.numberInSurah
        if audioBookmarksViewModel.containsAyahBookmark(
            reciterSlug: slug,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber
        ) {
            audioBookmarksViewModel.removeAyahBookmark(
                reciterSlug: slug,
                surahNumber: surahNumber,
                ayahNumber: ayahNumber
            )
            SurahRowActionFeedback.presentRemovedFromBookmark()
        } else {
            let nameEn = detail.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
            let portrait = detail.image
                .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
                .flatMap { $0.isEmpty ? nil : $0 }
            let bookmark = AudioSurahBookmark(
                reciterSlug: slug,
                reciterNameEn: nameEn,
                portraitURLString: portrait,
                surahNumber: surahNumber,
                surahTitleEn: bookmarkSurahTitleEn,
                surahTitleAr: bookmarkSurahTitleAr,
                ayahNumber: ayahNumber
            )
            audioBookmarksViewModel.add(bookmark)
            SurahRowActionFeedback.presentAddedToBookmark()
        }
    }

    private func shareAyah(_ ayah: AyahItem) {
        let line = String(
            format: NSLocalizedString("ayah_share_body_format", comment: ""),
            ayah.text,
            bookmarkSurahTitleEn,
            ayah.numberInSurah
        )
        ShareHelper.presentShareSheet(items: [line])
    }

    private func presentAyahTranslationSheet(_ ayah: AyahItem) {
        translationSheetContext = AyahTranslationSheetContext(
            ayahNumber: ayah.numberInSurah,
            surahNumber: surah.number,
            arabicText: ayah.text,
            translation: translationByAyah[ayah.numberInSurah]
        )
    }

    /// Hides the nav bar when the user scrolls **down** the list (content `minY`
    /// decreases) and shows it again on the next **up** scroll — independent of
    /// how far from the top they are. The visual change is a transform/alpha
    /// animation on `UINavigationBar` (no safe-area reflow), and a minimum
    /// dwell time stops the state from chattering during a single gesture.
    private func updateNavBarVisibilityFromScroll(minY: CGFloat) {
        guard minY.isFinite else { return }
        if Date() < suppressScrollUpdatesUntil { return }

        let prev = lastScrollContentMinY
        if !prev.isFinite {
            lastScrollContentMinY = minY
            return
        }

        let delta = minY - prev
        lastScrollContentMinY = minY

        // Ignore sub-point noise and big jumps (auto scroll-to-ayah, relayout).
        let noise: CGFloat = 8
        let jump: CGFloat = 140
        if abs(delta) < noise { return }
        if abs(delta) > jump { return }

        // Require sustained movement before flipping visibility. This prevents
        // tiny settle/reflow movement from causing one extra jerk.
        let direction = delta < 0 ? -1 : 1
        if direction != pendingScrollDirection {
            pendingScrollDirection = direction
            pendingScrollTravel = 0
        }
        pendingScrollTravel += abs(delta)

        let triggerTravel: CGFloat = 28
        guard pendingScrollTravel >= triggerTravel else { return }
        pendingScrollTravel = 0

        let desiredHidden = direction < 0
        guard desiredHidden != reciterNavBarUIKitHidden else { return }

        // Don't flip again until the previous bar animation has settled.
        let minDwell: TimeInterval = 0.30
        guard Date().timeIntervalSince(lastNavBarToggleAt) > minDwell else { return }
        lastNavBarToggleAt = Date()
        reciterNavBarUIKitHidden = desiredHidden
        suppressScrollUpdatesUntil = Date().addingTimeInterval(0.35)
        // Reset baseline after each transition so post-animation settling
        // doesn't get interpreted as a reverse scroll gesture.
        lastScrollContentMinY = .infinity
        pendingScrollDirection = 0
        pendingScrollTravel = 0
    }

    private var istiadhBlock: some View {
        Text(Self.istiadhArabic)
            .font(.custom("A Thuluth", size: 22))
            .multilineTextAlignment(.center)
            .fontWeight(.bold)
            .foregroundColor(selectedThemeColorManager.selectedColor)
            .frame(maxWidth: .infinity, alignment: .center)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private static let istiadhArabic =
        "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ"

    // MARK: - Bottom chrome (reference layout)

    private var bottomChrome: some View {

        return VStack(spacing: 12) {
            VStack(spacing: 6) {
                HStack(spacing: 0) {
                    compactControlButton("moon.zzz") { }

                    Button { player.skip(seconds: -15) } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        player.seekToPreviousAyahSegment(
                            activeAyah: activeAyahNumber,
                            ayahCount: ayahCountForMapping
                        )
                    } label: {
                        Image(systemName: "backward.end.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button { player.togglePlayPause() } label: {
                        Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(.white)
                            .frame(width: 52, height: 52)
                            .background(Circle().fill(Color.white.opacity(0.12)))
                    }
                    .buttonStyle(.plain)

                    Button {
                        player.seekToNextAyahSegment(
                            activeAyah: activeAyahNumber,
                            ayahCount: ayahCountForMapping
                        )
                    } label: {
                        Image(systemName: "forward.end.fill")
                            .font(.system(size: 22))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button { player.skip(seconds: 15) } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 20))
                            .foregroundColor(.white)
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Menu {
                        Button("general_share") {}
                    } label: {
                        Image(systemName: "ellipsis.circle.fill")
                            .font(.system(size: 22))
                            .foregroundColor(selectedThemeColorManager.selectedColor)
                    }
                    .frame(width: 44)
                }
                .padding(.horizontal, 6)
                
                HStack {
                    Text(formatTime(player.currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text(formatTime(player.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
                ReciterSmallThumbSlider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    range: 0 ... max(player.duration, 0.1),
                )
                .frame(height: 28)


            }
            .padding(.horizontal, 16)

           

            HStack(alignment: .top, spacing: 10) {
                Text(displayTitleLine)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Button {
                    shuffleEnabled.toggle()
                } label: {
                    Image(systemName: "shuffle")
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.plain)

                Button {
                    repeatMode = (repeatMode + 1) % 3
                    if repeatMode == 1 {
                        player.seek(to: 0)
                    }
                } label: {
                    Image(systemName: repeatIcon)
                        .font(.system(size: 18, weight: .medium))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 16)

            if !reciterTitle.isEmpty {
                Text(reciterTitle)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.55))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.horizontal, 16)
                    .padding(.top, -6)
            }

            HStack(spacing: 0) {
                Button { } label: {
                    Image(systemName: "list.bullet")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                Button {
                    player.cyclePlaybackRate()
                } label: {
                    Text(playbackRateLabel)
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.85))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)

                VStack(spacing: 2) {
                    ReciterAirPlayRoutePicker(tint: .white)
                        .frame(width: 34, height: 28)
                    if !audioOutputLabel.isEmpty {
                        Text(audioOutputLabel)
                            .font(.system(size: 10, weight: .medium))
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                }
                .frame(maxWidth: .infinity)

                Button { } label: {
                    Image(systemName: "car.fill")
                        .font(.system(size: 18))
                        .foregroundColor(.white.opacity(0.65))
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .background(.ultraThinMaterial.opacity(0.95))
    }

    private var repeatIcon: String {
        switch repeatMode {
        case 1: return "repeat.1"
        case 2: return "repeat"
        default: return "repeat"
        }
    }

    private func compactControlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.65))
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }

    private func formatTime(_ sec: Double) -> String {
        guard sec.isFinite, sec >= 0 else { return "00:00" }
        let s = Int(floor(sec))
        let m = s / 60
        let r = s % 60
        return String(format: "%02d:%02d", m, r)
    }

    private func loadAyahContent() async {
        isLoadingAyahs = true
        loadFailed = false
        do {
            let result = try await QuranAPIClient.shared.fetchSurah(number: surah.number)
            let map = await ReciterPlaybackTranslation.loadMap(surahNumber: surah.number)
            ayahs = result.ayahs
            surahMeta = result.surah
            translationByAyah = map
            isLoadingAyahs = false
        } catch {
            loadFailed = true
            isLoadingAyahs = false
        }
    }
}
