import SwiftUI
import SafariServices

struct LoginView: View {
    
    @State private var showNotificationSheet = false
    @State private var showSafari: Bool = false
    @State private var safariURL: URL?
    
    var body: some View {
        NavigationView {
            ZStack {
                // MARK: Scrollable content
                ScrollView {
                    VStack(spacing: 20) {
                        
                        // Logo
                        Image("quran_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.top, 40)
                        
                        // App Name
                        HStack(spacing: 0) {
                            Text("app_name_quran")
                                .font(.custom("Avenir Next Cyr", size: 34))
                                .foregroundColor(.blue)
                            
                            Text("app_name_pro")
                                .font(.system(size: 34))
                                .foregroundColor(.blue)
                        }
                        
                        // Description
                        Text("app_description")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                        
                        // Sign in with Apple
                        Button {
                            print("Apple sign in")
                        } label: {
                            HStack {
                                Image(systemName: "applelogo")
                                Text("sign_in_apple")
                                    .fontWeight(.semibold)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.primary)
                            .foregroundColor(Color(UIColor.systemBackground))
                            .clipShape(Capsule())
                        }
                        .padding(.horizontal, 30)
                        
                        // Other Sign-in Options
                        Button {
                            print("Other sign in options")
                        } label: {
                            Text("other_sign_in_options")
                                .fontWeight(.semibold)
                                .foregroundStyle(.pink)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .overlay(
                                    Capsule()
                                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                                )
                        }
                        .padding(.horizontal, 30)
                        
                        // Skip Button
                        Button("skip_button") {
                            showNotificationSheet = true
                        }
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                        
                        Spacer(minLength: 100) // Reserve space for bottom text
                    }
                    .padding(.bottom, 20)
                }
                
                // MARK: Fixed bottom Terms & Privacy
                VStack {
                    Spacer()
                    TermsTextView { url in
                        openLink(url)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color(.systemBackground))
            NavigationLink(
                                destination: NotificationView()
                                    .navigationBarBackButtonHidden(true),
                                isActive: $showNotificationSheet
                            ) {
                                EmptyView() // Hidden link
                            }            .sheet(isPresented: $showSafari) {
                if let safariURL = safariURL {
                    SafariView(url: safariURL)
                }
            }
        }
    }
    
    // MARK: Open link in SafariView
    private func openLink(_ urlString: String) {
        if let url = URL(string: urlString) {
            safariURL = url
            showSafari = true
        }
    }
}

// MARK: - SafariView for in-app browser
struct SafariView: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }
    
    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

// MARK: - TermsTextView for fixed bottom links
struct TermsTextView: View {
    
    var linkAction: (String) -> Void
    
    var body: some View {
        HStack(spacing: 0) {
            // Normal text
            Text("terms_prefix")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            // Terms of Service link
            Text("terms_of_service")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .onTapGesture {
                    linkAction("https://www.google.com") // your TOS link
                }
            
            // " and " text
            Text("terms_and")
                .font(.system(size: 10))
                .foregroundColor(.secondary)
            
            // Privacy Policy link
            Text("privacy_policy")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .onTapGesture {
                    linkAction("https://www.google.com") // your Privacy link
                }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
    }
}

// Helper to convert LocalizedStringKey to String
extension LocalizedStringKey {
    func stringValue() -> String {
        let mirror = Mirror(reflecting: self)
        if let storage = mirror.descendant("key") as? String {
            return storage
        }
        return ""
    }
}
