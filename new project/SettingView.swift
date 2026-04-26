import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var languageManager: AppLanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    @State private var showLogin = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Sign In Card
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.card)
                        .frame(height: 100)
                        .overlay(
                            HStack {
                                Image(systemName: "person.circle.fill")
                                    .font(.largeTitle)
                                    .foregroundColor(.gray)

                                VStack(alignment: .leading) {
                                    Text("settings_sign_in")
                                        .foregroundColor(.red)
                                        .font(.headline)

                                    Text("settings_sign_in_subtitle")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                        )
                        .onTapGesture {
                            showLogin = true
                        }

                    // Premium & Update buttons
                    HStack(spacing: 15) {
                        smallCard(
                            icon: "star.fill",
                            circleColor: .pink,
                            title: "settings_premium",
                            subtitle: "settings_premium_subtitle"
                        )
                        smallCard(
                            icon: "gear",
                            circleColor: .blue,
                            title: "settings_update",
                            subtitle: "settings_update_subtitle"
                        )
                    }

                    // Membership
                    VStack(spacing: 0) {
                        settingRow(title: "settings_membership_benefits", icon: "rosette", circleColor: .red)
                    }
                    .background(Color.card)
                    .cornerRadius(15)

                    // MARK: Appearance
                    sectionTitle("settings_section_appearance")

                    VStack(spacing: 0) {
                        NavigationLink(destination: AppearanceView().environmentObject(themeManager)) {
                            settingRow(title: "settings_appearance", icon: "lightbulb.fill", circleColor: .red)
                        }
                        .buttonStyle(PlainButtonStyle())
                        divider()
                        NavigationLink(destination: ColorSelectionView().environmentObject(themeManager)) {
                            settingRow(title: "settings_color", icon: "eyedropper", circleColor: .purple)
                        }
                        .buttonStyle(PlainButtonStyle())
                        divider()
                        settingRow(title: "settings_app_icon", icon: "app.fill", circleColor: .green)
                        divider()
                        NavigationLink(destination: NotificationsView().environmentObject(themeManager)) {
                            settingRow(title: "settings_notifications", icon: "bell.fill", circleColor: .blue)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                    .background(Color.card)
                    .cornerRadius(15)

                    // MARK: Advanced
                    sectionTitle("settings_section_advanced")

                    VStack(spacing: 0) {
                        settingRow(title: "settings_audio_quality", icon: "headphones", circleColor: .red)
                        divider()
                        settingRow(title: "settings_font", icon: "textformat", circleColor: .purple)
                        divider()
                        settingRow(title: "settings_translation_manager", icon: "globe", circleColor: .blue)
                        divider()
                        settingRow(title: "settings_download_manager", icon: "square.and.arrow.down.fill", circleColor: .blue)
                        divider()
                        NavigationLink(destination: LanguageSelectionView().environmentObject(languageManager)) {
                            settingRow(title: "settings_language", icon: "globe", circleColor: .gray)
                        }
                        .buttonStyle(PlainButtonStyle())
                        divider()
                        settingRow(title: "settings_clear_cache", icon: "hammer.fill", circleColor: .blue)
                        divider()
                        settingRow(title: "settings_pair_tv_app", icon: "tv", circleColor: .black)
                    }
                    .background(Color.card)
                    .cornerRadius(15)

                    // MARK: Support
                    sectionTitle("settings_section_support")

                    VStack(spacing: 0) {
                        settingRow(title: "settings_support", icon: "heart.fill", circleColor: .green)
                        divider()
                        settingRow(title: "settings_rate_us", icon: "star.fill", circleColor: .blue)
                        divider()
                        settingRow(title: "settings_social_media", icon: "square.and.arrow.up.fill", circleColor: .yellow)
                        divider()
                        settingRow(title: "settings_our_apps", icon: "list.bullet", circleColor: .blue)
                        divider()
                        settingRow(title: "privacy_policy", icon: "lock.fill", circleColor: .green)
                        divider()
                        settingRow(title: "terms_of_service", icon: "person.3.fill", circleColor: .purple)
                        divider()
                        settingRow(title: "settings_credits", icon: "house.fill", circleColor: .red)
                    }
                    .background(Color.card)
                    .cornerRadius(15)

                }
                .padding()
                .navigationTitle("settings_title")
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .clipShape(Circle())
                        }
                    }
                }
            }
            .background(Color.app)
        }
    }

    // MARK: - Helper Views

    func settingRow(title: LocalizedStringKey, icon: String, circleColor: Color) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(circleColor)
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .foregroundColor(.white)
            }

            Text(title)
                .foregroundColor(.primary)

            Spacer()

            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
        }
        .padding()
        .background(Color.card)
    }

    func smallCard(
        icon: String,
        circleColor: Color,
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey,
        action: @escaping () -> Void = {}
    ) -> some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                ZStack {
                    Circle()
                        .fill(circleColor)
                        .frame(width: 40, height: 40)
                    Image(systemName: icon)
                        .foregroundColor(.white)
                }

                Text(title).font(.headline)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.card)
            .cornerRadius(15)
        }
        .buttonStyle(PlainButtonStyle())
    }

    func sectionTitle(_ text: LocalizedStringKey) -> some View {
        Text(text)
            .font(.subheadline)
            .frame(maxWidth: .infinity, alignment: .leading)
            .foregroundColor(.gray)
    }

    func divider() -> some View {
        Divider().padding(.leading, 50)
    }
}
