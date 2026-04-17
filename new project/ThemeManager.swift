//
//  ThemeManager.swift
//  new project
//
//  Created by Muhammad Ahsan on 17/04/2026.
//

import Combine
import SwiftUI
import UIKit

enum AppearanceMode: Int, CaseIterable, Identifiable {
    case auto = 0
    case light = 1
    case dark = 2

    var id: Int { rawValue }

    var colorScheme: ColorScheme? {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return nil
        }
    }

    var uiUserInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .light: return .light
        case .dark: return .dark
        case .auto: return .unspecified
        }
    }
}

/// Drives app appearance. Updates `UIWindow.overrideUserInterfaceStyle` so the whole window (including
/// `fullScreenCover` / `NavigationView`) follows the choice — `preferredColorScheme` on a nested view alone is unreliable.
final class ThemeManager: ObservableObject {
    private static let storageKey = "appearanceMode"

    @Published var appearanceMode: AppearanceMode {
        didSet {
            guard appearanceMode != oldValue else { return }
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.storageKey)
            Self.applyToAllWindows(appearanceMode)
        }
    }

    init() {
        let raw: Int
        if UserDefaults.standard.object(forKey: Self.storageKey) == nil {
            raw = AppearanceMode.auto.rawValue
        } else {
            raw = UserDefaults.standard.integer(forKey: Self.storageKey)
        }
        let mode = AppearanceMode(rawValue: raw) ?? .auto
        self.appearanceMode = mode
        // `didSet` is not always invoked for the initial assignment from `init`; apply once here.
        Self.applyToAllWindows(mode)
    }

    private static func applyToAllWindows(_ mode: AppearanceMode) {
        let style = mode.uiUserInterfaceStyle
        DispatchQueue.main.async {
            for scene in UIApplication.shared.connectedScenes {
                guard let windowScene = scene as? UIWindowScene else { continue }
                for window in windowScene.windows {
                    window.overrideUserInterfaceStyle = style
                }
            }
        }
    }
}
