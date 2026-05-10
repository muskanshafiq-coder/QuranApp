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

    /// Inserts at the top. Replaces an existing bookmark with the same identity:
    /// whole-surah (`ayahNumber == nil`) or the same reciter + surah + ayah.
    func add(_ bookmark: AudioSurahBookmark) {
        var updated = bookmarks
        if let ayah = bookmark.ayahNumber {
            updated.removeAll {
                $0.reciterSlug == bookmark.reciterSlug
                    && $0.surahNumber == bookmark.surahNumber
                    && $0.ayahNumber == ayah
            }
        } else {
            updated.removeAll {
                $0.reciterSlug == bookmark.reciterSlug
                    && $0.surahNumber == bookmark.surahNumber
                    && $0.ayahNumber == nil
            }
        }
        updated.insert(bookmark, at: 0)
        bookmarks = updated
        store.save(bookmarks)
    }

    func remove(id: UUID) {
        bookmarks = bookmarks.filter { $0.id != id }
        store.save(bookmarks)
    }

    /// Whole-surah bookmark (from surah list), ignoring ayah-specific rows.
    func containsBookmark(reciterSlug: String, surahNumber: Int) -> Bool {
        bookmarks.contains {
            $0.reciterSlug == reciterSlug && $0.surahNumber == surahNumber && $0.ayahNumber == nil
        }
    }

    func containsAyahBookmark(reciterSlug: String, surahNumber: Int, ayahNumber: Int) -> Bool {
        bookmarks.contains {
            $0.reciterSlug == reciterSlug
                && $0.surahNumber == surahNumber
                && $0.ayahNumber == ayahNumber
        }
    }

    /// Removes the whole-surah bookmark only (`ayahNumber == nil`).
    func remove(reciterSlug: String, surahNumber: Int) {
        let next = bookmarks.filter {
            !($0.reciterSlug == reciterSlug && $0.surahNumber == surahNumber && $0.ayahNumber == nil)
        }
        guard next.count != bookmarks.count else { return }
        bookmarks = next
        store.save(bookmarks)
    }

    func removeAyahBookmark(reciterSlug: String, surahNumber: Int, ayahNumber: Int) {
        let next = bookmarks.filter {
            !($0.reciterSlug == reciterSlug && $0.surahNumber == surahNumber && $0.ayahNumber == ayahNumber)
        }
        guard next.count != bookmarks.count else { return }
        bookmarks = next
        store.save(bookmarks)
    }
}
