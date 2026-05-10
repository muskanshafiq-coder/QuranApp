//
//  PlaylistsViewModel.swift
//

import Foundation
import Combine
import SwiftUI

@MainActor
final class PlaylistsViewModel: ObservableObject {
    /// Shared instance so `PlayerView` and `PlaylistsView` show the same list and counts.
    static let shared = PlaylistsViewModel()

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
        let newPlaylist = Playlist(name: trimmed, entries: [], isDownloaded: true)
        playlists.insert(newPlaylist, at: 0)
        store.save(playlists)
        return true
    }

    func deletePlaylist(_ playlist: Playlist) {
        deletePlaylist(id: playlist.id)
    }

    func deletePlaylist(id: UUID) {
        playlists.removeAll { $0.id == id }
        store.save(playlists)
    }

    func deletePlaylists(at offsets: IndexSet) {
        playlists.remove(atOffsets: offsets)
        store.save(playlists)
    }

    /// Returns the latest model for `id`, if it is still in the list.
    func playlist(withId id: UUID) -> Playlist? {
        playlists.first { $0.id == id }
    }

    @discardableResult
    func renamePlaylist(id: UUID, to newName: String) -> Bool {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, let index = playlists.firstIndex(where: { $0.id == id }) else { return false }
        playlists[index].name = trimmed
        store.save(playlists)
        return true
    }

    func moveSurahs(inPlaylistId id: UUID, from source: IndexSet, to destination: Int) {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return }
        playlists[index].entries.move(fromOffsets: source, toOffset: destination)
        store.save(playlists)
    }

    /// Appends an entry if that surah number is not already in the playlist.
    @discardableResult
    func addSurahEntry(_ entry: PlaylistSurahEntry, toPlaylistId id: UUID) -> Bool {
        guard let index = playlists.firstIndex(where: { $0.id == id }) else { return false }
        if playlists[index].entries.contains(where: { $0.surahNumber == entry.surahNumber }) { return false }
        playlists[index].entries.append(entry)
        store.save(playlists)
        return true
    }

    func removeSurah(at index: Int, fromPlaylistId id: UUID) {
        guard let pIndex = playlists.firstIndex(where: { $0.id == id }) else { return }
        guard playlists[pIndex].entries.indices.contains(index) else { return }
        playlists[pIndex].entries.remove(at: index)
        store.save(playlists)
    }
}
