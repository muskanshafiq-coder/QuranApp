//
//  AppLanguageManager.swift
//

import SwiftUI
import Combine

class AppLanguageManager: ObservableObject {
    @Published var currentLanguage: String {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }
    
    init() {
        self.currentLanguage = UserDefaults.standard.string(forKey: "appLanguage") ?? "en"
    }
}
