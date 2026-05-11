//
//  ReadingBookmarksViewModel.swift
//

import Foundation
import Combine

@MainActor
final class ReadingBookmarksViewModel: ObservableObject {
    static let shared = ReadingBookmarksViewModel()

    @Published private(set) var bookmarks: [ReadingSurahBookmark] = []

    private let store: ReadingBookmarksStoring

    init(store: ReadingBookmarksStoring = ReadingBookmarksStore.shared) {
        self.store = store
        self.bookmarks = store.load()
    }

    func reloadFromStore() {
        bookmarks = store.load()
    }

    /// Inserts at the top. Replaces an existing bookmark for the same surah + ayah.
    func add(_ bookmark: ReadingSurahBookmark) {
        var updated = bookmarks
        updated.removeAll {
            $0.surahNumber == bookmark.surahNumber && $0.ayahNumber == bookmark.ayahNumber
        }
        updated.insert(bookmark, at: 0)
        bookmarks = updated
        store.save(bookmarks)
    }

    func remove(id: UUID) {
        bookmarks = bookmarks.filter { $0.id != id }
        store.save(bookmarks)
    }

    func containsBookmark(surahNumber: Int, ayahNumber: Int) -> Bool {
        bookmarks.contains { $0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber }
    }

    func remove(surahNumber: Int, ayahNumber: Int) {
        let next = bookmarks.filter { !($0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber) }
        guard next.count != bookmarks.count else { return }
        bookmarks = next
        store.save(bookmarks)
    }
}
