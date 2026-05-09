//
//  BookMarksView.swift
//  new project
//
//  Created by Muhammad Ahsan on 09/05/2026.
//

import SwiftUI

struct BookmarksView: View {
    
    @Environment(\.colorScheme) private var colorScheme
    
    var body: some View {
        
        NavigationStack {
            
            ScrollView(showsIndicators: false) {
                
                VStack(alignment: .leading, spacing: 26) {
                    
                    // MARK: Audio Section
                    
                    VStack(alignment: .leading, spacing: 14) {
                        
                        Text("audio_title")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        bookmarkCard(
                            title: "no_surah_title",
                            subtitle: "add_audio_bookmark"
                        )
                    }
                    
                    
                    // MARK: Reading Section
                    
                    VStack(alignment: .leading, spacing: 14) {
                        
                        Text("reading_title")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(primaryTextColor)
                        
                        bookmarkCard(
                            title: "no_bookmarks_title",
                            subtitle: "add_text_bookmark"
                        )
                    }
                    
                    Spacer(minLength: 120)
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
            }
            .background(backgroundColor.ignoresSafeArea())
            .navigationTitle("bookmarks_title")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}

// MARK: - Dynamic Colors

extension BookmarksView {
    
    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color.app
    }
    
    private var primaryTextColor: Color {
        colorScheme == .dark ? .white : .black
    }
    
    private var secondaryTextColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.45)
        : Color.black.opacity(0.45)
    }
    
    private var titleCardTextColor: Color {
        colorScheme == .dark
        ? Color.white.opacity(0.55)
        : Color.black.opacity(0.55)
    }
}

#Preview {
    BookmarksView()
}

extension BookmarksView {
    
    func bookmarkCard(
        title: LocalizedStringKey,
        subtitle: LocalizedStringKey
    ) -> some View {
        
        Button {
            print(title)
        } label: {
            
            VStack(spacing: 10) {
                
                Text(title)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(titleCardTextColor)
                
                Text(subtitle)
                    .font(.system(size: 16))
                    .foregroundColor(secondaryTextColor)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .background(
                RoundedRectangle(cornerRadius: 28)
                    .fill(Color.card)
            )
        }
        .buttonStyle(PlainButtonStyle())
    }
}
