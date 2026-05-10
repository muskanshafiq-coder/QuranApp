//
//  ThemeManager.swift
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
final class ThemeManager: ObservableObject {
    
    private static let storageKey = "appearanceMode"
    
    // MARK: - Appearance (Light/Dark)
    @Published var appearanceMode: AppearanceMode {
        didSet {
            guard appearanceMode != oldValue else { return }
            UserDefaults.standard.set(appearanceMode.rawValue, forKey: Self.storageKey)
            Self.applyToAllWindows(appearanceMode)
        }
    }
    
    // MARK: - Init
    init() {
        let raw: Int
        if UserDefaults.standard.object(forKey: Self.storageKey) == nil {
            raw = AppearanceMode.auto.rawValue
        } else {
            raw = UserDefaults.standard.integer(forKey: Self.storageKey)
        }
        
        let mode = AppearanceMode(rawValue: raw) ?? .auto
        self.appearanceMode = mode
        
        Self.applyToAllWindows(mode)
    }
    
    // MARK: - Apply Appearance
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
