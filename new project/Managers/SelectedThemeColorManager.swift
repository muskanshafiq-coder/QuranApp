import SwiftUI
import Combine
final class SelectedThemeColorManager: ObservableObject {
    @Published var selectedThemeID: String
    @Published var selectedColor: Color
    @Published var isPremiumUser: Bool = false

    private let userDefaultsManager: UserDefaultsManager
    private static let fallbackThemeID = "red"

    init(userDefaultsManager: UserDefaultsManager = .shared) {
        self.userDefaultsManager = userDefaultsManager

        let savedID = userDefaultsManager.selectedThemeColorID() ?? Self.fallbackThemeID
        let initialTheme = AppColorTheme.theme(for: savedID) ?? AppColorTheme.theme(for: Self.fallbackThemeID)!

        self.selectedThemeID = initialTheme.id
        self.selectedColor = initialTheme.color
    }

    func applyColor(_ theme: AppColorTheme) {
        guard !theme.isPremium || isPremiumUser else { return }
        selectedThemeID = theme.id
        selectedColor = theme.color
        userDefaultsManager.saveSelectedThemeColorID(theme.id)
    }
}
