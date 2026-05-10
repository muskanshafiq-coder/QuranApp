//
//  PlayerView.swift
//

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
    @ObservedObject private var playlistsViewModel = PlaylistsViewModel.shared
    @ObservedObject private var favoriteRecitersViewModel = FavoriteRecitersViewModel.shared
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @EnvironmentObject private var authManager: AuthManager
    @State private var navigateToPopularReciters = false
    @State private var navigateToAllReciters = false
    @State private var navigateToDuaRuqia = false
    @State private var popularReciterItems: [PlayerReciterDisplayItem] = []
    @State private var recitersLoading = false
    @State private var playerReciterItems: [PlayerReciterDisplayItem] = []
    @State private var recitersLoadFailed = false
    @State private var featuredReciterItems: [PlayerReciterDisplayItem] = []
    @AppStorage(UserDefaultsManager.Keys.quranPreferredAudioReciterEdition) private var preferredAudioReciterId: String = ""

    // MARK: - All Reciters grid layout
    /// Minimum row height for `PlayerReciterAvatarCell` (112pt + label stack).
    private let allRecitersRowMinHeight: CGFloat = 154

    /// Two flexible rows: each can grow with available space but never
    /// collapses below the cell's intrinsic content height.
    private var allRecitersGridRows: [GridItem] {
        [
            GridItem(.flexible(minimum: allRecitersRowMinHeight), spacing: 16),
            GridItem(.flexible(minimum: allRecitersRowMinHeight), spacing: 16)
        ]
    }

    /// Total min height of the grid (2 rows + inter-row spacing). Reused for
    /// the loading-state placeholder so the layout doesn't jump.
    private var allRecitersGridMinHeight: CGFloat {
        allRecitersRowMinHeight * 2 + 16
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    
                    VStack(alignment: .leading, spacing: 20) {
                        
                        // MARK: - Menu Items
                        VStack(spacing: 0) {
                            
                            PlayerRow(
                                title: "playlists_title",
                                trailingCount: playlistsViewModel.playlists.count
                            ) {
                                handlePlaylistsTap()
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            PlayerRow(title: "dua_ruqia_title") {
                                navigateToDuaRuqia = true
                            }
                            
                            Divider()
                                .padding(.horizontal)
                            PlayerRow(
                                title: "popular_favorites_title",
                                trailingCount: favoriteRecitersViewModel.favorites.count
                            ) {
                                navigateToPopularReciters = true
                            }
                        }
                        
                        ReviewBanner()
                            .frame(maxWidth: .infinity)
                        
                        Spacer()
                    }
                }
                VStack(alignment: .leading, spacing: 12) {
                    
                    Text("player_features_section_title")
                        .font(.system(size: 24))
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top)
                    if recitersLoading && featuredReciterItems.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(minHeight: 250)
                        .padding(.horizontal)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 16) {
                                ForEach(featuredReciterItems) { item in
                                    NavigationLink {
                                        PlayerReciterSurahListView(
                                            reciter: item,
                                            preferredReciterId: $preferredAudioReciterId
                                        )
                                    } label: {
                                        FeaturedReciterCard(item: item)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    Text("player_features_section_subtitle")
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                        .lineLimit(2)
                }
                VStack(alignment: .leading, spacing: 12) {
                    
                    // Header
                    HStack {
                        Text("player_all_reciters_title")
                            .font(.system(size: 24))
                            .fontWeight(.bold)
                            .padding(.horizontal)
                            .padding(.top)
                        Spacer()

                        Button("player_see_all") {
                            navigateToAllReciters = true
                        }
                        .foregroundColor(selectedThemeColorManager.selectedColor)
                        .font(.system(size: 14))
                        .fontWeight(.medium)
                        .disabled(playerReciterItems.isEmpty)
                    }
                    
                    // Horizontal list — 2 rows, spinner while loading
                    if recitersLoading && playerReciterItems.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .frame(minHeight: allRecitersGridMinHeight)
                    } else {
                        ScrollView(.horizontal, showsIndicators: false) {
                            LazyHGrid(
                                rows: allRecitersGridRows,
                                spacing: 16
                            ) {
                                ForEach(playerReciterItems) { item in
                                    NavigationLink {
                                        PlayerReciterSurahListView(
                                            reciter: item,
                                            preferredReciterId: $preferredAudioReciterId
                                        )
                                    } label: {
                                        PlayerReciterAvatarCell(
                                            item: item,
                                            diameter: 112,
                                            isSelected: preferredAudioReciterId == item.id,
                                            onSelect: nil
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 4)
                        }
                        .frame(minHeight: allRecitersGridMinHeight)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom)
                .background(.card)
            }
            .navigationTitle("player_title")
            .navigationDestination(isPresented: $navigateToPlaylists) {
                PlaylistsView()
                    .environmentObject(authManager)
                    .environmentObject(languageManager)
                    .environmentObject(themeManager)
                    .environmentObject(selectedThemeColorManager)
            }
            .navigationDestination(isPresented: $navigateToPopularReciters) {
                PlayerAllRecitersView(
                    reciters: popularReciterItems,
                    preferredReciterId: $preferredAudioReciterId,
                    reciterCatalogExtras: playerReciterItems
                )
                    .environmentObject(authManager)
                    .environmentObject(languageManager)
                    .environmentObject(themeManager)
                    .environmentObject(selectedThemeColorManager)
            }
            .navigationDestination(isPresented: $navigateToAllReciters) {
                PlayerAllRecitersView(
                    reciters: playerReciterItems,
                    preferredReciterId: $preferredAudioReciterId,
                    showSegmentedPicker: false
                )
                .environmentObject(authManager)
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
            }
            .navigationDestination(isPresented: $navigateToDuaRuqia) {
                PlayerReciterSurahListView(
                    reciter: PlayerReciterDisplayItem(id: PlayerReciterSegment.duaa.slug),
                    preferredReciterId: $preferredAudioReciterId,
                    segments: PlayerReciterSegment.allCases
                )
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
            .task { await loadReciters() }
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
    private func loadReciters(force: Bool = false) async {
        guard !recitersLoading else { return }
        if !force && !playerReciterItems.isEmpty { return }
        recitersLoadFailed = false
        recitersLoading = true
        let success = await ReciterRepository.loadReciters(update: applyReciters)
        recitersLoading = false
        recitersLoadFailed = !success
    }

    @MainActor
    private func applyReciters(_ dtos: [IslamicCloudReciterDTO]) {
        featuredReciterItems = dtos.filtered(by: .featured)
            .map { PlayerReciterDisplayItem(dto: $0) }
        popularReciterItems = dtos.filtered(by: .popular)
            .map { PlayerReciterDisplayItem(dto: $0) }
            .sorted { $0.englishName.localizedCaseInsensitiveCompare($1.englishName) == .orderedAscending }
        playerReciterItems = dtos.filtered(by: .all)
            .map { PlayerReciterDisplayItem(dto: $0) }
            .sorted { $0.englishName.localizedCaseInsensitiveCompare($1.englishName) == .orderedAscending }
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
    var trailingCount: Int? = nil
    let action: () -> Void
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    var body: some View {
        Button(action: action) {
            EmptyView()
        }
        .buttonStyle(
            PlayerRowButtonStyle(
                title: title,
                trailingCount: trailingCount,
                titleColor: selectedThemeColorManager.selectedColor,
                highlightColor: selectedThemeColorManager.selectedColor
            )
        )
    }
}

private struct PlayerRowButtonStyle: ButtonStyle {
    let title: LocalizedStringKey
    var trailingCount: Int?
    let titleColor: Color
    let highlightColor: Color

    func makeBody(configuration: Configuration) -> some View {
        let isPressed = configuration.isPressed
        return HStack {
            Text(title)
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(isPressed ? .white : titleColor)

            Spacer()

            if let trailingCount, trailingCount > 0 {
                Text("\(trailingCount)")
                    .font(.system(size: 17, weight: .medium))
                    .foregroundColor(isPressed ? .white.opacity(0.9) : .secondary)
                    .padding(.trailing, 4)
            }

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
