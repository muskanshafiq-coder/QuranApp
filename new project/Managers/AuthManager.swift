//
//  AuthManager.swift
//  new project
//
//  Single source of truth for user sign-in state across the app.
//  Persists the signed-in flag in UserDefaults so the state survives launches.
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
}
