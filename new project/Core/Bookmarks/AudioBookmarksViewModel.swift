//
//  AudioBookmarksViewModel.swift
//

import Foundation
import Combine
@MainActor
final class AudioBookmarksViewModel: ObservableObject {
    static let shared = AudioBookmarksViewModel()

    @Published private(set) var bookmarks: [AudioSurahBookmark] = []

    private let store: AudioBookmarksStoring

    init(store: AudioBookmarksStoring = AudioBookmarksStore.shared) {
        self.store = store
        self.bookmarks = store.load()
    }

    /// Syncs from persistent storage (e.g. tab became visible again).
    func reloadFromStore() {
        bookmarks = store.load()
    }

    /// Inserts at the top; replaces an existing bookmark for the same reciter + surah.
    func add(_ bookmark: AudioSurahBookmark) {
        var updated = bookmarks
        updated.removeAll {
            $0.reciterSlug == bookmark.reciterSlug && $0.surahNumber == bookmark.surahNumber
        }
        updated.insert(bookmark, at: 0)
        bookmarks = updated
        store.save(bookmarks)
    }

    func remove(id: UUID) {
        bookmarks = bookmarks.filter { $0.id != id }
        store.save(bookmarks)
    }
}
