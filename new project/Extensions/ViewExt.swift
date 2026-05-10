//
//  ViewExt.swift
//

import Foundation
import SwiftUI

extension View {
    @ViewBuilder
    func placeholder<Content: View>(
        when shouldShow: Bool,
        alignment: Alignment = .leading,
        @ViewBuilder placeholder: () -> Content
    ) -> some View {
        ZStack(alignment: alignment) {
            placeholder().opacity(shouldShow ? 1 : 0)
            self
        }
    }
    
    @ViewBuilder
    func pinnedSearchable(text: Binding<String>, promptKey: LocalizedStringKey) -> some View {
        if #available(iOS 16.0, *) {
            searchable(
                text: text,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text(promptKey)
            )
        } else {
            searchable(text: text, prompt: Text(promptKey))
        }
    }
    
    @ViewBuilder
    func keepNavigationBarVisibleDuringSearch() -> some View {
        if #available(iOS 17.1, *) {
            self.searchPresentationToolbarBehavior(.avoidHidingContent)
        } else if #available(iOS 16.0, *) {
            self.toolbar(.visible, for: .navigationBar)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func playerReciterGlassNavBar() -> some View {
        if #available(iOS 16.0, *) {
            self
                .toolbarBackground(.ultraThinMaterial, for: .navigationBar)
                .toolbarBackground(.visible, for: .navigationBar)
                .toolbarColorScheme(.dark, for: .navigationBar)
        } else {
            self
        }
    }
}
