//
//  PlayerReciterSurahListView.swift
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
    @ObservedObject private var favoritesViewModel = FavoriteRecitersViewModel.shared
    @ObservedObject private var playlistsViewModel = PlaylistsViewModel.shared
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared

    let reciter: PlayerReciterDisplayItem
    @Binding var preferredReciterId: String
    let segments: [PlayerReciterSegment]

    @State private var surahSearch = ""
    @State private var bioExpanded = false
    @State private var detail: IslamicCloudReciterDetailPayload?
    @State private var isLoadingDetail = true
    @State private var detailLoadFailed = false
    @State private var activeSlug: String
    @ObservedObject private var playbackPopupCoordinator = ReciterPlaybackPopupCoordinator.shared
    @State private var surahOptionsRow: PlayerSurahRowModel?
    @State private var pendingPlaylistRow: PlayerSurahRowModel?
    @State private var showDownloadManager = false
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

    /// Matches `AudioSurahBookmark.reciterSlug` saved in `addAudioBookmark(for:)`.
    private var bookmarkReciterSlug: String {
        let s = detail?.slug.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        return s.isEmpty ? reciter.id : s
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

                ReciterProfileCard(
                    displayTitle: displayTitle,
                    portraitImageURL: portraitImageURL,
                    reciterId: reciter.id,
                    bioText: bioText,
                    recordedCount: recordedCount,
                    isLoadingDetail: isLoadingDetail,
                    bioExpanded: $bioExpanded
                )

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
                reciterOptionsMenu
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
        .sheet(item: $surahOptionsRow) { row in
            SurahOptionsFlowSheet(
                surahRow: row,
                reciterSlug: bookmarkReciterSlug,
                accentColor: selectedThemeColorManager.selectedColor,
                onAddToPlaylistTapped: { handleAddToPlaylistTapped(for: row) },
                onAddBookmark: { addAudioBookmark(for: row) },
                onPlayNext: { playNextSurah(for: row) },
                onShare: { shareSurah(row: row) }
            )
        }
        .sheet(item: $pendingPlaylistRow) { row in
            PlaylistPickerSheet { playlist in
                addSurahToPlaylist(row: row, playlist: playlist)
            }
        }
        .sheet(isPresented: $showDownloadManager) {
            DownloadManagerSheet()
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
        isLoadingDetail = true
        detailLoadFailed = false

        let success = await ReciterRepository.loadReciterDetail(slug: slug) { fresh in
            // Drop late results if the user switched segments mid-flight.
            guard slug == activeSlug else { return }
            detail = fresh
            isLoadingDetail = false
        }

        guard slug == activeSlug else { return }
        isLoadingDetail = false
        if !success {
            detail = nil
            detailLoadFailed = true
        }
    }

    // MARK: - Options menu (heart / link / download / share)

    /// Whether the currently displayed reciter is in the user's favorites.
    /// Reads from the shared `FavoriteRecitersViewModel` so toggles update
    /// automatically across screens.
    private var isFavorite: Bool {
        favoritesViewModel.isFavorite(id: reciter.id)
    }

    @ViewBuilder
    private var reciterOptionsMenu: some View {
        Menu {
            Button {
                ReciterPlayerActions.toggleFavorite(reciter: reciter, favorites: favoritesViewModel)
            } label: {
                Label(
                    isFavorite ? "reciter_menu_remove_favorite" : "reciter_menu_add_favorite",
                    systemImage: isFavorite ? "heart.fill" : "heart"
                )
            }

            Button {
                ReciterPlayerActions.openFollow(fromDetailURL: detail?.url, deepLinkSlug: activeSlug)
            } label: {
                Label("reciter_menu_follow", systemImage: "link")
            }

            Button {
                showDownloadManager = true
            } label: {
                Label("reciter_menu_download_manager", systemImage: "arrow.down.to.line")
            }

            Button {
                ReciterPlayerActions.shareReciterProfile(
                    displayTitle: displayTitle,
                    fallbackEnglishName: reciter.englishName,
                    deepLinkSlug: reciter.id
                )
            } label: {
                Label("reciter_menu_share", systemImage: "square.and.arrow.up")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 22, weight: .regular))
        }
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
                startPlayback(detail: d, surah: s)
            }
            primaryPillButton(
                title: "player_reciter_shuffle",
                systemImage: "shuffle",
                enabled: hasPlayableSurah && !isLoadingDetail
            ) {
                guard let d = detail, let s = randomPlayableSurah() else { return }
                startPlayback(detail: d, surah: s)
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
        SurahListingRow(
            number: row.number,
            englishLine: row.englishLine,
            arabicLine: row.arabicLine,
            accentColor: selectedThemeColorManager.selectedColor,
            onTapContent: {
                guard let d = detail,
                      let dto = d.surahs.first(where: { $0.number == row.number }),
                      row.audioURL != nil
                else { return }
                startPlayback(detail: d, surah: dto)
            },
            onDownload: {},
            onMore: { surahOptionsRow = row }
        )
    }

    // MARK: - Surah row sheet actions

    /// Bridges the surah-options sheet → playlist picker transition.
    /// We have to wait for the first sheet's dismiss animation to finish
    /// before presenting the second one (SwiftUI can't drive two `.sheet`
    /// modifiers on the same view simultaneously).
    private func handleAddToPlaylistTapped(for row: PlayerSurahRowModel) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            pendingPlaylistRow = row
        }
    }

    private func addSurahToPlaylist(row: PlayerSurahRowModel, playlist: Playlist) {
        guard let d = detail else { return }
        let nameEn = d.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        let portrait = d.image?.trimmingCharacters(in: .whitespacesAndNewlines)
        let entry = PlaylistSurahEntry(
            surahNumber: row.number,
            reciterSlug: bookmarkReciterSlug,
            englishLine: row.englishLine,
            arabicLine: row.arabicLine,
            reciterNameEn: nameEn.isEmpty ? reciter.englishName : nameEn,
            portraitURLString: portrait.flatMap { $0.isEmpty ? nil : $0 }
        )
        if playlistsViewModel.addSurahEntry(entry, toPlaylistId: playlist.id) {
            SurahRowActionFeedback.presentAddedToPlaylist(playlistName: playlist.name)
        } else {
            SurahRowActionFeedback.presentAlreadyInPlaylist(playlistName: playlist.name)
        }
    }

    private func addAudioBookmark(for row: PlayerSurahRowModel) {
        guard let d = detail else { return }
        let nameEn = d.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        let portrait = d.image?.trimmingCharacters(in: .whitespacesAndNewlines)
        let dto = d.surahs.first(where: { $0.number == row.number })
        let ar = dto?.nameAr?.trimmingCharacters(in: .whitespacesAndNewlines)
        let bookmark = AudioSurahBookmark(
            reciterSlug: bookmarkReciterSlug,
            reciterNameEn: nameEn.isEmpty ? reciter.englishName : nameEn,
            portraitURLString: portrait.flatMap { $0.isEmpty ? nil : $0 },
            surahNumber: row.number,
            surahTitleEn: row.englishLine,
            surahTitleAr: ar.flatMap { $0.isEmpty ? nil : $0 }
        )
        audioBookmarksViewModel.add(bookmark)
        SurahRowActionFeedback.presentAddedToBookmark()
    }

    private func playNextSurah(for row: PlayerSurahRowModel) {
        guard let d = detail,
              let dto = d.surahs.first(where: { $0.number == row.number }),
              row.audioURL != nil
        else { return }
        let session = ReciterPlaybackSession(detail: d, surah: dto)
        let queue = ReciterPlaybackQueueCoordinator.shared
        if playbackPopupCoordinator.isPopupActive {
            queue.enqueuePlayNext(session)
        } else {
            queue.cancelQueued()
            ReciterPlaybackPopupCoordinator.shared.present(session: session)
        }
        SurahRowActionFeedback.presentAddedToQueue()
    }

    /// Single entry point for "start playing this surah now" — cancels any
    /// queued auto-advance and routes through the popup coordinator.
    private func startPlayback(
        detail: IslamicCloudReciterDetailPayload,
        surah: IslamicCloudReciterSurahItemDTO
    ) {
        ReciterPlaybackQueueCoordinator.shared.cancelQueued()
        let session = ReciterPlaybackSession(detail: detail, surah: surah)
        ReciterPlaybackPopupCoordinator.shared.present(session: session)
    }

    private func shareSurah(row: PlayerSurahRowModel) {
        ReciterPlayerActions.shareSurahRow(
            reciterDisplayTitle: displayTitle,
            fallbackReciterEnglishName: reciter.englishName,
            deepLinkSlug: reciter.id,
            surahNumber: row.number,
            surahEnglishLine: row.englishLine
        )
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
