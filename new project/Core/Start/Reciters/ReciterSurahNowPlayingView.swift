//
//  ReciterSurahNowPlayingView.swift
//

import SwiftUI
import AVFoundation

private enum ReciterTransportRingBlink: Equatable {
    case previousSurah
    case nextSurah
    case playPause
}

private enum MarqueeTextUnitWidthKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = nextValue()
    }
}

/// Single-line title: scrolls toward leading (LTR). Two copies spaced by `width + gap` so the loop is **mathematically seamless** — jerk was from `cycle` changing when measured width jumped from 0 → real width.
private struct MarqueeSurahTitleView: View {
    let text: String
    let fontSize: CGFloat

    @State private var stableTextWidth: CGFloat = 0
    @State private var lastMeasuredRaw: CGFloat = 0

    private var font: Font { .system(size: fontSize, weight: .semibold) }

    private var segment: String {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return t.isEmpty ? " " : t
    }

    var body: some View {
        GeometryReader { geo in
            let containerW = max(geo.size.width, 1)
            let gap: CGFloat = 40
            let speedPtsPerSec: CGFloat = 38
            let rawW = lastMeasuredRaw
            let needsMarquee = rawW > containerW + 2
            let w = max(stableTextWidth, 1)
            /// Period must equal distance between the **starts** of the two identical `Text` rows (only `[T][gap][T]` is periodic with this period).
            let cycle = w + gap

            ZStack(alignment: .leading) {
                Text(segment)
                    .font(font)
                    .lineLimit(1)
                    .fixedSize(horizontal: true, vertical: false)
                    .hidden()
                    .background(
                        GeometryReader { g in
                            Color.clear.preference(key: MarqueeTextUnitWidthKey.self, value: g.size.width)
                        }
                    )

                if needsMarquee, stableTextWidth > 1 {
                    TimelineView(.animation(minimumInterval: 1 / 60, paused: false)) { context in
                        let t = context.date.timeIntervalSinceReferenceDate
                        let dist = CGFloat(t) * speedPtsPerSec
                        // Phase so the strip does not always start at the title's leading edge (reads more "from trailing" first) without changing loop length.
                        let phase0 = containerW.truncatingRemainder(dividingBy: cycle)
                        let mod = (dist + phase0).truncatingRemainder(dividingBy: cycle)
                        let offsetX = -mod
                        marqueeRow(gap: gap)
                            .offset(x: offsetX)
                    }
                    .id(segment)
                } else {
                    Text(segment)
                        .font(font)
                        .lineLimit(1)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .environment(\.layoutDirection, .leftToRight)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            .clipped()
            .onPreferenceChange(MarqueeTextUnitWidthKey.self) { newW in
                guard newW.isFinite, newW > 0.5 else { return }
                lastMeasuredRaw = newW
                if stableTextWidth < 1 || abs(newW - stableTextWidth) > 3 {
                    stableTextWidth = newW
                }
            }
            .onChange(of: text) { _ in
                stableTextWidth = 0
                lastMeasuredRaw = 0
            }
        }
        .frame(height: max(26, fontSize * 1.45))
    }

    @ViewBuilder
    private func marqueeRow(gap: CGFloat) -> some View {
        HStack(spacing: gap) {
            Text(segment)
                .font(font)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
            Text(segment)
                .font(font)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
    }
}

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
    /// Same ordering as Quran detail options (excluding Arabic mushaf); ids that loaded for this surah.
    @State private var selectedTranslationIds: [String] = []
    @State private var translationByAyah: [String: [Int: String]] = [:]
    @State private var loadFailed = false
    @State private var isLoadingAyahs = true
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared
    @ObservedObject private var premiumManager = PremiumManager.shared
    @State private var translationSheetContext: AyahTranslationSheetContext?
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @State private var reciterNavBarUIKitHidden = false
    @State private var lastScrollContentMinY: CGFloat = .infinity
    @State private var lastNavBarToggleAt: Date = .distantPast
    @State private var suppressScrollUpdatesUntil: Date = .distantPast
    @State private var pendingScrollDirection: Int = 0 // -1 up, +1 down
    @State private var pendingScrollTravel: CGFloat = 0
    @State private var pauseAutoAyahScrollUntil: Date = .distantPast
    @State private var isTimelineScrubbing = false
    @State private var transportRingBlink: ReciterTransportRingBlink?
    @State private var showCarPlayPremiumInfo = false
    @State private var quranDetailOptionsSheetTab: QuranDetailOptionsTab?
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @AppStorage(UserDefaultsManager.Keys.quranLatestSelectedTranslationId) private var storedLatestTranslationId: String = ""

    private var ayahListHorizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 48 : 16
    }

    /// Keeps ayah blocks readable and centered on iPad (reference-style margins).
    private var ayahContentMaxWidth: CGFloat {
        horizontalSizeClass == .regular ? 720 : .infinity
    }

    /// Same “latest selected translation” flag as in Quran options (`TranslationRegistry` + UserDefaults).
    private var translationsToolbarFlagEmoji: String {
        let latest = storedLatestTranslationId.trimmingCharacters(in: .whitespacesAndNewlines)
        if !latest.isEmpty, latest != "quran-buck" {
            return TranslationRegistry.flag(for: latest)
        }
        let ids = selectedTranslationIds.isEmpty
            ? UserDefaultsManager.shared.quranSelectedTranslationIds
            : selectedTranslationIds
        if let id = ids.last(where: { $0 != "quran-buck" }) ?? ids.first(where: { $0 != "quran-buck" }) {
            return TranslationRegistry.flag(for: id)
        }
        return TranslationRegistry.flag(for: "quran-buck")
    }

    private func selectedTranslationTexts(for ayahNumber: Int) -> [String] {
        selectedTranslationIds.compactMap { id in
            guard let raw = translationByAyah[id]?[ayahNumber] else { return nil }
            let t = raw.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? nil : t
        }
    }

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

    /// Current surah position within this reciter’s surah list (e.g. “12 of 114”).
    private var principalSurahIndexTitle: String {
        let list = detail.surahs
        let total: Int
        let current: Int
        if list.isEmpty {
            total = 114
            current = surah.number
        } else if let idx = list.firstIndex(where: { $0.number == surah.number }) {
            total = list.count
            current = idx + 1
        } else {
            total = list.count
            current = surah.number
        }
        return String(
            format: NSLocalizedString("reciter_now_playing_surah_index_of_total", comment: ""),
            locale: .current,
            arguments: [current as CVarArg, total as CVarArg]
        )
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

    private func playableSurahsSorted() -> [IslamicCloudReciterSurahItemDTO] {
        detail.playableSurahsSortedByNumber()
    }

    private func previousPlayableSurah() -> IslamicCloudReciterSurahItemDTO? {
        let list = playableSurahsSorted()
        guard let i = list.firstIndex(where: { $0.number == surah.number }), i > 0 else { return nil }
        return list[i - 1]
    }

    private func nextPlayableSurah() -> IslamicCloudReciterSurahItemDTO? {
        detail.nextPlayableSurah(after: surah.number, shuffle: player.shuffleSurahsEnabled, wrap: false)
    }

    private func presentPlayableSurah(_ dto: IslamicCloudReciterSurahItemDTO) {
        let session = ReciterPlaybackSession(detail: detail, surah: dto)
        ReciterPlaybackPopupCoordinator.shared.present(session: session, openFullScreen: true)
    }

    private func goToPreviousReciterAudio() {
        if let prev = previousPlayableSurah() {
            presentPlayableSurah(prev)
        } else {
            player.seek(to: 0)
        }
    }

    private func goToNextReciterAudio() {
        if let next = nextPlayableSurah() {
            presentPlayableSurah(next)
        } else {
            player.seekToNextAyahSegment(
                activeAyah: activeAyahNumber,
                ayahCount: ayahCountForMapping
            )
        }
    }

    private var repeatIsActive: Bool { player.surahRepeatMode != 0 }

    private var repeatSystemImageName: String {
        player.surahRepeatMode == 1 ? "repeat.1" : "repeat"
    }

    @ViewBuilder
    private func chromeTransportChip(active: Bool, accent: Color, @ViewBuilder label: () -> some View) -> some View {
        label()
            .frame(width: 40, height: 40)
            .background(
                RoundedRectangle(cornerRadius: 10, style: .continuous)
                    .fill(active ? accent : Color.clear)
            )
    }

    private func flashTransportRing(_ ring: ReciterTransportRingBlink) {
        withAnimation(.easeOut(duration: 0.16)) {
            transportRingBlink = ring
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.38) {
            withAnimation(.easeOut(duration: 0.22)) {
                if transportRingBlink == ring {
                    transportRingBlink = nil
                }
            }
        }
    }


    var body: some View {
        AppNavigationContainer{
            ZStack {
                Color.app.ignoresSafeArea()
                
                VStack(spacing: 0) {
                    if loadFailed {
                        Text("error")
                            .padding()
                        Spacer()
                    } else if isLoadingAyahs, ayahs.isEmpty {
                        Spacer()
                        ProgressView()
                        Spacer()
                    } else {
                        ScrollViewReader { proxy in
                            ScrollView {
                                HStack(spacing: 0) {
                                    VStack(alignment: .leading, spacing: 0) {
                                        istiadhBlock
                                            .padding(.horizontal, ayahListHorizontalPadding)
                                            .padding(.bottom, 20)
                                            .reportScrollTopMinYForNavigationBar()

                                        LazyVStack(alignment: .leading, spacing: 0) {
                                            ForEach(ayahs) { ayah in
                                                ReciterPlayerAyahRow(
                                                    ayah: ayah,
                                                    translationTexts: selectedTranslationTexts(for: ayah.numberInSurah),
                                                    isAyahBookmarked: audioBookmarksViewModel.containsAyahBookmark(
                                                        reciterSlug: detail.slug,
                                                        surahNumber: surah.number,
                                                        ayahNumber: ayah.numberInSurah
                                                    ),
                                                    accentColor: selectedThemeColorManager.selectedColor,
                                                    onToggleAyahBookmark: { toggleAyahBookmark(ayah) },
                                                    onShareAyah: { shareAyah(ayah) },
                                                    onPlayAyah: { DummyPaywallPresenter.shared.present() },
                                                    onShowTranslation: { presentAyahTranslationSheet(ayah) },
                                                    onRepeatOption: { DummyPaywallPresenter.shared.present() }
                                                )
                                                .id(ayah.numberInSurah)
                                            }
                                        }
                                        .padding(.horizontal, ayahListHorizontalPadding)
                                    }
                                    .frame(maxWidth: ayahContentMaxWidth, alignment: .leading)
                                }
                                .padding(.bottom, 220)
                                .frame(maxWidth: .infinity)
//                                .background(Color(uiColor: .secondarySystemGroupedBackground))
                            }
                            .coordinateSpace(name: ReciterNowPlayingScrollSpace.name)
                            .simultaneousGesture(
                                TapGesture().onEnded {
                                    toggleChromeVisibility()
                                }
                            )
                            .modifier(ReciterScrollUserInteractionPauseModifier(pauseUntil: $pauseAutoAyahScrollUntil))
                            .onChange(of: activeAyahNumber) { newVal in
                                scrollToActiveAyahIfAllowed(proxy: proxy, ayahNumber: newVal)
                            }
                            .onChange(of: ayahs.count) { count in
                                guard count > 0 else { return }
                                let n = activeAyahNumber
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
                                    scrollToActiveAyahIfAllowed(proxy: proxy, ayahNumber: n)
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
                        Text(principalSurahIndexTitle)
                            .font(.system(size: 16, weight: .medium))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            quranDetailOptionsSheetTab = .translations
                        } label: {
                            Text(translationsToolbarFlagEmoji)
                                .font(.system(size: 22))
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                        .accessibilityLabel(Text("quran_options_tab_translations"))
                    }
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            quranDetailOptionsSheetTab = .appearance
                        } label: {
                            Image(systemName: "ellipsis")
                        }
                        .accessibilityLabel(Text("quran_options_tab_appearance"))
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
                pauseAutoAyahScrollUntil = .distantPast
                isTimelineScrubbing = false
                quranDetailOptionsSheetTab = nil
            }
            .task(id: surah.number) {
                await loadAyahContent()
            }
            .sheet(item: $translationSheetContext) { context in
                AyahTranslationSheet(context: context)
                    .environmentObject(selectedThemeColorManager)
            }
            .sheet(item: $quranDetailOptionsSheetTab, onDismiss: {
                // Runs for every dismiss (close button, swipe down, etc.) after `quranSelectedTranslationIds` is updated.
                Task { await reloadTranslationsMatchingSelection() }
            }) { tab in
                QuranDetailOptionsSheet(initialTab: tab, onDismiss: {
                    quranDetailOptionsSheetTab = nil
                })
                .environmentObject(selectedThemeColorManager)
            }
            .alert("feature_carplay_title", isPresented: $showCarPlayPremiumInfo) {
                Button("general_ok", role: .cancel) {}
            } message: {
                Text("feature_carplay_desc")
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
        let translationCombined = selectedTranslationTexts(for: ayah.numberInSurah).joined(separator: "\n\n")
        translationSheetContext = AyahTranslationSheetContext(
            ayahNumber: ayah.numberInSurah,
            surahNumber: surah.number,
            arabicText: ayah.text,
            translation: translationCombined.isEmpty ? nil : translationCombined
        )
    }

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

    private func toggleChromeVisibility() {
        withAnimation(.easeInOut(duration: 0.28)) {
            reciterNavBarUIKitHidden.toggle()
        }
        lastNavBarToggleAt = Date()
        suppressScrollUpdatesUntil = Date().addingTimeInterval(0.35)
        lastScrollContentMinY = .infinity
        pendingScrollDirection = 0
        pendingScrollTravel = 0
    }

    private func scrollToActiveAyahIfAllowed(proxy: ScrollViewProxy, ayahNumber: Int) {
        guard !isTimelineScrubbing else { return }
        guard Date() > pauseAutoAyahScrollUntil else { return }
        withAnimation(.easeInOut(duration: 0.78)) {
            proxy.scrollTo(ayahNumber, anchor: .bottom)
        }
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
                    compactControlButton("gauge") {
                        DummyPaywallPresenter.shared.present()
                    }

                    Button {
                        guard player.isPlaying, player.duration > 0 else { return }
                        player.skip(seconds: -15)
                    } label: {
                        Image(systemName: "gobackward.15")
                            .font(.system(size: 20))
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        flashTransportRing(.previousSurah)
                        goToPreviousReciterAudio()
                    } label: {
                        ZStack {
                            Image(systemName: "backward.end.fill")
                                .font(.system(size: 22))
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        player.togglePlayPause()
                        flashTransportRing(.playPause)
                    } label: {
                            Image(systemName: player.isPlaying ? "pause.fill" : "play.fill")
                                .font(.system(size: 26, weight: .medium))
                    }
                    .buttonStyle(.plain)

                    Button {
                        flashTransportRing(.nextSurah)
                        goToNextReciterAudio()
                    } label: {
                        ZStack {
                            Image(systemName: "forward.end.fill")
                                .font(.system(size: 22))
                        }
                    }
                    .buttonStyle(.plain)
                    .frame(maxWidth: .infinity)

                    Button {
                        guard player.duration > 0 else { return }
                        player.skip(seconds: 15)
                    } label: {
                        Image(systemName: "goforward.15")
                            .font(.system(size: 20))
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
                    Spacer()
                    Text(formatTime(player.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                }
                ReciterSmallThumbSlider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    range: 0 ... max(player.duration, 0.1),
                    onScrubbingChanged: { scrubbing in
                        isTimelineScrubbing = scrubbing
                        if scrubbing {
                            pauseAutoAyahScrollUntil = Date().addingTimeInterval(2.0)
                        } else {
                            pauseAutoAyahScrollUntil = Date().addingTimeInterval(0.6)
                        }
                    }
                )
                .frame(height: 28)


            }
            .padding(.horizontal, 16)

           

            HStack(alignment: .top, spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    MarqueeSurahTitleView(text: displayTitleLine, fontSize: 18)
                        .frame(maxWidth: .infinity, alignment: .leading)

                    if !reciterTitle.isEmpty {
                        Text(reciterTitle)
                            .font(.system(size: 14, weight: .regular))
                            .lineLimit(1)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                HStack(spacing: 10) {
                    Button {
                        player.shuffleSurahsEnabled.toggle()
                    } label: {
                        chromeTransportChip(active: player.shuffleSurahsEnabled, accent: selectedThemeColorManager.selectedColor) {
                            Image(systemName: "shuffle")
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)

                    Button {
                        player.surahRepeatMode = (player.surahRepeatMode + 1) % 3
                    } label: {
                        chromeTransportChip(active: repeatIsActive, accent: selectedThemeColorManager.selectedColor) {
                            Image(systemName: repeatSystemImageName)
                                .font(.system(size: 17, weight: .medium))
                        }
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 1)
            }
            .padding(.horizontal, 16)

            ZStack {
                VStack(spacing: 2) {
                    ReciterAirPlayRoutePicker(tint: .gray)
                        .frame(width: 34, height: 28)
                    if !audioOutputLabel.isEmpty {
                        Text(audioOutputLabel)
                            .font(.system(size: 10, weight: .medium))
                            .multilineTextAlignment(.center)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                            .frame(maxWidth: 160, alignment: .center)
                    }
                }

                HStack(alignment: .center, spacing: 0) {
                    HStack(spacing: 8) {
                        Button {
                            DummyPaywallPresenter.shared.present()
                        } label: {
                            Image(systemName: "list.bullet")
                                .font(.system(size: 18))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)

                        Button {
                            player.cyclePlaybackRate()
                        } label: {
                            Text(playbackRateLabel)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }

                    Spacer(minLength: 8)

                    Button {
                        if premiumManager.isPremium {
                            showCarPlayPremiumInfo = true
                        } else {
                            DummyPaywallPresenter.shared.present()
                        }
                    } label: {
                        Image(systemName: "car.fill")
                            .font(.system(size: 18))
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 12)
            .padding(.bottom, 10)
        }
        .padding(.top, 10)
        .background(.app)
    }

    private func compactControlButton(_ systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 18))
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
        await MainActor.run {
            isLoadingAyahs = true
            loadFailed = false
        }
        do {
            async let surahPayload = QuranAPIClient.shared.fetchSurah(number: surah.number)
            async let translationBundle = ReciterPlaybackTranslation.loadSurahTranslationMaps(surahNumber: surah.number)
            let result = try await surahPayload
            let bundle = await translationBundle
            await MainActor.run {
                ayahs = result.ayahs
                surahMeta = result.surah
                selectedTranslationIds = bundle.selectedTranslationIds
                translationByAyah = bundle.translationByAyah
                isLoadingAyahs = false
            }
        } catch {
            await MainActor.run {
                loadFailed = true
                isLoadingAyahs = false
            }
        }
    }

    /// Re-fetch ayah text for every translation edition currently selected in options (UserDefaults); safe to call anytime selections change.
    private func reloadTranslationsMatchingSelection() async {
        let bundle = await ReciterPlaybackTranslation.loadSurahTranslationMaps(surahNumber: surah.number)
        await MainActor.run {
            selectedTranslationIds = bundle.selectedTranslationIds
            translationByAyah = bundle.translationByAyah
        }
    }
}

/// Pauses follow-scroll during user-driven scrolling. Uses scroll phases on iOS 18+ (no conflict with `scrollTo`); earlier OS uses a drag end hint only.
private struct ReciterScrollUserInteractionPauseModifier: ViewModifier {
    @Binding var pauseUntil: Date

    func body(content: Content) -> some View {
        Group {
            if #available(iOS 18.0, *) {
                content.onScrollPhaseChange { _, newPhase in
                    switch newPhase {
                    case .idle:
                        pauseUntil = Date().addingTimeInterval(0.28)
                    case .interacting, .tracking, .decelerating:
                        pauseUntil = Date().addingTimeInterval(2.5)
                    case .animating:
                        break
                    @unknown default:
                        break
                    }
                }
            } else {
                content
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 30)
                            .onEnded { _ in
                                pauseUntil = Date().addingTimeInterval(0.9)
                            }
                    )
            }
        }
    }
}
