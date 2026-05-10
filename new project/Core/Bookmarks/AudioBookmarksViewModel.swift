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

    /// Inserts at the top; replaces an existing bookmark for the same reciter + surah.
    func add(_ bookmark: AudioSurahBookmark) {
        bookmarks.removeAll {
            $0.reciterSlug == bookmark.reciterSlug && $0.surahNumber == bookmark.surahNumber
        }
        bookmarks.insert(bookmark, at: 0)
        store.save(bookmarks)
    }

    func remove(id: UUID) {
        bookmarks.removeAll { $0.id == id }
        store.save(bookmarks)
    }
}
