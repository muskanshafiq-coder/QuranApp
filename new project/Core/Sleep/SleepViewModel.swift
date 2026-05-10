//
//  SleepViewModel.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
class SleepViewModel: ObservableObject {
    @Published var featuredStories: [SleepStory] = []
    @Published var recentlyAddedStories: [SleepStory] = []
    /// Derived from all API stories across categories (newest first).
    @Published var recentlyAddedItems: [SleepAudioItem] = []
    @Published var nowPlaying: NowPlayingInfo = NowPlayingInfo(
        isPlaying: false,
        title: "sleep_now_playing_not_playing",
        progress: 0.0
    )

    /// Shared playback manager so audio continues when minimizing to popup bar.
    let sharedPlayback = SleepPlaybackManager()

    enum DownloadVisualState: Equatable {
        case notDownloaded
        case downloading
        case downloaded
    }

    /// In‑memory favorites for the current session.
    @Published private(set) var favoriteItems: [SleepAudioItem] = []
    /// Favorite story IDs in most-recent-first order (source of truth).
    private var favoriteOrderedIds: [String] = []

    /// Keys are "\(storyId)|\(languageOrDefault)".
    @Published private(set) var downloadingKeys: Set<String> = []
    /// Bumps whenever downloaded files change (forces SwiftUI refresh for filesystem-backed state).
    @Published private var downloadsVersion: Int = 0

    /// Item to present in full-screen play view (tap on card)
    @Published var selectedPlayItem: SleepAudioItem?
    /// When true, present popup opened (full screen); when false, stay in mini bar (e.g. when switching via forward).
    var openPopupFullScreenWhenPresenting: Bool = true
    /// List of items in current context (e.g. section); used for "next story" forward.
    private var currentPlaylist: [SleepAudioItem] = []
    /// Item to show options sheet (long tap on card)
    @Published var optionsSheetItem: SleepAudioItem?
    /// True when the long-press options overlay is visible; used to hide the tab bar.
    @Published var isOptionsOverlayVisible: Bool = false

    /// Islamic Cloud Stories API: one section per category (title from API, stories loaded per category).
    @Published var categorySections: [SleepCategorySection] = []
    @Published var isLoadingCategories = false
    @Published var categoriesLoadError: String?

    private let client = IslamicCloudAPIClient.shared
    private let storiesCache = StoriesCacheStore.shared
    private let storiesLang = "en"
    private let favoritesStore = SleepFavoritesStore.shared

    private var authorCacheObserver: NSObjectProtocol?

    init() {
        loadStories()

        // Placeholder until Islamic Cloud cache/API fills in (Recently Added row).
        let placeholderRecentlyAdded = Array(recentlyAddedStories.map { SleepAudioItem.from(story: $0) }.prefix(4))

        syncHydrateFromStoryCache()
        if recentlyAddedItems.isEmpty {
            recentlyAddedItems = placeholderRecentlyAdded
        }

        loadFavoritesFromStore()

        authorCacheObserver = NotificationCenter.default.addObserver(
            forName: .sleepStoryAuthorDidCache,
            object: nil,
            queue: .main
        ) { [weak self] _ in
            Task { @MainActor in
                self?.rehydrateCategorySectionsFromStoryCache()
            }
        }
    }

    deinit {
        if let authorCacheObserver {
            NotificationCenter.default.removeObserver(authorCacheObserver)
        }
    }

    /// Re-map items from cached `StoryDTO` so subtitles pick up `SleepStoryAuthorCache` (detail API `author`).
    private func rehydrateCategorySectionsFromStoryCache() {
        guard !categorySections.isEmpty else { return }
        categorySections = categorySections.map { sec in
            guard let stories = storiesCache.loadStories(categoryId: sec.category.id, lang: storiesLang),
                  !stories.isEmpty else { return sec }
            let items = stories.map { SleepAudioItem.from(story: $0) }
            return SleepCategorySection(
                category: sec.category,
                items: items,
                isLoading: sec.isLoading,
                loadError: sec.loadError
            )
        }
        recomputeRecentlyAdded()
        recomputeFavoriteItemsFromLoadedSections()
    }

    /// Synchronously restore categories + stories from disk so Sleep/Featured UI isn’t empty until `onAppear`.
    private func syncHydrateFromStoryCache() {
        guard let cachedCategories = storiesCache.loadCategoriesIfAvailable(lang: storiesLang), !cachedCategories.isEmpty else {
            return
        }
        let sections = cachedCategories.map { category in
            let cachedStories = storiesCache.loadStories(categoryId: category.id, lang: storiesLang)
            let items = (cachedStories ?? []).map { SleepAudioItem.from(story: $0) }
            return SleepCategorySection(category: category, items: items, isLoading: false, loadError: nil)
        }
        categorySections = sections
        recomputeRecentlyAdded()
        recomputeFavoriteItemsFromLoadedSections()
        for section in sections { prefetchThumbnails(for: section.items) }
    }

    /// Load from cache first (instant UI), then refresh from API and save to cache.
    func loadCategoriesAndStories() async {
        categoriesLoadError = nil

        // 1. Load from cache so screen shows immediately without waiting for API.
        syncHydrateFromStoryCache()

        // 2. Fetch from API and update cache + UI.
        isLoadingCategories = true
        defer { isLoadingCategories = false }
        do {
            let categories = try await client.fetchStoriesCategories(lang: storiesLang)
            storiesCache.saveCategories(categories, lang: storiesLang)
            categorySections = categories.map { category in
                let cachedStories = storiesCache.loadStories(categoryId: category.id, lang: storiesLang)
                let items = (cachedStories ?? []).map { SleepAudioItem.from(story: $0) }
                return SleepCategorySection(category: category, items: items, isLoading: true, loadError: nil)
            }
            recomputeRecentlyAdded()
            recomputeFavoriteItemsFromLoadedSections()
            await withTaskGroup(of: Void.self) { group in
                for section in categorySections {
                    group.addTask { await self.loadStoriesForCategory(section.category.id) }
                }
            }
        } catch {
            categoriesLoadError = error.localizedDescription
            if categorySections.isEmpty {
                categorySections = []
            }
        }
    }

    /// Load stories for one category from API, save to cache, and update the section.
    private func loadStoriesForCategory(_ categoryId: String) async {
        do {
            let stories = try await client.fetchStories(categoryId: categoryId, lang: storiesLang)
            storiesCache.saveStories(stories, categoryId: categoryId, lang: storiesLang)
            let items = stories.map { SleepAudioItem.from(story: $0) }
            updateSection(categoryId: categoryId, items: items, loadError: nil)
            prefetchThumbnails(for: items)
        } catch {
            updateSection(categoryId: categoryId, items: [], loadError: error.localizedDescription)
        }
    }

    /// Prefetch story thumbnails to disk cache in the background.
    private func prefetchThumbnails(for items: [SleepAudioItem]) {
        Task.detached(priority: .utility) {
            for item in items {
                guard let url = item.imageURL else { continue }
                // 1. Check if already in Core Data
                if SleepImageCacheStore.shared.fetchImageData(for: url.absoluteString) != nil {
                    continue
                }
                // 2. Download and save to both disk and Core Data
                if let localURL = await StoryImageCache.shared.downloadAndCache(from: url),
                   let data = try? Data(contentsOf: localURL) {
                    SleepImageCacheStore.shared.saveImageInBackground(data: data, for: url.absoluteString)
                }
            }
        }
    }

    private func updateSection(categoryId: String, items: [SleepAudioItem], loadError: String?) {
        categorySections = categorySections.map { sec in
            guard sec.category.id == categoryId else { return sec }
            return SleepCategorySection(category: sec.category, items: items, isLoading: false, loadError: loadError)
        }
        recomputeRecentlyAdded()
        recomputeFavoriteItemsFromLoadedSections()
    }

    private func recomputeRecentlyAdded() {
        let all = categorySections.flatMap(\.items)
        let sorted = all.sorted {
            ($0.createdAt ?? .distantPast) > ($1.createdAt ?? .distantPast)
        }
        // Pick 4 by default (per request: 3–4)
        recentlyAddedItems = Array(sorted.prefix(4))
    }

    private func loadStories() {
        featuredStories = [
            SleepStory(
                title: "The Peaceful Journey",
                artist: "Ziad Mohamed",
                date: "18 MAR",
                duration: "09:41",
                imageName: "mecca_img",
                isLocked: true,
                backgroundColor: "brown"
            ),
            SleepStory(
                title: "Moonlight over Dubai",
                artist: "Ziad Zidan",
                date: "11 MAR",
                duration: "12:20",
                imageName: "mecca_img",
                isLocked: false,
                backgroundColor: "blue"
            )
        ]

        recentlyAddedStories = [
            SleepStory(
                title: "The Peaceful Journey",
                artist: "Ziad Mohamed",
                date: "18 MAR",
                duration: "09:41",
                imageName: "mecca_img",
                isLocked: true,
                backgroundColor: "brown"
            ),
            SleepStory(
                title: "Moonlight over Dubai",
                artist: "Ziad Zidan",
                date: "11 MAR",
                duration: "12:20",
                imageName: "mecca_img",
                isLocked: false,
                backgroundColor: "blue"
            ),
            SleepStory(
                title: "Desert Nights",
                artist: "Ahmed Ali",
                date: "15 MAR",
                duration: "10:30",
                imageName: "mecca_img",
                isLocked: false,
                backgroundColor: "purple"
            )
        ]
    }

    private func loadFavoritesFromStore() {
        favoriteOrderedIds = favoritesStore.loadFavoriteIds()
        recomputeFavoriteItemsFromLoadedSections()
    }

    /// Rebuilds `favoriteItems` based on:
    /// 1) the saved favorite IDs (`favoriteOrderedIds`)
    /// 2) the currently loaded items inside `categorySections`
    private func recomputeFavoriteItemsFromLoadedSections() {
        guard !favoriteOrderedIds.isEmpty else {
            favoriteItems = []
            return
        }

        let allItems = categorySections.flatMap(\.items)
        let lookup = Dictionary(uniqueKeysWithValues: allItems.map { ($0.id, $0) })
        favoriteItems = favoriteOrderedIds.compactMap { lookup[$0] }
    }

    func playStory(_ story: SleepStory) {
        if !story.isLocked {
            nowPlaying = NowPlayingInfo(isPlaying: true, title: story.title, progress: 0.0)
        }
    }

    func selectItemForPlay(_ item: SleepAudioItem) {
        selectItemForPlay(item, from: [])
    }

    func selectItemForPlay(_ item: SleepAudioItem, from list: [SleepAudioItem]) {
        if !item.isLocked {
            currentPlaylist = list
            openPopupFullScreenWhenPresenting = true
            nowPlaying = NowPlayingInfo(isPlaying: true, title: item.title, progress: 0.0)
            selectedPlayItem = item
        }
    }

    /// Advance to next story in current playlist. Returns true if switched, false if no next (caller may skip within track).
    /// Keeps popup in mini bar (does not open full screen).
    func playNext() -> Bool {
        guard let current = selectedPlayItem,
              let idx = currentPlaylist.firstIndex(where: { $0.id == current.id }),
              idx + 1 < currentPlaylist.count else { return false }
        openPopupFullScreenWhenPresenting = false
        selectedPlayItem = currentPlaylist[idx + 1]
        return true
    }

    func showOptions(for item: SleepAudioItem) {
        optionsSheetItem = item
    }

    func togglePlayback() {
        nowPlaying.isPlaying.toggle()
    }

    func downloadItem(_ item: SleepAudioItem) {
        let (lang, remote) = preferredAudioForDownloadOrPlayback(item)
        guard let remote else { return }
        let key = downloadKey(storyId: item.id, languageCode: lang)
        if downloadingKeys.contains(key) { return }
        downloadingKeys.insert(key)
        downloadsVersion &+= 1
        print("[SleepViewModel] downloadItem: start. storyId=\(item.id) lang=\(lang ?? "default") remote=\(remote.absoluteString) key=\(key)")
        Task(priority: .utility) { [weak self] in
            defer {
                Task { @MainActor in
                    self?.downloadingKeys.remove(key)
                    self?.downloadsVersion &+= 1
                }
            }
            do {
                let localURL = try await SleepAudioDownloadStore.shared.downloadIfNeeded(
                    storyId: item.id,
                    languageCode: lang,
                    remoteURL: remote
                )
                print("[SleepViewModel] downloadItem: success. storyId=\(item.id) local=\(localURL.path)")
            } catch {
                print("[SleepViewModel] downloadItem: FAILED. storyId=\(item.id) error=\(error)")
            }
        }
    }

    func removeDownload(for item: SleepAudioItem) {
        let (lang, remote) = preferredAudioForDownloadOrPlayback(item)
        do {
            try SleepAudioDownloadStore.shared.removeDownload(storyId: item.id, languageCode: lang, remoteURL: remote)
            print("[SleepViewModel] removeDownload: removed. storyId=\(item.id) lang=\(lang ?? "default")")
            downloadsVersion &+= 1
        } catch {
            // ignore: removing is best-effort
            print("[SleepViewModel] removeDownload: FAILED. storyId=\(item.id) lang=\(lang ?? "default") error=\(error)")
        }
    }

    func downloadState(for item: SleepAudioItem) -> DownloadVisualState {
        _ = downloadsVersion
        let (lang, remote) = preferredAudioForDownloadOrPlayback(item)
        let key = downloadKey(storyId: item.id, languageCode: lang)
        if downloadingKeys.contains(key) { return .downloading }
        guard let remote else { return .notDownloaded }
        return SleepAudioDownloadStore.shared.isDownloaded(storyId: item.id, languageCode: lang, remoteURL: remote) ? .downloaded : .notDownloaded
    }

    /// Returns the "best" audio URL for this item based on cached selected language (if available),
    /// falling back to the item's `audioURL`.
    func preferredRemoteAudioURL(for item: SleepAudioItem) -> URL? {
        preferredAudioForDownloadOrPlayback(item).remoteURL
    }

    func preferredLanguageCode(for item: SleepAudioItem) -> String? {
        preferredAudioForDownloadOrPlayback(item).languageCode
    }

    private func downloadKey(storyId: String, languageCode: String?) -> String {
        let lang = (languageCode?.isEmpty == false) ? languageCode! : "default"
        return "\(storyId)|\(lang.lowercased())"
    }

    private func preferredAudioForDownloadOrPlayback(_ item: SleepAudioItem) -> (languageCode: String?, remoteURL: URL?) {
        let selectedLang = SleepStoryTranslationsCacheStore.shared.cachedSelectedLanguageCode(storyId: item.id)
        if let lang = selectedLang, !lang.isEmpty {
            let cached = SleepStoryTranslationsCacheStore.shared.cachedTranslations(storyId: item.id)
            if let t = cached.first(where: { $0.language == lang }),
               let urlStr = t.files.first?.fileUrl,
               let remote = URL(string: urlStr) {
                return (lang, remote)
            }
        }
        return (selectedLang, item.audioURL)
    }

    /// Returns true when the given item is currently marked as favorite.
    func isFavorite(_ item: SleepAudioItem) -> Bool {
        favoriteOrderedIds.contains(item.id)
    }

    /// Toggle favorite status for the given item and keep a small in‑memory list.
    func addToFavorites(_ item: SleepAudioItem) {
        if let idx = favoriteOrderedIds.firstIndex(of: item.id) {
            favoriteOrderedIds.remove(at: idx)
        } else {
            favoriteOrderedIds.insert(item.id, at: 0)
        }

        // Persist ordered IDs so the Saved stories list keeps its order across launches.
        favoritesStore.saveFavoriteIds(favoriteOrderedIds)
        recomputeFavoriteItemsFromLoadedSections()
    }

    func shareItem(_ item: SleepAudioItem) {
        // TODO: See repo root TODO.txt (Sleep stories — share).
    }
}

