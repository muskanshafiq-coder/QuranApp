//
//  ReciterSurahNowPlayingView.swift
//

import SwiftUI
import AVFoundation

struct ReciterSurahNowPlayingView: View {
    let detail: IslamicCloudReciterDetailPayload
    let surah: IslamicCloudReciterSurahItemDTO
    let onDismiss: () -> Void
    /// Invoked on the main queue when the current surah audio reaches the end
    /// (used by the parent to advance the "Play Next" queue).
    let onFinishedCurrentTrack: (() -> Void)?

    init(
        detail: IslamicCloudReciterDetailPayload,
        surah: IslamicCloudReciterSurahItemDTO,
        onDismiss: @escaping () -> Void,
        onFinishedCurrentTrack: (() -> Void)? = nil
    ) {
        self.detail = detail
        self.surah = surah
        self.onDismiss = onDismiss
        self.onFinishedCurrentTrack = onFinishedCurrentTrack
    }

    @StateObject private var player = ReciterSurahAudioPlayer()
    @State private var ayahs: [AyahItem] = []
    @State private var surahMeta: SurahItem?
    @State private var translationByAyah: [Int: String] = [:]
    @State private var loadFailed = false
    @State private var isLoadingAyahs = true
    @State private var shuffleEnabled = false
    @State private var repeatMode: Int = 0

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
        ZStack {
            Color.black.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar

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

                                LazyVStack(alignment: .leading, spacing: 22) {
                                    ForEach(ayahs) { ayah in
                                        ReciterPlayerAyahRow(
                                            ayah: ayah,
                                            translation: translationByAyah[ayah.numberInSurah],
                                            isActive: ayah.numberInSurah == activeAyahNumber,
                                            onSeekToAyah: {
                                                player.seekToEstimatedStartOfAyah(
                                                    ayahNumber: ayah.numberInSurah,
                                                    ayahCount: ayahCountForMapping
                                                )
                                            }
                                        )
                                        .id(ayah.numberInSurah)
                                    }
                                }
                                .padding(.horizontal, 16)
                            }
                            .padding(.bottom, 12)
                        }
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

                bottomChrome
            }
        }
        .preferredColorScheme(.dark)
        .task {
            await loadAyahContent()
        }
        .onAppear {
            player.onDidPlayToEnd = onFinishedCurrentTrack
            if let url = surah.audio.flatMap({ URL(string: $0) }) {
                player.load(url: url)
            }
        }
        .onDisappear {
            player.onDidPlayToEnd = nil
            player.stop()
        }
    }

    // MARK: - Header (reference: red title, istiʿādh, star + more)

    private var headerBar: some View {
        ZStack {
            HStack {
                Button {
                    onDismiss()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)

                Spacer(minLength: 0)

                HStack(spacing: 16) {
                    Image(systemName: "star.fill")
                        .font(.system(size: 18, weight: .regular))

                    Menu {
                        Button("general_share") {}
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 18, weight: .semibold))
                            .frame(width: 36, height: 36)
                    }
                }
            }
            .padding(.horizontal, 4)

            Text(arabicHeaderTitle)
                .font(.system(size: 20, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.55)
                .padding(.horizontal, 72)
        }
        .padding(.top, 4)
        .padding(.bottom, 8)
    }

    private var istiadhBlock: some View {
        Text(Self.istiadhArabic)
            .font(.system(size: 16, weight: .regular))
            .foregroundColor(.white.opacity(0.92))
            .multilineTextAlignment(.trailing)
            .frame(maxWidth: .infinity, alignment: .trailing)
            .environment(\.layoutDirection, .rightToLeft)
    }

    private static let istiadhArabic =
        "أَعُوذُ بِاللَّهِ مِنَ الشَّيْطَانِ الرَّجِيمِ"

    // MARK: - Bottom chrome (reference layout)

    private var bottomChrome: some View {
        let accentUI = UIColor(.accentColor)

        return VStack(spacing: 12) {
            VStack(spacing: 6) {
                ReciterSmallThumbSlider(
                    value: Binding(
                        get: { player.currentTime },
                        set: { player.seek(to: $0) }
                    ),
                    range: 0 ... max(player.duration, 0.1),
                    tint: accentUI
                )
                .frame(height: 28)

                HStack {
                    Text(formatTime(player.currentTime))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                    Spacer()
                    Text(formatTime(player.duration))
                        .font(.system(size: 12, weight: .medium, design: .monospaced))
                        .foregroundColor(.white.opacity(0.55))
                }
            }
            .padding(.horizontal, 16)

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
                        .symbolRenderingMode(.palette)
                }
                .frame(width: 44)
            }
            .padding(.horizontal, 6)

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
                    ReciterAirPlayRoutePicker(tint: UIColor(.black))
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
            await MainActor.run {
                ayahs = result.ayahs
                surahMeta = result.surah
                translationByAyah = map
                isLoadingAyahs = false
            }
        } catch {
            await MainActor.run {
                loadFailed = true
                isLoadingAyahs = false
            }
        }
    }
}
