//
//  UserDefaultsManager.swift
//

import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults: UserDefaults
    enum Keys {
        static let selectedThemeColorID = "selectedThemeColorID"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isSignedIn = "isSignedIn"
        static let playlistsData = "playlistsData"
        static let quranFontFamily = "quran_font_family"
        static let quranFontSize = "quran_font_size"
        static let quranSelectedTranslationIds = "quran_selected_translation_ids"
        static let quranPreferredAudioReciterEdition = "quran_preferred_audio_reciter_edition"
        static let quranLastSurahNumber = "quran_last_surah_number"
        static let quranLastAyahNumber = "quran_last_ayah_number"
        static let quranLastJuz = "quran_last_juz"
        static let quranLastHizbQuarter = "quran_last_hizb_quarter"
        static let favoriteRecitersData = "favorite_reciters_data"
        static let audioBookmarksData = "audio_bookmarks_data"
        static let quranLatestSelectedTranslationId = "quran_latest_selected_translation_id"
        static let quranDownloadedTranslationIds = "quran_downloaded_translation_ids"
        /// 0 = slowest auto-scroll, 1 = fastest. Maps to ayah follow animation duration in reciter surah view.
        static let quranReciterAyahScrollSpeed = "quran_reciter_ayah_scroll_speed"
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    func getQuranReadingProgress() -> ReadingProgress? {
        guard let surah = defaults.object(forKey: Keys.quranLastSurahNumber) as? Int,
              let ayah = defaults.object(forKey: Keys.quranLastAyahNumber) as? Int,
              let juz = defaults.object(forKey: Keys.quranLastJuz) as? Int,
              let hizb = defaults.object(forKey: Keys.quranLastHizbQuarter) as? Int else {
            return nil
        }
        return ReadingProgress(surahNumber: surah, ayahNumber: ayah, juz: juz, hizbQuarter: hizb)
    }

    func saveSelectedThemeColorID(_ id: String) {
        defaults.set(id, forKey: Keys.selectedThemeColorID)
    }

    func selectedThemeColorID() -> String? {
        defaults.string(forKey: Keys.selectedThemeColorID)
    }

    func setHasCompletedOnboarding(_ completed: Bool) {
        defaults.set(completed, forKey: Keys.hasCompletedOnboarding)
    }

    func hasCompletedOnboarding() -> Bool {
        defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    func setSignedIn(_ signedIn: Bool) {
        defaults.set(signedIn, forKey: Keys.isSignedIn)
    }

    func isSignedIn() -> Bool {
        defaults.bool(forKey: Keys.isSignedIn)
    }

    func savePlaylistsData(_ data: Data) {
        defaults.set(data, forKey: Keys.playlistsData)
    }

    func playlistsData() -> Data? {
        defaults.data(forKey: Keys.playlistsData)
    }

    func saveQuranSelectedTranslationIds(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.quranSelectedTranslationIds)
    }

    // MARK: - Favorite reciters

    func favoriteRecitersData() -> Data? {
        defaults.data(forKey: Keys.favoriteRecitersData)
    }

    func saveFavoriteRecitersData(_ data: Data) {
        defaults.set(data, forKey: Keys.favoriteRecitersData)
    }

    // MARK: - Audio bookmarks (surah under reciter)

    func audioBookmarksData() -> Data? {
        defaults.data(forKey: Keys.audioBookmarksData)
    }

    func saveAudioBookmarksData(_ data: Data) {
        defaults.set(data, forKey: Keys.audioBookmarksData)
    }
    
    // MARK: - Quran Font
    /// Selected Quran font family. "SF font" = system font; otherwise use custom font name.
    var quranFontFamily: String {
        get {
            defaults.string(forKey: Keys.quranFontFamily) ?? "Nabi"
        }
        set {
            defaults.set(newValue, forKey: Keys.quranFontFamily)
        }
    }

    /// Quran ayah font size (16–32 pt). Default 20.
    var quranFontSize: Double {
        get {
            let value = defaults.double(forKey: Keys.quranFontSize)
            return value > 0 ? value : 20
        }
        set {
            defaults.set(min(32, max(16, newValue)), forKey: Keys.quranFontSize)
        }
    }
    /// ID of the translation whose flag is shown in the surah toolbar (last one user selected).
    var quranLatestSelectedTranslationId: String? {
        get {
            defaults.string(forKey: Keys.quranLatestSelectedTranslationId)
        }
        set {
            if let v = newValue {
                defaults.set(v, forKey: Keys.quranLatestSelectedTranslationId)
            } else {
                defaults.removeObject(forKey: Keys.quranLatestSelectedTranslationId)
            }
        }
    }
    var quranDownloadedTranslationIds: [String] {
        get {
            (defaults.array(forKey: Keys.quranDownloadedTranslationIds) as? [String]) ?? []
        }
        set {
            defaults.set(newValue, forKey: Keys.quranDownloadedTranslationIds)
        }
    }
    var quranSelectedTranslationIds: [String] {
        get {
            (defaults.array(forKey: Keys.quranSelectedTranslationIds) as? [String]) ?? []
        }
        set {
            defaults.set(newValue, forKey: Keys.quranSelectedTranslationIds)
        }
    }

    /// Stored 0...1; higher = faster auto-scroll to active ayah in reciter surah view.
    var quranReciterAyahScrollSpeed: Double {
        get {
            guard defaults.object(forKey: Keys.quranReciterAyahScrollSpeed) != nil else { return 0.5 }
            let v = defaults.double(forKey: Keys.quranReciterAyahScrollSpeed)
            return min(1, max(0, v))
        }
        set {
            defaults.set(min(1, max(0, newValue)), forKey: Keys.quranReciterAyahScrollSpeed)
        }
    }

    /// `easeInOut` duration used when scrolling the ayah list to the active verse (from stored speed).
    static func ayahScrollAnimationDuration(forStoredSpeed speed: Double) -> Double {
        let s = min(1, max(0, speed))
        return 1.28 - s * (1.28 - 0.32)
    }
}
