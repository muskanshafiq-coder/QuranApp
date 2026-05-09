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
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
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

    /// Ordered translation / resource ids for Quran reader playback (e.g. `en.yusufali`, legacy `en`).
    var quranSelectedTranslationIds: [String] {
        defaults.stringArray(forKey: Keys.quranSelectedTranslationIds) ?? []
    }

    func saveQuranSelectedTranslationIds(_ ids: [String]) {
        defaults.set(ids, forKey: Keys.quranSelectedTranslationIds)
    }
}
