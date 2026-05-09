//
//  PlaylistsStore.swift
//  new project
//
//  Persists user playlists in UserDefaults as JSON.
//  Keeps persistence concerns out of the view-model (Single Responsibility).
//

import Foundation

protocol PlaylistsStoring {
    func load() -> [Playlist]
    func save(_ playlists: [Playlist])
}

final class PlaylistsStore: PlaylistsStoring {
    static let shared = PlaylistsStore()

    private let storage: UserDefaultsManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storage: UserDefaultsManager = .shared) {
        self.storage = storage
    }

    func load() -> [Playlist] {
        guard let data = storage.playlistsData(),
              let playlists = try? decoder.decode([Playlist].self, from: data) else {
            return []
        }
        return playlists
    }

    func save(_ playlists: [Playlist]) {
        guard let data = try? encoder.encode(playlists) else { return }
        storage.savePlaylistsData(data)
    }
}
