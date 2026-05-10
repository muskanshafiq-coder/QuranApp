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
        if resolvedPlaylist.surahIDs.isEmpty {
            Text("playlist_detail_empty_surahs")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(RoundedRectangle(cornerRadius: 12).fill(Color.card))
        } else {
            List {
                ForEach(resolvedPlaylist.surahIDs, id: \.self) { surahId in
                    Text(
                        String(
                            format: NSLocalizedString("playlist_surah_row_format", comment: ""),
                            surahId
                        )
                    )
                    .listRowBackground(Color.card)
                }
                .onMove { source, destination in
                    playlistsViewModel.moveSurahs(
                        inPlaylistId: resolvedPlaylist.id,
                        from: source,
                        to: destination
                    )
                }
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .environment(\.editMode, $editMode)
        }
    }
}
