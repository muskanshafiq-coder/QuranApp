//
//  SleepFavoritesStore.swift
//

import Foundation
import CoreData

final class SleepFavoritesStore {
    static let shared = SleepFavoritesStore()

    private let persistence = PersistenceController.shared

    private init() {}

    /// Load all favorite story IDs, most-recent-first.
    func loadFavoriteIds() -> [String] {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepFavorite")
        let sort = NSSortDescriptor(key: "createdAt", ascending: false)
        request.sortDescriptors = [sort]

        do {
            let rows = try ctx.fetch(request)
            return rows.compactMap { $0.value(forKey: "storyId") as? String }
        } catch {
            print("SleepFavoritesStore: loadFavoriteIds error: \(error)")
            return []
        }
    }

    /// Persist a full replacement list of favorite IDs, most‑recent‑first.
    func saveFavoriteIds(_ ids: [String]) {
        let ctx = persistence.viewContext

        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SleepFavorite")
        let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetch)

        do {
            try ctx.execute(deleteRequest)

            let now = Date()
            for (offset, id) in ids.enumerated() {
                let obj = NSEntityDescription.insertNewObject(forEntityName: "SleepFavorite", into: ctx)
                obj.setValue(id, forKey: "storyId")
                // Ensure ordering is preserved while still storing a real date.
                obj.setValue(now.addingTimeInterval(TimeInterval(-offset)), forKey: "createdAt")
            }

            try ctx.save()
        } catch {
            print("SleepFavoritesStore: saveFavoriteIds error: \(error)")
        }
    }
}

