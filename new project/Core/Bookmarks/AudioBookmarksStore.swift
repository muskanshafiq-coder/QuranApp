//
//  AudioBookmarksStore.swift
//

import Foundation

protocol AudioBookmarksStoring {
    func load() -> [AudioSurahBookmark]
    func save(_ items: [AudioSurahBookmark])
}

final class AudioBookmarksStore: AudioBookmarksStoring {
    static let shared = AudioBookmarksStore()

    private let storage: UserDefaultsManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storage: UserDefaultsManager = .shared) {
        self.storage = storage
    }

    func load() -> [AudioSurahBookmark] {
        guard let data = storage.audioBookmarksData(),
              let items = try? decoder.decode([AudioSurahBookmark].self, from: data) else {
            return []
        }
        return items
    }

    func save(_ items: [AudioSurahBookmark]) {
        guard let data = try? encoder.encode(items) else { return }
        storage.saveAudioBookmarksData(data)
    }
}
