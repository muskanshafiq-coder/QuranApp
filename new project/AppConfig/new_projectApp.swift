import SwiftUI

@main
struct MyApp: App {
    @StateObject private var languageManager = AppLanguageManager()
    @StateObject private var themeManager = ThemeManager()
    @StateObject private var selectedThemeColorManager = SelectedThemeColorManager()

    var body: some Scene {
        WindowGroup {
            RootView()
                .ignoresSafeArea()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
        }
    }
}
