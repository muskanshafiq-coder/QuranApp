//
//  PlaylistsView.swift
//  new project
//
//  Lists user-created playlists. Supports empty state, swipe-to-delete,
//  and an alert-based "create playlist" flow.
//

import SwiftUI

struct PlaylistsView: View {
    @ObservedObject private var viewModel = PlaylistsViewModel.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showAddAlert: Bool = false
    @State private var newPlaylistName: String = ""

    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var contentMaxWidth: CGFloat { isIPad ? 700 : .infinity }

    var body: some View {
        ZStack {
            Color.app.ignoresSafeArea()
            content
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle("playlists_title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button(action: presentAddAlert) {
                    Image(systemName: "plus")
                        .font(.system(size: 16, weight: .semibold))
                }
                .accessibilityLabel(Text("playlist_add_button_accessibility"))
            }
        }
        .alert("playlist_alert_title", isPresented: $showAddAlert) {
            TextField("playlist_alert_placeholder", text: $newPlaylistName)
            Button("alert_cancel", role: .cancel, action: cancelAdd)
            Button("playlist_alert_add", action: confirmAdd)
        } message: {
            Text("playlist_alert_message")
        }
    }

    @ViewBuilder
    private var content: some View {
        if viewModel.playlists.isEmpty {
            emptyState
        } else {
            playlistList
        }
    }

    private var emptyState: some View {
        VStack(spacing: 8) {
            Spacer()
            Text("playlists_empty_title")
                .font(.system(size: 28, weight: .bold))
                .foregroundStyle(.secondary)
            Text("playlists_empty_subtitle")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var playlistList: some View {
        List {
            ForEach(viewModel.playlists) { playlist in
                NavigationLink {
                    PlaylistDetailView(playlist: playlist)
                } label: {
                    PlaylistRow(playlist: playlist)
                }
                .listRowBackground(Color.card)
            }
            .onDelete(perform: viewModel.deletePlaylists)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
    }

    private func presentAddAlert() {
        newPlaylistName = ""
        showAddAlert = true
    }

    private func confirmAdd() {
        let name = newPlaylistName
        newPlaylistName = ""
        if viewModel.addPlaylist(named: name) {
            PlaylistSuccessFeedback.presentPlaylistCreated()
        }
    }

    private func cancelAdd() {
        newPlaylistName = ""
    }
}

private struct PlaylistRow: View {
    let playlist: Playlist

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(playlist.name)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(.primary)
            Text(surahCountText)
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .padding(.vertical, 4)
    }

    private var surahCountText: LocalizedStringKey {
        // Uses the .stringsdict-style key when count > 1; matches the "0 surah" / "1 surah" wording in the design.
        switch playlist.surahCount {
        case 0: return "playlist_surah_count_zero"
        case 1: return "playlist_surah_count_one"
        default: return LocalizedStringKey(String(format: NSLocalizedString("playlist_surah_count_other", comment: ""), playlist.surahCount))
        }
    }
}
