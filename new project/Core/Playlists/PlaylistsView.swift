//
//  PlaylistsView.swift
//

import SwiftUI

struct PlaylistsView: View {
    /// How the screen behaves. `.manage` is the default tab usage; `.picker`
    /// turns each row into a selection callback so callers can reuse this UI
    /// inside a sheet (e.g. "Add surah to a playlist").
    enum Mode: Equatable {
        case manage
        case picker
    }

    @ObservedObject private var viewModel = PlaylistsViewModel.shared
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass

    @State private var showAddAlert: Bool = false
    @State private var newPlaylistName: String = ""

    let mode: Mode
    var onSelect: ((Playlist) -> Void)?

    init(mode: Mode = .manage, onSelect: ((Playlist) -> Void)? = nil) {
        self.mode = mode
        self.onSelect = onSelect
    }

    private var isIPad: Bool { horizontalSizeClass == .regular }
    private var contentMaxWidth: CGFloat { isIPad ? 700 : .infinity }

    private var navigationTitleKey: LocalizedStringKey {
        mode == .picker ? "playlist_picker_title" : "playlists_title"
    }

    var body: some View {
        ZStack {
            Color.app.ignoresSafeArea()
            content
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
        }
        .navigationTitle(navigationTitleKey)
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
        let deleteAction: ((IndexSet) -> Void)? = mode == .manage
            ? { offsets in viewModel.deletePlaylists(at: offsets) }
            : nil
        return List {
            ForEach(viewModel.playlists) { playlist in
                playlistRow(for: playlist)
                    .listRowBackground(Color.card)
            }
            .onDelete(perform: deleteAction)
        }
    }

    @ViewBuilder
    private func playlistRow(for playlist: Playlist) -> some View {
        switch mode {
        case .manage:
            NavigationLink {
                PlaylistDetailView(playlist: playlist)
            } label: {
                PlaylistRow(playlist: playlist)
            }
        case .picker:
            Button {
                onSelect?(playlist)
            } label: {
                HStack {
                    PlaylistRow(playlist: playlist)
                    Spacer(minLength: 8)
                    Image(systemName: "chevron.right")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(.tertiary)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
        }
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
