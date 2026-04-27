import Foundation

final class UserDefaultsManager {
    static let shared = UserDefaultsManager()

    private let defaults: UserDefaults
    private enum Keys {
        static let selectedThemeColorID = "selectedThemeColorID"
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
}
