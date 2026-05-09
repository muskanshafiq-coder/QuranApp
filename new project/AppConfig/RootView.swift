//
//  RootView.swift
//  new project
//
//  Created by apple on 09/05/2026.
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
