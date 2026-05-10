//
//  RootView.swift
//

import SwiftUI

struct RootView: View {
    @AppStorage(UserDefaultsManager.Keys.hasCompletedOnboarding) private var hasCompletedOnboarding: Bool = false

    var body: some View {
        QuranApp()
            .sheet(isPresented: showOnboardingBinding) {
                LoginView()
                    .interactiveDismissDisabled(true)
            }
    }

    private var showOnboardingBinding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { _ in }
        )
    }
}
