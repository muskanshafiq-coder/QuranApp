//
//  SleepModel.swift
//

import Foundation

/// Formats duration strings for story cards as `minutes:seconds` (e.g. `7:15`). Supports `m:ss`, `h:mm:ss`, or a single integer (minutes).
func formatSleepDurationForDisplay(_ raw: String) -> String {
    let d = raw.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !d.isEmpty else { return "" }
    let parts = d.split(separator: ":").map { String($0).trimmingCharacters(in: .whitespaces) }
    if parts.count >= 3,
       let h = Int(parts[0]), let m = Int(parts[1]), let s = Int(parts[2]) {
        let totalMinutes = h * 60 + m
        return String(format: "%d:%02d", totalMinutes, min(59, max(0, s)))
    }
    if parts.count == 2, let m = Int(parts[0]), let s = Int(parts[1]) {
        return String(format: "%d:%02d", m, min(59, max(0, s)))
    }
    if parts.count == 1, let m = Int(parts[0]) {
        return String(format: "%d:%02d", m, 0)
    }
    return d
}

// MARK: - Unified audio item for display (local or API)
struct SleepAudioItem: Identifiable, Hashable {
    let id: String
    let title: String
    let subtitle: String
    let imageURL: URL?
    let localImageName: String?
    let audioURL: URL?
    let duration: String
    let isLocked: Bool
    let backgroundColor: String
    /// Used for sorting in "Recently Added" (API stories only).
    let createdAt: Date?

    static func from(story: SleepStory) -> SleepAudioItem {
        SleepAudioItem(
            id: story.id.uuidString,
            title: story.title,
            subtitle: story.artist,
            imageURL: nil,
            localImageName: story.imageName,
            audioURL: nil,
            duration: story.duration,
            isLocked: story.isLocked,
            backgroundColor: story.backgroundColor,
            createdAt: parseCreatedAtFromSleepStoryDate(story.date)
        )
    }

    static func from(story: StoryDTO) -> SleepAudioItem {
        let thumbURL = story.thumbnail.flatMap { URL(string: $0) }
        var audioURL = story.files.first.flatMap { URL(string: $0.fileUrl) }
        // AVPlayer can fail if the URL doesn't end in a known extension
        if let currentURL = audioURL, currentURL.pathExtension.isEmpty {
            audioURL = currentURL.appendingPathExtension("mp3")
        }
        
        let durationStr: String
        if let d = story.files.first?.duration, d > 0 {
            let m = Int(d) / 60
            let s = Int(d) % 60
            durationStr = String(format: "%d:%02d", m, s)
        } else {
            durationStr = ""
        }
        return SleepAudioItem(
            id: story.id,
            title: story.title,
            subtitle: Self.subtitleForIslamicCloudList(story),
            imageURL: thumbURL,
            localImageName: nil,
            audioURL: audioURL,
            duration: durationStr,
            isLocked: false,
            backgroundColor: "purple",
            createdAt: SleepAudioItem.parseCreatedAt(story.createdAt)
        )
    }

    /// List endpoint often returns `author`/`source` as null; detail `GET /stories/item/{id}` has them — see `SleepStoryAuthorCache`.
    private static func subtitleForIslamicCloudList(_ story: StoryDTO) -> String {
        func nonEmpty(_ s: String?) -> String? {
            guard let t = s?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty else { return nil }
            return t
        }
        if let a = nonEmpty(story.author) { return a }
        if let s = nonEmpty(story.source) { return s }
        if let c = nonEmpty(SleepStoryAuthorCache.shared.author(for: story.id)) { return c }
        return ""
    }

    private static func parseCreatedAt(_ raw: String) -> Date? {
        // Most APIs return ISO8601 like "2026-03-18T12:34:56.789Z"
        let iso = ISO8601DateFormatter()
        iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let d = iso.date(from: raw) { return d }
        iso.formatOptions = [.withInternetDateTime]
        return iso.date(from: raw)
    }

    /// Parses SleepStory's `date` strings like "18 MAR" (month abbreviations).
    /// Used so Recently Added cards can also show the "Featured" date label.
    private static func parseCreatedAtFromSleepStoryDate(_ raw: String) -> Date? {
        let cleaned = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard cleaned.isEmpty == false else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        formatter.locale = Locale(identifier: "en_US_POSIX")
        if let d = formatter.date(from: cleaned.uppercased()) { return d }

        // Fallback to current locale (in case abbreviations are localized).
        formatter.locale = .current
        if let d = formatter.date(from: cleaned) { return d }

        return nil
    }

    func hash(into hasher: inout Hasher) { hasher.combine(id) }
    static func == (lhs: SleepAudioItem, rhs: SleepAudioItem) -> Bool { lhs.id == rhs.id }
}

// MARK: - Category section from Islamic Cloud Stories API (category title + story cards)
struct SleepCategorySection: Identifiable {
    var id: String { category.id }
    let category: StoryCategoryDTO
    var items: [SleepAudioItem]
    var isLoading: Bool
    var loadError: String?
}

struct SleepStory: Identifiable {
    let id = UUID()
    let title: String
    let artist: String
    let date: String
    let duration: String
    let imageName: String
    let isLocked: Bool
    let backgroundColor: String // For gradient/color background
}

struct NowPlayingInfo {
    var isPlaying: Bool
    var title: String
    var progress: Double // 0.0 to 1.0
}

struct SleepModel {
    var featuredStories: [SleepStory]
    var recentlyAddedStories: [SleepStory]
    var nowPlaying: NowPlayingInfo
}

// MARK: - Story author cache (detail API; fills subtitle when list has null author)

extension Notification.Name {
    /// Posted when `author` from story detail is saved so category cards can re-map subtitles.
    static let sleepStoryAuthorDidCache = Notification.Name("sleepStoryAuthorDidCache")
}

/// Persists `story.author` from `GET /stories/item/{id}` because category list responses often omit it.
final class SleepStoryAuthorCache {
    static let shared = SleepStoryAuthorCache()

    private let defaults = UserDefaults.standard
    private let storageKey = "sleep_story_author_by_id_v1"
    private var authors: [String: String] = [:]
    private let lock = NSLock()

    private init() {
        if let data = defaults.data(forKey: storageKey),
           let decoded = try? JSONDecoder().decode([String: String].self, from: data) {
            authors = decoded
        }
    }

    func author(for storyId: String) -> String? {
        lock.lock()
        defer { lock.unlock() }
        return authors[storyId]
    }

    func saveAuthor(_ author: String?, for storyId: String) {
        let trimmed = author?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        lock.lock()
        if trimmed.isEmpty {
            authors.removeValue(forKey: storyId)
        } else {
            authors[storyId] = trimmed
        }
        let snapshot = authors
        lock.unlock()
        if let data = try? JSONEncoder().encode(snapshot) {
            defaults.set(data, forKey: storageKey)
        }
    }
}

