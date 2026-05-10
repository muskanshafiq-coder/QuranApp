//
//  AuthManager.swift
//

import Foundation
import Combine

/// Centralised authentication state.
/// Other features should observe `isSignedIn` (e.g. via `@EnvironmentObject`)
/// instead of reading `UserDefaults` directly, so we have one consistent source of truth.
final class AuthManager: ObservableObject {
    static let shared = AuthManager()

    @Published private(set) var isSignedIn: Bool = true

    private let storage: UserDefaultsManager

    init(storage: UserDefaultsManager = .shared) {
        self.storage = storage
        self.isSignedIn =  true //storage.isSignedIn()
    }

    /// Mark the current user as signed in.
    /// In a real implementation this would be called after a successful Apple/Google handshake.
    func signIn() {
        guard !isSignedIn else { return }
        isSignedIn = true
        storage.setSignedIn(true)
    }

    /// Clear the signed-in flag.
    func signOut() {
        guard isSignedIn else { return }
        isSignedIn = false
        storage.setSignedIn(false)
    }

    /// Display name used in share text until a profile name is wired from sign-in.
    var playlistShareDisplayName: String {
        NSLocalizedString("playlist_share_default_user", comment: "")
    }
}
