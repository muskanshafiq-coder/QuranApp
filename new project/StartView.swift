import SwiftUI

struct PlayerView: View {
    
    @State private var showSettings = false
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ScrollView{
                VStack{
                    VStack(alignment: .leading, spacing: 20) {
                        // MARK: - Menu Items
                        VStack(spacing: 0) {
                            
                            PlayerRow(title: "playlists_title") {
                                print("Playlists tapped")
                            }
                            
                            Divider()
                            
                            PlayerRow(title: "dua_ruqia_title") {
                                print("Dua & Ruqia tapped")
                            }
                            
                            Divider()
                            
                            PlayerRow(title: "popular_favorites_title") {
                                print("Most Popular & Favorites tapped")
                            }
                        }
                        .background(Color(.systemGray6).opacity(0.1))
                        .cornerRadius(12)
                        ReviewBanner()
                            .frame(maxWidth: .infinity)

                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationTitle("player_title")
            .background(Color.app)
            .toolbar {
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {}) {
                        Text("share_title")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {}) {
                        Text("upgrade_title")
                    }
                }
                if #available(iOS 26.0, *) {
                    ToolbarSpacer(placement: .topBarTrailing)
                }
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
        }
        .fullScreenCover(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
        }
    }
}
struct ReviewBanner: View {
    
    @State private var isVisible: Bool = true
    
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
                            .foregroundColor(.red)
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
                        .foregroundColor(.red)
                }
            }
            .padding()
            .frame(maxWidth: 400)
                    .frame(maxWidth: .infinity)

            
            // 👉 BOX STYLE HERE
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.secondarySystemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
            )
            .shadow(color: Color.black.opacity(0.2), radius: 6, x: 0, y: 2)
            
            .padding(.horizontal)
        }
    }
}
struct PlayerRow: View {
    let title: LocalizedStringKey
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .foregroundColor(.red) // match your UI
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundColor(.gray)
            }
            .padding()
        }
    }
}
