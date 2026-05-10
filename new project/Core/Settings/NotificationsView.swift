//
//  NotificationsView.swift
//

import SwiftUI

struct NotificationsView: View {
    
    @Environment(\.dismiss) var dismiss
    
    @State private var dailySurah = true
    @State private var kahfReminder = true
    @State private var promotional = true
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                notificationToggle(
                    title: "daily_surah_title",
                    subtitle: "daily_surah_subtitle",
                    isOn: $dailySurah
                )
                
                notificationToggle(
                    title: "kahf_title",
                    subtitle: "kahf_subtitle",
                    isOn: $kahfReminder
                )
                
                notificationToggle(
                    title: "promo_title",
                    subtitle: "promo_subtitle",
                    isOn: $promotional
                )
                
                Spacer(minLength: 20) // 👈 fix for ScrollView
            }
            .padding()
        }
        .navigationTitle("Notifications")
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.app)
    }
    
    // ✅ OUTSIDE body
    func notificationToggle(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        isOn: Binding<Bool>
    ) -> some View {
        
        VStack(alignment: .leading, spacing: 6) {
            
            // ✅ Card (ONLY title + toggle)
            HStack {
                Text(title)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Toggle("", isOn: isOn)
                    .labelsHidden()
            }
            .padding()
            .background(Color.card)
            .cornerRadius(15)
            
            // ✅ Subtitle OUTSIDE the card
            Text(subtitle)
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.horizontal, 4) // slight alignment tweak
        }
    }
}
