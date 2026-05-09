//
//  PlayerReciterSurahListView.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import SwiftUI

enum PlayerReciterSegment: String, CaseIterable, Identifiable, Hashable {
    case duaa = "duaa"
    case tilawats = "tilawates-and-rouqia"

    var id: String { rawValue }
    var slug: String { rawValue }

    var localizedTitleKey: LocalizedStringKey {
        switch self {
        case .duaa:     return "reciters_segment_duaa"
        case .tilawats: return "reciters_segment_tilawats"
        }
    }
}

struct PlayerReciterSurahListView: View {
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    let reciter: PlayerReciterDisplayItem
    @Binding var preferredReciterId: String
    let segments: [PlayerReciterSegment]

    @State private var surahSearch = ""
    @State private var bioExpanded = false
    @State private var detail: IslamicCloudReciterDetailPayload?
    @State private var isLoadingDetail = true
    @State private var detailLoadFailed = false
    @State private var playbackSession: ReciterPlaybackSession?
    @State private var activeSlug: String

    private let horizontalInset: CGFloat = 16
    private let rowHPadding: CGFloat = 14

    init(
        reciter: PlayerReciterDisplayItem,
        preferredReciterId: Binding<String>,
        segments: [PlayerReciterSegment] = []
    ) {
        self.reciter = reciter
        self._preferredReciterId = preferredReciterId
        self.segments = segments
        self._activeSlug = State(initialValue: segments.first?.slug ?? reciter.id)
    }

    private var displayTitle: String {
        let t = detail?.nameEn.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return t.isEmpty ? reciter.englishName : t
    }

    private var portraitImageURL: URL? {
        if let s = detail?.image?.trimmingCharacters(in: .whitespacesAndNewlines), !s.isEmpty,
           let u = URL(string: s) { return u }
        return reciter.portraitURL
    }

    private var recordedCount: Int {
        if let s = detail?.surahCount?.trimmingCharacters(in: .whitespacesAndNewlines), let n = Int(s) {
            return n
        }
        let n = detail?.surahs.count ?? 0
        return n > 0 ? n : 114
    }

    private var bioText: String {
        detail?.bio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private var filteredSurahs: [PlayerSurahRowModel] {
        let q = surahSearch.trimmingCharacters(in: .whitespacesAndNewlines)
        let base = (detail?.surahs ?? []).map { PlayerSurahRowModel(surah: $0) }
        guard !q.isEmpty else { return base }
        return base.filter {
            String($0.number).contains(q)
                || $0.englishLine.localizedCaseInsensitiveContains(q)
                || $0.arabicLine.contains(q)
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                if detailLoadFailed {
                    loadFailureBanner
                }

                profileGlassCard

                playShuffleRow

                if isLoadingDetail {
                    surahListLoadingCard
                } else {
                    surahListGlassCard
                }
            }
            .padding(.horizontal, horizontalInset)
            .padding(.top, 8)
            .padding(.bottom, 28)
        }
        .background(Color.app.ignoresSafeArea())
        .navigationTitle(segments.isEmpty ? displayTitle : "")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if !segments.isEmpty {
                ToolbarItem(placement: .principal) {
                    segmentPicker
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 22, weight: .regular))
                }
            }
        }
        .pinnedSearchable(text: $surahSearch, promptKey: "search_surah")
        .keepNavigationBarVisibleDuringSearch()
        .onAppear {
            if segments.isEmpty {
                preferredReciterId = reciter.id
            }
        }
        .task(id: activeSlug) {
            await loadReciterDetail()
        }
        .onChange(of: activeSlug) { _ in
            surahSearch = ""
            bioExpanded = false
        }
        .fullScreenCover(item: $playbackSession) { session in
            ReciterSurahNowPlayingView(
                detail: session.detail,
                surah: session.surah,
                onDismiss: { playbackSession = nil }
            )
        }
    }

    private var hasPlayableSurah: Bool {
        guard let d = detail else { return false }
        return d.surahs.contains { surah in
            let s = surah.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            return !s.isEmpty
        }
    }

    private func firstPlayableSurah() -> IslamicCloudReciterSurahItemDTO? {
        guard let d = detail else { return nil }
        return d.surahs
            .filter { !($0.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty }
            .sorted { $0.number < $1.number }
            .first
    }

    private func randomPlayableSurah() -> IslamicCloudReciterSurahItemDTO? {
        guard let d = detail else { return nil }
        let list = d.surahs.filter { !($0.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty }
        return list.randomElement()
    }

    private var segmentPicker: some View {
        let selection = Binding(
            get: { segments.first { $0.slug == activeSlug } ?? .duaa },
            set: { activeSlug = $0.slug }
        )
        return Picker(selection: selection) {
            ForEach(segments) { segment in
                Text(segment.localizedTitleKey).tag(segment)
            }
        } label: {
            Text("reciters_segment_picker_label")
        }
        .pickerStyle(.segmented)
        .labelsHidden()
    }

    private var loadFailureBanner: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("error")
                .font(.subheadline)
                .foregroundColor(.secondary)
            Button("retry") {
                Task { await loadReciterDetail() }
            }
            .font(.system(size: 14, weight: .semibold))
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }

    private func loadReciterDetail() async {
        let slug = activeSlug
        await MainActor.run {
            isLoadingDetail = true
            detailLoadFailed = false
        }
        do {
            let d = try await IslamicCloudAPIClient.shared.fetchReciterDetail(slug: slug)
            await MainActor.run {
                detail = d
                isLoadingDetail = false
            }
        } catch {
            await MainActor.run {
                detail = nil
                isLoadingDetail = false
                detailLoadFailed = true
            }
        }
    }

    // MARK: - Profile card

    private var profileGlassCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                portrait
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    Text(String(format: "player_reciter_recorded_count", recordedCount))
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 18) {
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("player_reciter_all_download")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal,8)
                    .padding(.vertical,4)
                    .background(selectedThemeColorManager.selectedColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "film")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("player_reciter_audio_sync")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }

            bioBlock
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var portrait: some View {
        if let url = portraitImageURL {
            AsyncImage(url: url) { phase in
                if case .success(let img) = phase {
                    img.resizable().aspectRatio(contentMode: .fill)
                } else {
                    portraitPlaceholder
                }
            }
            .clipShape(Circle())
        } else {
            portraitPlaceholder
        }
    }

    private var portraitPlaceholder: some View {
        Circle()
            .fill(LinearGradient(
                colors: PlayerReciterAvatarPalette.gradient(for: reciter.id),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay {
                Text(PlayerReciterAvatarPalette.initials(for: displayTitle))
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
    }

    @ViewBuilder
    private var bioBlock: some View {
        if isLoadingDetail || bioText.isEmpty {
            EmptyView()
        } else {
            bioTextBlock(full: bioText)
        }
    }

    private func bioTextBlock(full: String) -> some View {
        let shortLimit = 120
        let needsMore = full.count > shortLimit
        return VStack(alignment: .leading, spacing: 6) {
            if bioExpanded || !needsMore {
                Text(full)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if needsMore {
                    bioToggleButton(
                        titleKey: "player_reciter_bio_less",
                        expand: false
                    )
                }
            } else {
                Text(String(full.prefix(shortLimit)) + "…")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                bioToggleButton(
                    titleKey: "player_reciter_bio_more",
                    expand: true
                )
            }
        }
    }

    private func bioToggleButton(titleKey: LocalizedStringKey, expand: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { bioExpanded = expand }
        } label: {
            Text(titleKey)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedThemeColorManager.selectedColor)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Play / Shuffle

    private var playShuffleRow: some View {
        HStack(spacing: 12) {
            primaryPillButton(
                title: "player_reciter_play",
                systemImage: "play.fill",
                enabled: hasPlayableSurah && !isLoadingDetail
            ) {
                guard let d = detail, let s = firstPlayableSurah() else { return }
                playbackSession = ReciterPlaybackSession(detail: d, surah: s)
            }
            primaryPillButton(
                title: "player_reciter_shuffle",
                systemImage: "shuffle",
                enabled: hasPlayableSurah && !isLoadingDetail
            ) {
                guard let d = detail, let s = randomPlayableSurah() else { return }
                playbackSession = ReciterPlaybackSession(detail: d, surah: s)
            }
        }
    }

    private func primaryPillButton(title: LocalizedStringKey, systemImage: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedThemeColorManager.selectedColor)
                Text(title)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(selectedThemeColorManager.selectedColor)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 14)
            .background(.card)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .opacity(enabled ? 1 : 0.45)
        }
        .buttonStyle(.plain)
        .disabled(!enabled)
    }

    // MARK: - Surah list

    private var surahListLoadingCard: some View {
        HStack {
            Spacer()
            ProgressView()
            Spacer()
        }
        .padding(.vertical, 40)
        .frame(maxWidth: .infinity)
        .background(playerGlassBackground(cornerRadius: 20))
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    private var surahListGlassCard: some View {
        Group {
            if filteredSurahs.isEmpty {
                Text("player_reciter_surahs_empty")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 28)
                    .background(.card)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            } else {
                VStack(spacing: 0) {
                    ForEach(Array(filteredSurahs.enumerated()), id: \.element.id) { index, row in
                        surahRow(row)
                        if index < filteredSurahs.count - 1 {
                            Divider()
                                .background(Color(.separator))
                                .padding(.horizontal, rowHPadding)
                        }
                    }
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }

    private func surahRow(_ row: PlayerSurahRowModel) -> some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(row.number)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(row.englishLine)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !row.arabicLine.isEmpty {
                    Text(row.arabicLine)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .contentShape(Rectangle())
            .onTapGesture {
                guard let d = detail,
                      let dto = d.surahs.first(where: { $0.number == row.number }),
                      row.audioURL != nil
                else { return }
                playbackSession = ReciterPlaybackSession(detail: d, surah: dto)
            }

            Button {} label: {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(selectedThemeColorManager.selectedColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)

            Button {} label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28)
                    .foregroundColor(selectedThemeColorManager.selectedColor)

            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, rowHPadding)
        .padding(.vertical, 12)
    }

    // MARK: - Glass background

    private func playerGlassBackground(cornerRadius: CGFloat) -> some View {
        ZStack {
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(Color.primary.opacity(0.06))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .fill(.ultraThinMaterial.opacity(0.65))
            RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                .stroke(Color.primary.opacity(0.10), lineWidth: 1)
        }
    }
}
