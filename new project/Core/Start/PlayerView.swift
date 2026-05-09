struct Reciter: Identifiable {
    let id = UUID()
    let name: String
    let image: String
}


import SwiftUI

struct PlayerView: View {
    
    @State private var showSettings = false
    @State private var showSignInRequiredAlert = false
    @State private var showLoginSheet = false
    @State private var navigateToPlaylists = false
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @EnvironmentObject private var authManager: AuthManager

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Menu Items
                        VStack(spacing: 0) {
                            
                            PlayerRow(title: "playlists_title") {
                                handlePlaylistsTap()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            PlayerRow(title: "dua_ruqia_title") {
                                print("Dua & Ruqia tapped")
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            PlayerRow(title: "popular_favorites_title") {
                                print("Most Popular & Favorites tapped")
                            }
                        }
                        
                        ReviewBanner()
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    
                        Text("Features")
                            .font(.largeTitle)
                            .padding(.horizontal)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            
                            FeatureCard(title: "Gift of Ramadan", subtitle: "Editor`s Pick", image: "feature1")
                            FeatureCard(title: "Adhkar", subtitle: "Morning & Evening", image: "feature2")
                            FeatureCard(title: "99 Names", subtitle: "of Allah", image: "feature2")
                            FeatureCard(title: "Daily Duas", subtitle: "", image: "feature1")
                            FeatureCard(title: "Stories", subtitle: "of Prophets", image: "feature2")
                            FeatureCard(title: "Stories", subtitle: "of Prophets", image: "feature1")
                            FeatureCard(title: "Stories", subtitle: "of Prophets", image: "feature2")
                            FeatureCard(title: "Stories", subtitle: "of Prophets", image: "feature1")
                            FeatureCard(title: "Stories", subtitle: "of Prophets", image: "feature2")
                        }
                        .padding(.horizontal, 4)
                    }
                    Text("Expertly curated playlists of the world's best voice of the moment")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .lineLimit(2)
                }
                let reciters: [Reciter] = [
                    Reciter(name: "Yasser Al-Dosari", image: "reciter1"),
                    Reciter(name: "Mishary Rashid Alafasy", image: "reciter1"),
                    Reciter(name: "Maher Al Mueaqly", image: "reciter1"),
                    Reciter(name: "Fatih Seferagic", image: "reciter1"),
                    Reciter(name: "Abdul Rahman Al Sudais", image: "reciter1"),
                    Reciter(name: "Abdullah Al-Johany", image: "reciter1"),
                    Reciter(name: "Saad El Ghamidi", image: "reciter1")
                ]
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Header
                    HStack {
                        Text("All Reciters")
                            .font(.headline)
                        
                        Spacer()
                        
                        Button("See All") {
                            print("See all tapped")
                        }
                        .foregroundColor(.red)
                        .font(.caption)
                    }
                    
                    // Horizontal list
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 16) {
                            ForEach(reciters) { reciter in
                                ReciterItem(reciter: reciter)
                            }
                        }
                        .padding(.horizontal, 4)
                    }
                }
                .padding() // 👈 inner spacing
                .background(Color(.systemGray5)) // 👈 ONE gray frame
                .cornerRadius(16) // 👈 rounded like iOS cards
                .padding(.horizontal)
            }
            .navigationTitle("player_title")
            .navigationDestination(isPresented: $navigateToPlaylists) {
                PlaylistsView()
                    .environmentObject(authManager)
                    .environmentObject(languageManager)
                    .environmentObject(themeManager)
                    .environmentObject(selectedThemeColorManager)
            }
            .background(Color.app.ignoresSafeArea())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: shareApp) {
                        Text("share_title")
                    }
                }
            }
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Menu {
                        Button {
                            print("Notifications tapped")
                        } label: {
                            Label("notifications_title", systemImage: "bell")
                        }
                        
                        Button {
                            showSettings = true
                        } label: {
                            Label("settings_title", systemImage: "gear")
                        }
                        
                    } label: {
                        Image(systemName: "ellipsis")
                    }
                }
            }
            .toolbarSpacerIfAvailable()
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Text("upgrade_title")
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
        }
        .alert("auth_registered_users_title", isPresented: $showSignInRequiredAlert) {
            Button("alert_cancel", role: .cancel, action: {})
            Button("alert_sign_in") { showLoginSheet = true }
        } message: {
            Text("auth_registered_users_message")
        }
        .sheet(isPresented: $showLoginSheet, onDismiss: handleLoginSheetDismissed) {
            LoginView(mode: .standalone)
                .environmentObject(authManager)
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
        }
    }

    /// After the login sheet closes, send the (now-signed-in) user straight into
    /// Playlists so they don't have to tap the row a second time.
    private func handleLoginSheetDismissed() {
        if authManager.isSignedIn {
            navigateToPlaylists = true
        }
    }

    private func handlePlaylistsTap() {
        if authManager.isSignedIn {
            navigateToPlaylists = true
        } else {
            showSignInRequiredAlert = true
        }
    }

    private func shareApp() {
        let message = NSLocalizedString("share_message", comment: "Share app message")
        ShareHelper.presentShareSheet(items: [message])
    }
}


struct ReviewBanner: View {
    
    @State private var isVisible: Bool = true
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    
    var body: some View {
        if isVisible {
            HStack(alignment: .top, spacing: 12) {
                
                Image("app_icon")
                    .resizable()
                    .frame(width: 40, height: 40)
                    .cornerRadius(8)
                
                VStack(alignment: .leading, spacing: 6) {
                    
                    Text("salam_title")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("review_message")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .lineLimit(2)
                    
                    Divider()
                    
                    Button(action: {
                        print("Rate app tapped")
                    }) {
                        Text("rate_app_title")
                            .foregroundColor(selectedThemeColorManager.selectedColor)
                            .fontWeight(.semibold)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isVisible = false
                    }
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(selectedThemeColorManager.selectedColor)
                }
            }
            .padding()
            .frame(maxWidth: 400)
            .frame(maxWidth: .infinity)
            
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .padding(.horizontal)
        }
    }
}

struct PlayerRow: View {
    let title: LocalizedStringKey
    let action: () -> Void
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            PlayerRowButtonStyle(
                title: title,
                titleColor: selectedThemeColorManager.selectedColor,
                highlightColor: selectedThemeColorManager.selectedColor
            )
        )
    }
}

private struct PlayerRowButtonStyle: ButtonStyle {
    let title: LocalizedStringKey
    let titleColor: Color
    let highlightColor: Color

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        return HStack {
            Text(title)
                .foregroundColor(isPressed ? .white : titleColor)

            Spacer()

            Image(systemName: "chevron.forward")
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(isPressed ? highlightColor : Color.clear)
        .contentShape(Rectangle())
    }
}

private extension View {
    @ViewBuilder
    func toolbarSpacerIfAvailable() -> some View {
        if #available(iOS 26.0, *) {
            self.toolbar {
                ToolbarSpacer(placement: .topBarTrailing)
            }
        } else {
            self
        }
    }
}

@ViewBuilder
func bottomButton(title: String, icon: String) -> some View {
    
    Button(action: {
        print("\(title) tapped")
    }) {
        VStack(spacing: 4) {
            
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            
            Text(title)
                .font(.caption2)
        }
        .foregroundColor(.gray)
        .frame(maxWidth: .infinity) // 👈 IMPORTANT (equal width)
        .padding(.vertical, 10)
    }
}

struct FeatureCard: View {
    
    let title: String
    let subtitle: String
    let image: String
    
    var body: some View {
        Button(action: {
            print("\(title) tapped")
        }) {
            ZStack(alignment: .bottom) {
                
                Image(image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 200, height: 250)
                    .clipped()
                    .cornerRadius(16)
                
                HStack {
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .fontWeight(.bold)
                            .foregroundColor(.black)
                        
                        if !subtitle.isEmpty {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.gray.opacity(0.8))
                        }
                    }
                    
                    Spacer()
                    
                    Image(systemName: "play.fill")
                        .foregroundColor(.black)
                        .padding(8)
                        .background(Color.white)
                        .clipShape(Circle())
                }
                .padding(10)
                .background(
                    Color.gray.opacity(0.6)
                )
                .cornerRadius(12)
                .padding(6)
            }
            .frame(width: 200, height: 250)
        }
    }
}
struct ReciterItem: View {
    
    let reciter: Reciter
    
    var body: some View {
        VStack(spacing: 6) {
            
            Image(reciter.image)
                .resizable()
                .scaledToFill()
                .frame(width: 70, height: 70)
                .clipShape(Circle())
            
            Text(reciter.name)
                .font(.caption)
                .multilineTextAlignment(.center)
                .frame(width: 80)
        }
    }
}
