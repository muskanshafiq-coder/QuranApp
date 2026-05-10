//
//  QuranApp.swift
//

import SwiftUI

struct QuranApp: View {
    var body: some View {
        MainTabBarRepresentable()
    }
}
struct MainTabBarRepresentable: UIViewControllerRepresentable {
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    func makeUIViewController(context: Context) -> MainTabBarController {
        MainTabBarController(
            languageManager: languageManager,
            themeManager: themeManager,
            selectedThemeColorManager: selectedThemeColorManager
        )
    }

    func updateUIViewController(_ uiViewController: MainTabBarController, context: Context) {
        uiViewController.applyEnvironment(
            languageManager: languageManager,
            themeManager: themeManager,
            selectedThemeColorManager: selectedThemeColorManager
        )
    }
}
