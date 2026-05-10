//
//  FavoriteRecitersStore.swift
//

import Foundation

protocol FavoriteRecitersStoring {
    func load() -> [PlayerReciterDisplayItem]
    func save(_ favorites: [PlayerReciterDisplayItem])
}

final class FavoriteRecitersStore: FavoriteRecitersStoring {
    static let shared = FavoriteRecitersStore()

    private let storage: UserDefaultsManager
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    init(storage: UserDefaultsManager = .shared) {
        self.storage = storage
    }

    func load() -> [PlayerReciterDisplayItem] {
        guard let data = storage.favoriteRecitersData(),
              let items = try? decoder.decode([PlayerReciterDisplayItem].self, from: data) else {
            return []
        }
        return items
    }

    func save(_ favorites: [PlayerReciterDisplayItem]) {
        guard let data = try? encoder.encode(favorites) else { return }
        storage.saveFavoriteRecitersData(data)
    }
}
