//
//  PlaylistsViewModel.swift
//  new project
//
//  MVVM view-model for the Playlists feature.
//  Responsible for read/add/delete; persistence is delegated to `PlaylistsStoring`.
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class PlaylistsViewModel: ObservableObject {
    @Published private(set) var playlists: [Playlist] = []

    private let store: PlaylistsStoring

    init(store: PlaylistsStoring = PlaylistsStore.shared) {
        self.store = store
        self.playlists = store.load()
    }

    /// Trims the entered name and creates a new playlist if it's not empty.
    /// Returns `true` when the playlist was added so the view can dismiss its alert.
    @discardableResult
    func addPlaylist(named name: String) -> Bool {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let newPlaylist = Playlist(name: trimmed, isDownloaded: true)
        playlists.insert(newPlaylist, at: 0)
        store.save(playlists)
        return true
    }

    func deletePlaylist(_ playlist: Playlist) {
        playlists.removeAll { $0.id == playlist.id }
        store.save(playlists)
    }

    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        store.save(playlists)
    }
}
