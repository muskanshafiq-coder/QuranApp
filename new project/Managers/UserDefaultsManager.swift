import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults: UserDefaults
    enum Keys {
        static let selectedThemeColorID = "selectedThemeColorID"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
        static let isSignedIn = "isSignedIn"
        static let playlistsData = "playlistsData"
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
}
