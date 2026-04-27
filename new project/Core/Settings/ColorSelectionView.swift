//
//  ColorSelectionView.swift
//  new project
//
//  Created by Muhammad Ahsan on 26/04/2026.
//

import SwiftUI
struct AppColorTheme: Identifiable {
    let id: String
    let color: Color
    let isPremium: Bool

    static let allThemes: [AppColorTheme] = [
        AppColorTheme(id: "red", color: Color(hex: "fb2d54"), isPremium: false),
        AppColorTheme(id: "pink", color: Color(hex: "e73b63"), isPremium: false),
        AppColorTheme(id: "blue", color: Color(hex: "5c9ceb"), isPremium: false),
        AppColorTheme(id: "cyan", color: Color(hex: "4fc0e8"), isPremium: false),
        AppColorTheme(id: "purple", color: Color(hex: "aa91ec"), isPremium: false),
        AppColorTheme(id: "mint", color: Color(hex: "ed87c1"), isPremium: false),
        AppColorTheme(id: "teal", color: Color(hex: "49ceaf"), isPremium: false),
        AppColorTheme(id: "gray", color: Color(hex: "676d79"), isPremium: false)
    ]

    static func theme(for id: String) -> AppColorTheme? {
        allThemes.first(where: { $0.id == id })
    }
}
struct ColorSelectionView: View {
    
    @EnvironmentObject var selectedThemeColorManager: SelectedThemeColorManager
    
    private let columns = Array(repeating: GridItem(.flexible()), count: 4)
    
    var body: some View {
        VStack {
            LazyVGrid(columns: columns, spacing: 20) {
                ForEach(AppColorTheme.allThemes) { theme in
                    ColorItemView(theme: theme)
                }
            }
            .padding()
        }
        .navigationTitle("Appearance")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.app)
    }
}
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)

        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
