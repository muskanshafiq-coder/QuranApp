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
    @State private var playbackSession: ReciterPlaybackSession?

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
        .fullScreenCover(item: $playbackSession) { session in
            ReciterSurahNowPlayingView(
                detail: session.detail,
                surah: session.surah,
                onDismiss: { playbackSession = nil },
                onFinishedCurrentTrack: {
                    if let next = ReciterPlaybackQueueCoordinator.shared.dequeueNext() {
                        playbackSession = next
                    }
                }
            )
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

    private func play(entry: PlaylistSurahEntry) {
        let stored = entry.reciterSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallback = preferredAudioReciterId.trimmingCharacters(in: .whitespacesAndNewlines)
        let slug = stored.isEmpty ? fallback : stored
        guard !slug.isEmpty else { return }
        Task {
            var latest: IslamicCloudReciterDetailPayload?
            _ = await ReciterRepository.loadReciterDetail(slug: slug) { d in
                latest = d
            }
            guard let detail = latest,
                  let dto = detail.surahs.first(where: { $0.number == entry.surahNumber })
            else { return }
            let audio = dto.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            guard !audio.isEmpty else { return }
            await MainActor.run {
                ReciterPlaybackQueueCoordinator.shared.cancelQueued()
                playbackSession = ReciterPlaybackSession(detail: detail, surah: dto)
            }
        }
    }

    private func removeSurah(_ entry: PlaylistSurahEntry) {
        guard let idx = resolvedPlaylist.entries.firstIndex(where: { $0.surahNumber == entry.surahNumber }) else { return }
        playlistsViewModel.removeSurah(at: idx, fromPlaylistId: resolvedPlaylist.id)
    }

    @ViewBuilder
    private func entryRow(_ entry: PlaylistSurahEntry) -> some View {
        SurahListingRow(
            number: entry.surahNumber,
            englishLine: entry.englishLine,
            arabicLine: entry.arabicLine,
            accentColor: selectedThemeColorManager.selectedColor,
            onTapContent: { play(entry: entry) },
            onDownload: {},
            moreAccessory: {
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
                        .foregroundColor(selectedThemeColorManager.selectedColor)
                }
            }
        )
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(resolvedPlaylist.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)

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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.card)
        )
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
                ForEach(resolvedPlaylist.entries, id: \.surahNumber) { entry in
                    entryRow(entry)
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
            .background(Color.card)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
        } else {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(Array(resolvedPlaylist.entries.enumerated()), id: \.element.surahNumber) { index, entry in
                        entryRow(entry)
                        if index < resolvedPlaylist.entries.count - 1 {
                            Divider()
                                .background(Color(.separator))
                                .padding(.horizontal, 14)
                        }
                    }
                }
                .padding(.vertical, 6)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.card)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            }
        }
    }
}