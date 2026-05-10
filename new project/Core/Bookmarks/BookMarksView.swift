//
//  BookMarksView.swift
//  new project
//
//  Created by Muhammad Ahsan on 09/05/2026.
//

import SwiftUI

struct BookmarksView: View {

    @Environment(\.colorScheme) private var colorScheme
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared
    @AppStorage(UserDefaultsManager.Keys.quranPreferredAudioReciterEdition) private var preferredAudioReciterId: String = ""

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 26) {

                    // MARK: Audio Section

                    VStack(alignment: .leading, spacing: 14) {

                        Text("audio_title")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(primaryTextColor)

                        if audioBookmarksViewModel.bookmarks.isEmpty {
                            bookmarkCard(
                                title: "no_surah_title",
                                subtitle: "add_audio_bookmark"
                            )
                        } else {
                            VStack(spacing: 12) {
                                ForEach(audioBookmarksViewModel.bookmarks) { bookmark in
                                    NavigationLink {
                                        PlayerReciterSurahListView(
                                            reciter: bookmark.asPlayerReciterDisplayItem(),
                                            preferredReciterId: $preferredAudioReciterId
                                        )
                                    } label: {
                                        audioBookmarkRow(bookmark)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
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

    private func audioBookmarkRow(_ bookmark: AudioSurahBookmark) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(bookmark.surahTitleEn)
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(primaryTextColor)
                .lineLimit(2)
            if let ar = bookmark.surahTitleAr, !ar.isEmpty {
                Text(ar)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(secondaryTextColor)
                    .lineLimit(1)
            }
            Text(bookmark.reciterNameEn)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(secondaryTextColor)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 18)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.card)
        )
    }
}
