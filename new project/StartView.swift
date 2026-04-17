import SwiftUI

struct PlayerView: View {
    
    @State private var showSettings = false
    @EnvironmentObject private var languageManager: AppLanguageManager
    @EnvironmentObject private var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            VStack{
                
            }
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
    
    /// Resolves `Localizable.strings` for the in-app language (not only system locale).
    private func localized(_ key: String) -> String {
        let language = languageManager.currentLanguage
        guard let path = Bundle.main.path(forResource: language, ofType: "lproj"),
              let bundle = Bundle(path: path) else {
            return NSLocalizedString(key, comment: "")
        }
        return bundle.localizedString(forKey: key, value: nil, table: nil)
    }
}
