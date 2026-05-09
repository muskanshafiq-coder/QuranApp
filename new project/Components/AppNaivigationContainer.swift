//
//  AppNaivigationContainer.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import Foundation
import SwiftUI
// MARK: - Navigation container
struct AppNavigationContainer<Content: View>: View {
    private let content: Content

    init(@ViewBuilder content: () -> Content) {
        self.content = content()
    }

    var body: some View {
        if #available(iOS 16.0, *) {
            NavigationStack {
                content
            }
        } else {
            NavigationView {
                content
            }
            .navigationViewStyle(StackNavigationViewStyle())
        }
    }
}
