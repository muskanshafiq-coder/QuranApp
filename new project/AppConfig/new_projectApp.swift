//
//  new_projectApp.swift
//

import SwiftUI

@main
struct MyApp: App {
    @StateObject private var languageManager = AppLanguageManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var selectedThemeColorManager = SelectedThemeColorManager()
    @StateObject private var authManager = AuthManager.shared
    @ObservedObject private var dummyPaywallPresenter = DummyPaywallPresenter.shared
    init(){
        prefetchSleepStories()
    }
    var body: some Scene {
        WindowGroup {
            RootView()
                .ignoresSafeArea()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
                .environmentObject(authManager)
                .sheet(isPresented: $dummyPaywallPresenter.isPresented) {
                    DummySubscriptionPaywallView()
                        .environmentObject(selectedThemeColorManager)
                }
        }
    }
}
extension MyApp {
    private func prefetchSleepStories() {
        Task.detached(priority: .utility) {
            let client = await IslamicCloudAPIClient.shared
            let cache = await StoriesCacheStore.shared
            let lang = "en"
            let translationsCache = await SleepStoryTranslationsCacheStore.shared

            do {
                let categories = try await client.fetchStoriesCategories(lang: lang)
                await cache.saveCategories(categories, lang: lang)
                print("✅ Sleep Stories: cached categories (\(categories.count))")

                // Also prefetch a small number of story details so the Sleep player globe menu is instant
                // even on the first open (translations options cached in Core Data).
                var storyIdsToPrefetch: [String] = []

                await withTaskGroup(of: Void.self) { group in
                    for category in categories {
                        group.addTask {
                            do {
                                let stories = try await client.fetchStories(categoryId: category.id, lang: lang)
                                await cache.saveStories(stories, categoryId: category.id, lang: lang)
                                print("✅ Sleep Stories: cached \(category.title) (\(stories.count))")

                                // Collect a few story IDs per category (cap overall below).
                                let ids = stories.prefix(3).map(\.id)
                                // Not thread-safe to mutate from multiple tasks; store to UserDefaults cache instead
                                // by appending later on MainActor.
                                await MainActor.run {
                                    storyIdsToPrefetch.append(contentsOf: ids)
                                }
                            } catch {
                                print("❌ Sleep Stories: \(category.title): \(error.localizedDescription)")
                            }
                        }
                    }
                }

                // Deduplicate and cap to avoid too many network calls on launch.
                let uniqueIds = Array(Set(storyIdsToPrefetch)).prefix(12)
                await withTaskGroup(of: Void.self) { group in
                    for id in uniqueIds {
                        group.addTask {
                            do {
                                let detail = try await client.fetchStoryDetail(storyId: id)
                                await translationsCache.upsertTranslationsIfChanged(storyId: id, translations: detail.translations)
                                SleepStoryAuthorCache.shared.saveAuthor(detail.author, for: id)
                                await MainActor.run {
                                    NotificationCenter.default.post(name: .sleepStoryAuthorDidCache, object: nil)
                                }
                            } catch {
                                // Ignore; player will fetch on demand.
                            }
                        }
                    }
                }
            } catch {
                print("❌ Sleep Stories: categories: \(error.localizedDescription)")
            }
        }
    }

}
