//
//  ColorItemView.swift
//

import SwiftUI
struct ColorItemView: View {
    
    let theme: AppColorTheme
    @EnvironmentObject var selectedThemeColorManager: SelectedThemeColorManager
    
    var body: some View {
        ZStack {
            Rectangle()
                .fill(theme.color)
                .frame(width: 50, height: 50)
            
            if selectedThemeColorManager.selectedThemeID == theme.id {
                Image(systemName: "checkmark")
                    .font(.title2)
                    .foregroundColor(.black)
            }
            
            if theme.isPremium && !selectedThemeColorManager.isPremiumUser {
                Image(systemName: "lock.fill")
                    .font(.body)
                    .foregroundColor(.black.opacity(0.7))
            }
        }
        .scaleEffect(selectedThemeColorManager.selectedThemeID == theme.id ? 1.1 : 1.0)
        .animation(.easeInOut(duration: 0.2), value: selectedThemeColorManager.selectedThemeID)
        .cornerRadius(40)
        .onTapGesture {
            if theme.isPremium && !selectedThemeColorManager.isPremiumUser {
                print("🔒 Show Paywall")
            } else {
                selectedThemeColorManager.applyColor(theme)
            }
        }
    }
}
