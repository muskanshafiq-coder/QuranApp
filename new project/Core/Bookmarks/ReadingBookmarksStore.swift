//
//  ReadingBookmarksStore.swift
//

import Foundation

protocol ReadingBookmarksStoring {
    func load() -> [ReadingSurahBookmark]
    func save(_ items: [ReadingSurahBookmark])
}

final class ReadingBookmarksStore: ReadingBookmarksStoring {
    static let shared = ReadingBookmarksStore()

    private let storage: UserDefaultsManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storage: UserDefaultsManager = .shared) {
        self.storage = storage
    }

    func load() -> [ReadingSurahBookmark] {
        guard let data = storage.readingBookmarksData(),
              let items = try? decoder.decode([ReadingSurahBookmark].self, from: data) else {
            return []
        }
        return items
    }

    func save(_ items: [ReadingSurahBookmark]) {
        guard let data = try? encoder.encode(items) else { return }
        storage.saveReadingBookmarksData(data)
    }
}
