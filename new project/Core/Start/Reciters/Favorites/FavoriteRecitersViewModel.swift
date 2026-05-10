//
//  FavoriteRecitersViewModel.swift
//

import Foundation
import Combine

@MainActor
final class FavoriteRecitersViewModel: ObservableObject {
    /// Shared instance so every screen shows the same list and counts.
    static let shared = FavoriteRecitersViewModel()

    @Published private(set) var favorites: [PlayerReciterDisplayItem] = []

    private let store: FavoriteRecitersStoring

    init(store: FavoriteRecitersStoring = FavoriteRecitersStore.shared) {
        self.store = store
        self.favorites = store.load()
    }

    /// Inserts the reciter at the top if not already present.
    func add(_ item: PlayerReciterDisplayItem) {
        guard !favorites.contains(where: { $0.id == item.id }) else { return }
        favorites.insert(item, at: 0)
        store.save(favorites)
    }

    func remove(id: String) {
        let before = favorites.count
        favorites.removeAll { $0.id == id }
        guard favorites.count != before else { return }
        store.save(favorites)
    }

    func isFavorite(id: String) -> Bool {
        favorites.contains { $0.id == id }
    }

    /// Toggles favorite state. Returns `true` when the reciter was added,
    /// `false` when removed. Useful so the caller can show the right toast.
    @discardableResult
    func toggle(_ item: PlayerReciterDisplayItem) -> Bool {
        if isFavorite(id: item.id) {
            remove(id: item.id)
            return false
        } else {
            add(item)
            return true
        }
    }
}
