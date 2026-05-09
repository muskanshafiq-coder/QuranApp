//
//  SleepImageCacheStore.swift
//  Quran App
//
//  Manages persistence of Sleep Screen images in Core Data for fast and reliable loading.
//

import Foundation
import CoreData
import UIKit

final class SleepImageCacheStore {
    static let shared = SleepImageCacheStore()
    
    private let persistence = PersistenceController.shared
    
    private init() {}
    
    /// Returns image data from Core Data if available.
    func fetchImageData(for id: String) -> Data? {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStoryImage")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let result = try ctx.fetch(request).first
            return result?.value(forKey: "imageData") as? Data
        } catch {
            print("SleepImageCacheStore: Fetch error for \(id): \(error)")
            return nil
        }
    }
    
    /// Saves image data to Core Data.
    func saveImage(data: Data, for id: String) {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStoryImage")
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        
        do {
            let existing = try ctx.fetch(request).first
            let entity: NSManagedObject
            
            if let found = existing {
                entity = found
            } else {
                entity = NSEntityDescription.insertNewObject(forEntityName: "SleepStoryImage", into: ctx)
                entity.setValue(id, forKey: "id")
            }
            
            entity.setValue(data, forKey: "imageData")
            entity.setValue(Date(), forKey: "lastUpdated")
            
            persistence.save(context: ctx)
        } catch {
            print("SleepImageCacheStore: Save error for \(id): \(error)")
        }
    }
    
    /// Background save to Core Data.
    func saveImageInBackground(data: Data, for id: String) {
        Task.detached(priority: .utility) {
            await self.persistence.performBackgroundTask { context in
                let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStoryImage")
                request.predicate = NSPredicate(format: "id == %@", id)
                request.fetchLimit = 1
                
                do {
                    let existing = try context.fetch(request).first
                    let entity: NSManagedObject
                    
                    if let found = existing {
                        entity = found
                    } else {
                        entity = NSEntityDescription.insertNewObject(forEntityName: "SleepStoryImage", into: context)
                        entity.setValue(id, forKey: "id")
                    }
                    
                    entity.setValue(data, forKey: "imageData")
                    entity.setValue(Date(), forKey: "lastUpdated")
                    
                    try context.save()
                } catch {
                    print("SleepImageCacheStore: BG Save error for \(id): \(error)")
                }
            }
        }
    }
}

// MARK: - Sleep story translations + selected language (globe)

/// Core Data cache for Sleep story translations and the last selected globe-language per story.
///
/// Goal:
/// - Show translation options instantly (Core Data).
/// - Still refresh from API; only update Core Data if API data changed.
final class SleepStoryTranslationsCacheStore {
    static let shared = SleepStoryTranslationsCacheStore()
    private let persistence = PersistenceController.shared

    private init() {}

    func cachedTranslations(storyId: String) -> [StoryTranslationDTO] {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStoryTranslationCached")
        request.predicate = NSPredicate(format: "storyId == %@", storyId)

        do {
            let rows = try ctx.fetch(request)
            // Keep a stable order so diffing/menus don't "shuffle" between launches.
            let sorted = rows.sorted {
                let a = ($0.value(forKey: "languageCode") as? String) ?? ""
                let b = ($1.value(forKey: "languageCode") as? String) ?? ""
                if a != b { return a < b }
                let ta = ($0.value(forKey: "title") as? String) ?? ""
                let tb = ($1.value(forKey: "title") as? String) ?? ""
                return ta < tb
            }
            return sorted.compactMap { row in
                guard
                    let translationId = row.value(forKey: "translationId") as? String,
                    let language = row.value(forKey: "languageCode") as? String
                else { return nil }

                let title = row.value(forKey: "title") as? String ?? ""
                let desc = row.value(forKey: "translationDescription") as? String
                let fileId = row.value(forKey: "fileId") as? String ?? translationId
                let fileUrl = row.value(forKey: "fileUrl") as? String ?? ""
                let duration = row.value(forKey: "duration") as? Double
                let isChapter = row.value(forKey: "isChapter") as? Bool
                let chapterNumber = row.value(forKey: "chapterNumber") as? Int

                let file = StoryFileDTO(
                    id: fileId,
                    fileUrl: fileUrl,
                    duration: duration,
                    isChapter: isChapter ?? false,
                    chapterNumber: chapterNumber
                )

                return StoryTranslationDTO(
                    id: translationId,
                    language: language,
                    title: title,
                    description: desc,
                    files: fileUrl.isEmpty ? [] : [file]
                )
            }
        } catch {
            print("SleepStoryTranslationsCacheStore: Fetch translations error for \(storyId): \(error)")
            return []
        }
    }

    func cachedSelectedLanguageCode(storyId: String) -> String? {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStorySelectedLanguageCached")
        request.predicate = NSPredicate(format: "storyId == %@", storyId)
        request.fetchLimit = 1
        do {
            let row = try ctx.fetch(request).first
            return row?.value(forKey: "languageCode") as? String
        } catch {
            print("SleepStoryTranslationsCacheStore: Fetch selected language error for \(storyId): \(error)")
            return nil
        }
    }

    func saveSelectedLanguageCode(_ code: String, storyId: String) {
        let ctx = persistence.viewContext
        let request = NSFetchRequest<NSManagedObject>(entityName: "SleepStorySelectedLanguageCached")
        request.predicate = NSPredicate(format: "storyId == %@", storyId)
        request.fetchLimit = 1
        do {
            let existing = try ctx.fetch(request).first
            let entity: NSManagedObject = existing ?? NSEntityDescription.insertNewObject(forEntityName: "SleepStorySelectedLanguageCached", into: ctx)
            entity.setValue(storyId, forKey: "storyId")
            entity.setValue(code, forKey: "languageCode")
            entity.setValue(Date(), forKey: "lastUpdated")
            persistence.save(context: ctx)
        } catch {
            print("SleepStoryTranslationsCacheStore: Save selected language error for \(storyId): \(error)")
        }
    }

    /// Upserts the translation options for a story. If the cached content matches the incoming API content, no write occurs.
    func upsertTranslationsIfChanged(storyId: String, translations: [StoryTranslationDTO]) async {
        // Normalize to a stable signature for diffing.
        func signature(_ list: [StoryTranslationDTO]) -> [String] {
            list.map { t in
                let file = t.files.first
                let url = file?.fileUrl ?? ""
                let dur = file?.duration ?? -1
                let chap = file?.isChapter ?? false
                let chapNum = file?.chapterNumber ?? -1
                return [
                    t.id,
                    t.language.lowercased(),
                    t.title,
                    (t.description ?? ""),
                    url,
                    String(dur),
                    String(chap),
                    String(chapNum)
                ].joined(separator: "|")
            }
            .sorted()
        }

        let existingSig = signature(cachedTranslations(storyId: storyId))
        let incomingSig = signature(translations)
        guard existingSig != incomingSig else { return }

        await persistence.performBackgroundTask { context in
            let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "SleepStoryTranslationCached")
            fetch.predicate = NSPredicate(format: "storyId == %@", storyId)

            let delete = NSBatchDeleteRequest(fetchRequest: fetch)
            delete.resultType = .resultTypeObjectIDs

            do {
                let result = try context.execute(delete) as? NSBatchDeleteResult
                if let ids = result?.result as? [NSManagedObjectID], !ids.isEmpty {
                    NSManagedObjectContext.mergeChanges(fromRemoteContextSave: [NSDeletedObjectsKey: ids], into: [self.persistence.viewContext])
                }

                let now = Date()
                for t in translations {
                    let obj = NSEntityDescription.insertNewObject(forEntityName: "SleepStoryTranslationCached", into: context)
                    obj.setValue(storyId, forKey: "storyId")
                    obj.setValue(t.id, forKey: "translationId")
                    obj.setValue(t.language, forKey: "languageCode")
                    obj.setValue(t.title, forKey: "title")
                    obj.setValue(t.description, forKey: "translationDescription")

                    if let f = t.files.first {
                        obj.setValue(f.id, forKey: "fileId")
                        obj.setValue(f.fileUrl, forKey: "fileUrl")
                        if let d = f.duration { obj.setValue(d, forKey: "duration") }
                        obj.setValue(f.isChapter, forKey: "isChapter")
                        if let n = f.chapterNumber { obj.setValue(n, forKey: "chapterNumber") }
                    }
                    obj.setValue(now, forKey: "lastUpdated")
                }

                try context.save()
            } catch {
                print("SleepStoryTranslationsCacheStore: Upsert translations error for \(storyId): \(error)")
            }
        }
    }
}
