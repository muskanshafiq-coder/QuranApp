//
//  PlaylistDetailView.swift
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist

    @ObservedObject private var playlistsViewModel = PlaylistsViewModel.shared
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.dismiss) private var dismiss

    @State private var showOptionsSheet = false
    @State private var editMode: EditMode = .inactive
    @State private var showRenameAlert = false
    @State private var renameFieldText = ""
    @State private var showDownloadManager = false

    @AppStorage(UserDefaultsManager.Keys.quranPreferredAudioReciterEdition) private var preferredAudioReciterId: String = ""

    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var contentMaxWidth: CGFloat { isIPad ? 700 : .infinity }

    private var resolvedPlaylist: Playlist {
        playlistsViewModel.playlist(withId: playlist.id) ?? playlist
    }

    private var isReordering: Bool { editMode == .active }

    var body: some View {
        ZStack(alignment: .top) {
            Color.app.ignoresSafeArea()
            VStack(spacing: 16) {
                headerCard
                actionButtons
                surahsSection
                Spacer(minLength: 0)
            }
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .frame(maxWidth: contentMaxWidth)
            .frame(maxWidth: .infinity, alignment: .top)
        }
        .navigationTitle(resolvedPlaylist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                if isReordering {
                    Button {
                        withAnimation {
                            editMode = .inactive
                        }
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(selectedThemeColorManager.selectedColor)
                    }
                    .accessibilityLabel(Text("playlist_reorder_done_accessibility"))
                } else {
                    Button {
                        showOptionsSheet = true
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(.primary)
                    }
                    .accessibilityLabel(Text("playlist_more_options_accessibility"))
                }
            }
        }
        .sheet(isPresented: $showOptionsSheet) {
            PlaylistOptionsSheet(
                accentColor: selectedThemeColorManager.selectedColor,
                onReorder: {
                    scheduleAfterSheetDismiss {
                        withAnimation {
                            editMode = .active
                        }
                    }
                },
                onShare: {
                    let playlistId = playlist.id
                    // Keep the options sheet visible; present UIActivityViewController from the topmost VC (the sheet).
                    DispatchQueue.main.async {
                        guard let current = playlistsViewModel.playlist(withId: playlistId) else { return }
                        let text = shareMessage(
                            playlist: current,
                            userDisplayName: authManager.playlistShareDisplayName
                        )
                        ShareHelper.presentShareSheet(items: [text])
                    }
                },
                onRename: {
                    renameFieldText = resolvedPlaylist.name
                    scheduleAfterSheetDismiss {
                        showRenameAlert = true
                    }
                },
                onDelete: {
                    let playlistId = playlist.id
                    scheduleAfterSheetDismiss {
                        playlistsViewModel.deletePlaylist(id: playlistId)
                        dismiss()
                    }
                }
            )
            .presentationDragIndicator(.visible)
        }
        .alert("playlist_rename_alert_title", isPresented: $showRenameAlert) {
            TextField("playlist_rename_placeholder", text: $renameFieldText)
            Button("alert_cancel", role: .cancel, action: {})
            Button("playlist_rename_save") {
                let name = renameFieldText
                if playlistsViewModel.renamePlaylist(id: resolvedPlaylist.id, to: name) {
                    PlaylistSuccessFeedback.presentPlaylistRenamed()
                }
            }
        } message: {
            Text("playlist_rename_alert_message")
        }
        .sheet(isPresented: $showDownloadManager) {
            DownloadManagerSheet()
        }
    }

    private func shareMessage(playlist: Playlist, userDisplayName: String) -> String {
        let link = String(
            format: NSLocalizedString("playlist_share_link_format", comment: ""),
            playlist.id.uuidString
        )
        return String(
            format: NSLocalizedString("playlist_share_body_format", comment: ""),
            playlist.name,
            userDisplayName,
            link
        )
    }

    private func scheduleAfterSheetDismiss(_ action: @escaping () -> Void) {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.35, execute: action)
    }

    private func removeSurah(_ entry: PlaylistSurahEntry) {
        guard let idx = resolvedPlaylist.entries.firstIndex(where: { $0.surahNumber == entry.surahNumber }) else { return }
        playlistsViewModel.removeSurah(at: idx, fromPlaylistId: resolvedPlaylist.id)
    }

    @ViewBuilder
    private func entryRow(_ entry: PlaylistSurahEntry, listPosition: Int) -> some View {
        AudioSurahListRow(
            listPosition: listPosition,
            surahTitleEn: entry.englishLine,
            surahTitleAr: entry.arabicLine.isEmpty ? nil : entry.arabicLine,
            reciterNameEn: entry.reciterNameEn,
            portraitURLString: entry.portraitURLString,
            accentColor: selectedThemeColorManager.selectedColor,
            preferredReciterId: $preferredAudioReciterId,
            navigationReciter: entry.navigationReciter(preferredSlugFallback: preferredAudioReciterId),
            onDownloadTap: { showDownloadManager = true }
        ) {
            Menu {
                Button(role: .destructive) {
                    removeSurah(entry)
                } label: {
                    Label("playlist_remove_surah", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28)
                    .foregroundStyle(selectedThemeColorManager.selectedColor)
            }
            .buttonStyle(.plain)
        }
    }

    private var headerCard: some View {
        HStack(alignment: .center, spacing: 16) {
            VStack(alignment: .leading, spacing: 10) {
                Text(resolvedPlaylist.name)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundStyle(.primary)

                HStack(alignment: .center, spacing: 10) {
                    headerSurahCountLabel
                        .font(.system(size: 17, weight: .regular))
                        .foregroundStyle(.secondary)

                    if resolvedPlaylist.isDownloaded {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .semibold))
                            Text("playlist_downloaded_badge")
                                .font(.system(size: 11, weight: .semibold))
                                .tracking(1)
                        }
                        .foregroundStyle(.secondary)
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            PlaylistDetailHeaderReciterStack(items: headerDistinctReciters)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.card)
        )
    }

    /// Unique reciters in playlist order (for stacked portraits on the header card).
    private var headerDistinctReciters: [PlayerReciterDisplayItem] {
        var seen = Set<String>()
        var items: [PlayerReciterDisplayItem] = []
        for entry in resolvedPlaylist.entries {
            let key = playlistEntryReciterDedupeKey(entry)
            guard seen.insert(key).inserted else { continue }
            items.append(entry.navigationReciter(preferredSlugFallback: preferredAudioReciterId))
        }
        return items
    }

    private func playlistEntryReciterDedupeKey(_ entry: PlaylistSurahEntry) -> String {
        let slug = entry.reciterSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        if !slug.isEmpty { return "slug:\(slug)" }
        let name = entry.reciterNameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        if !name.isEmpty { return "name:\(name)" }
        return "surah:\(entry.surahNumber)"
    }

    private var headerSurahCountLabel: Text {
        let n = resolvedPlaylist.surahCount
        switch n {
        case 0:
            return Text("playlist_surah_count_zero")
        case 1:
            return Text("playlist_surah_count_one")
        default:
            let format = NSLocalizedString("playlist_surah_count_other", comment: "")
            return Text(String(format: format, n))
        }
    }

    private var actionButtons: some View {
        HStack(spacing: 12) {
            playlistActionButton(
                titleKey: "playlist_action_play",
                systemImage: "play.fill",
                action: {}
            )
            playlistActionButton(
                titleKey: "playlist_action_shuffle",
                systemImage: "shuffle",
                action: {}
            )
        }
    }

    private func playlistActionButton(
        titleKey: LocalizedStringKey,
        systemImage: String,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: systemImage)
                    .font(.system(size: 16, weight: .bold))
                Text(titleKey)
                    .font(.system(size: 15, weight: .semibold))
            }
            .foregroundStyle(selectedThemeColorManager.selectedColor)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.card)
            )
        }
    }

    @ViewBuilder
    private var surahsSection: some View {
        if resolvedPlaylist.entries.isEmpty {
            Text("playlist_detail_empty_surahs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.card))
        } else if isReordering {
            List {
                ForEach(Array(resolvedPlaylist.entries.enumerated()), id: \.element.surahNumber) { index, entry in
                    entryRow(entry, listPosition: index + 1)
                        .listRowInsets(EdgeInsets())
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                }
                .onMove { source, destination in
                    playlistsViewModel.moveSurahs(
                        inPlaylistId: resolvedPlaylist.id,
                        from: source,
                        to: destination
                    )
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
        } else {
            ScrollView {
                VStack(spacing: 12) {
                    ForEach(Array(resolvedPlaylist.entries.enumerated()), id: \.element.surahNumber) { index, entry in
                        entryRow(entry, listPosition: index + 1)
                    }
                }
            }
        }
    }
}

// MARK: - Header reciter stack

private struct PlaylistDetailHeaderReciterStack: View {
    let items: [PlayerReciterDisplayItem]
    private let diameter: CGFloat = 44
    private let overlap: CGFloat = 18

    var body: some View {
        let shown = Array(items.prefix(3))
        Group {
            if shown.isEmpty {
                EmptyView()
            } else {
                HStack(spacing: -overlap) {
                    ForEach(Array(shown.enumerated()), id: \.element.id) { index, item in
                        PlaylistDetailHeaderReciterAvatar(item: item, diameter: diameter)
                            .zIndex(Double(index))
                    }
                }
                .accessibilityHidden(true)
            }
        }
    }
}

private struct PlaylistDetailHeaderReciterAvatar: View {
    let item: PlayerReciterDisplayItem
    let diameter: CGFloat

    var body: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: PlayerReciterAvatarPalette.gradient(for: item.id),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            Text(PlayerReciterAvatarPalette.initials(for: item.englishName, idFallback: item.id))
                .font(.system(size: diameter * 0.27, weight: .bold, design: .rounded))
                .foregroundStyle(.white)

            if let url = item.portraitURL {
                CachedRemoteImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: diameter, height: diameter)
                    .clipShape(Circle())
            }
        }
        .frame(width: diameter, height: diameter)
        .overlay {
            Circle()
                .strokeBorder(Color.card, lineWidth: 2)
        }
    }
}