//
//  ColorItemView.swift
//  new project
//
//  Created by Muhammad Ahsan on 26/04/2026.
//
import SwiftUI
struct ColorItemView: View {
    
    let theme: AppColorTheme
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        ZStack {
            Circle()
                .fill(theme.color)
                .frame(width: 70, height: 70)
            
            if themeManager.selectedThemeID == theme.id {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            if theme.isPremium && !themeManager.isPremiumUser {
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .scaleEffect(themeManager.selectedThemeID == theme.id ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: themeManager.selectedThemeID)
        .onTapGesture {
            if theme.isPremium && !themeManager.isPremiumUser {
                print("🔒 Show Paywall")
            } else {
                themeManager.applyColor(theme)
            }
        }
    }
}
