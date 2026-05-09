import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults: UserDefaults
    enum Keys {
        static let selectedThemeColorID = "selectedThemeColorID"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
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
}
