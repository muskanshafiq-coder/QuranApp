//
//  StoriesCacheStore.swift
//  Quran App
//
//  Caches Islamic Cloud Stories API data (categories + stories per category) to disk
//  so the Sleep tab loads instantly and doesn't hit the API every time.
//

import Foundation

private struct CachedCategories: Codable {
    let categories: [StoryCategoryDTO]
    let savedAt: Date
}

private struct CachedStories: Codable {
    let stories: [StoryDTO]
    let savedAt: Date
}

final class StoriesCacheStore {
    static let shared = StoriesCacheStore()

    private let fileManager = FileManager.default
    private let encoder = JSONEncoder()
    private let decoder = JSONDecoder()

    /// Cache is considered valid for this duration. After that we still show cache but refresh from API.
    static let cacheMaxAge: TimeInterval = 24 * 60 * 60 // 24 hours

    private init() {}

    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent("StoriesCache", isDirectory: true)
    }

    private func ensureCacheDirectory() {
        guard let dir = cacheDirectory else { return }
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    // MARK: - Categories

    func saveCategories(_ categories: [StoryCategoryDTO], lang: String = "en") {
        ensureCacheDirectory()
        let key = "categories_\(lang).json"
        let payload = CachedCategories(categories: categories, savedAt: Date())
        guard let dir = cacheDirectory,
              let data = try? encoder.encode(payload) else { return }
        let url = dir.appendingPathComponent(key)
        try? data.write(to: url)
    }

    func loadCategories(lang: String = "en") -> [StoryCategoryDTO]? {
        let key = "categories_\(lang).json"
        guard let dir = cacheDirectory else { return nil }
        let url = dir.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url),
              let cached = try? decoder.decode(CachedCategories.self, from: data) else { return nil }
        return cached.categories
    }

    /// Returns cached categories if available (ignores age). Caller can still refresh from API.
    func loadCategoriesIfAvailable(lang: String = "en") -> [StoryCategoryDTO]? {
        loadCategories(lang: lang)
    }

    // MARK: - Stories by category

    func saveStories(_ stories: [StoryDTO], categoryId: String, lang: String = "en") {
        ensureCacheDirectory()
        let key = "stories_\(lang)_\(categoryId).json"
        let payload = CachedStories(stories: stories, savedAt: Date())
        guard let dir = cacheDirectory,
              let data = try? encoder.encode(payload) else { return }
        let url = dir.appendingPathComponent(key)
        try? data.write(to: url)
    }

    func loadStories(categoryId: String, lang: String = "en") -> [StoryDTO]? {
        let key = "stories_\(lang)_\(categoryId).json"
        guard let dir = cacheDirectory else { return nil }
        let url = dir.appendingPathComponent(key)
        guard let data = try? Data(contentsOf: url),
              let cached = try? decoder.decode(CachedStories.self, from: data) else { return nil }
        return cached.stories
    }
}
