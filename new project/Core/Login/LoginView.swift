//
//  LoginView.swift
//

import SwiftUI
import SafariServices

struct LoginView: View {
    enum Mode {
        case onboarding
        case standalone
    }

    var mode: Mode = .onboarding

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var authManager: AuthManager

    @State private var showSafari: Bool = false
    @State private var safariURL: URL?

    var body: some View {
        NavigationStack {
            ZStack {
                Color.app
                    .ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 20) {

                        Image("quran_logo")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80, height: 80)
                            .padding(.top, 40)

                        HStack(spacing: 0) {
                            Text("app_name_quran")
                                .font(.custom("Avenir Next Cyr", size: 34))
                                .foregroundColor(.blue)

                            Text("app_name_pro")
                                .font(.system(size: 34))
                                .foregroundColor(.blue)
                        }

                        Text(descriptionKey)
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)

                        Button(action: handleAppleSignIn) {
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

                        secondarySignInButton

                        if mode == .onboarding {
                            NavigationLink {
                                NotificationView()
                            } label: {
                                Text("skip_button")
                                    .foregroundStyle(.secondary)
                                    .padding(.top, 8)
                            }
                        }

                        Spacer(minLength: 100)
                    }
                    .padding(.bottom, 20)
                }

                VStack {
                    Spacer()
                    TermsTextView { url in
                        openLink(url)
                    }
                    .padding(.bottom, 20)
                }
            }
            .background(Color.app.ignoresSafeArea())
            .sheet(isPresented: $showSafari) {
                if let safariURL {
                    SafariView(url: safariURL)
                }
            }
            .toolbar {
                if mode == .standalone {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.system(size: 24))
                        }
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var secondarySignInButton: some View {
        switch mode {
        case .onboarding:
            Button(action: handleSecondarySignIn) {
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

        case .standalone:
            Button(action: handleSecondarySignIn) {
                HStack {
                    Image(systemName: "g.circle.fill")
                        .font(.system(size: 18))
                    Text("sign_in_google")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.primary)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .overlay(
                    Capsule()
                        .stroke(Color.secondary.opacity(0.3), lineWidth: 1)
                )
            }
            .padding(.horizontal, 30)
        }
    }

    private var descriptionKey: LocalizedStringKey {
        mode == .onboarding ? "app_description" : "login_choose_method_description"
    }

    private func handleAppleSignIn() {
        // Real Apple Sign-In integration goes here. For now we mark the user as signed in.
        completeSignIn()
    }

    private func handleSecondarySignIn() {
        // Real Google / other provider integration goes here.
        completeSignIn()
    }

    private func completeSignIn() {
        guard mode == .standalone else { return }
        authManager.signIn()
        dismiss()
    }

    private func openLink(_ urlString: String) {
        if let url = URL(string: urlString) {
            safariURL = url
            showSafari = true
        }
    }
}

struct SafariView: UIViewControllerRepresentable {
    let url: URL

    func makeUIViewController(context: Context) -> SFSafariViewController {
        return SFSafariViewController(url: url)
    }

    func updateUIViewController(_ uiViewController: SFSafariViewController, context: Context) { }
}

struct TermsTextView: View {

    var linkAction: (String) -> Void

    var body: some View {
        HStack(spacing: 0) {
            Text("terms_prefix")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text("terms_of_service")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .onTapGesture {
                    linkAction("https://www.google.com")
                }

            Text("terms_and")
                .font(.system(size: 10))
                .foregroundColor(.secondary)

            Text("privacy_policy")
                .font(.system(size: 10))
                .foregroundColor(.red)
                .onTapGesture {
                    linkAction("https://www.google.com")
                }
        }
        .lineLimit(1)
        .truncationMode(.tail)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 20)
    }
}
