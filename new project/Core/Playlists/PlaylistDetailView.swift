//
//  PlaylistDetailView.swift
//  new project
//
//  Detail screen for a single playlist: name header, "downloaded" badge,
//  Play / Shuffle actions, and an overflow menu in the toolbar.
//

import SwiftUI

struct PlaylistDetailView: View {
    let playlist: Playlist

    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var contentMaxWidth: CGFloat { isIPad ? 700 : .infinity }

    var body: some View {
        ZStack {
            Color.app.ignoresSafeArea()
            ScrollView {
                VStack(spacing: 16) {
                    headerCard
                    actionButtons
                    Spacer(minLength: 24)
                }
                .padding(.horizontal, 16)
                .padding(.top, 16)
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
        .navigationTitle(playlist.name)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button(action: {}) {
                        Label("playlist_action_rename", systemImage: "pencil")
                    }
                    Button(role: .destructive, action: {}) {
                        Label("playlist_action_delete", systemImage: "trash")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel(Text("playlist_more_options_accessibility"))
            }
        }
    }

    private var headerCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(playlist.name)
                .font(.system(size: 32, weight: .bold))
                .foregroundStyle(.primary)

            if playlist.isDownloaded {
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
}
