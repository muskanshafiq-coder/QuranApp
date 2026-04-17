import SwiftUI

@main
struct MyApp: App {
    @StateObject private var languageManager = AppLanguageManager()
    @StateObject private var themeManager = ThemeManager()

    var body: some Scene {
        WindowGroup {
            AppRootContainer()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
        }
    }
}

/// Applies locale and color scheme on a real `View` so updates invalidate correctly (unlike `@AppStorage` on `App`).
private struct AppRootContainer: View {
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager

    var body: some View {
        PlayerView()
            .environment(\.locale, Locale(identifier: languageManager.currentLanguage))
            // Appearance is applied via UIWindow.overrideUserInterfaceStyle in ThemeManager.
            // Only rebuild the tree on language change, NOT on theme change — otherwise the screen goes blank.
            .id(languageManager.currentLanguage)
    }
}
