//
//  BookMarksView.swift
//

import SwiftUI

struct BookmarksView: View {

    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared
    @AppStorage(UserDefaultsManager.Keys.quranPreferredAudioReciterEdition) private var preferredAudioReciterId: String = ""
    @State private var showDownloadManager = false

    private var audioBookmarksPreview: [AudioSurahBookmark] {
        Array(audioBookmarksViewModel.bookmarks.prefix(3))
    }

    var body: some View {

        NavigationStack {

            ScrollView(showsIndicators: false) {

                VStack(alignment: .leading, spacing: 26) {

                    // MARK: Audio Section

                    VStack(alignment: .leading, spacing: 14) {

                        if audioBookmarksViewModel.bookmarks.isEmpty {
                            Text("audio_title")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(primaryTextColor)

                            bookmarkCard(
                                title: "no_surah_title",
                                subtitle: "add_audio_bookmark"
                            )
                        } else {
                            HStack(alignment: .firstTextBaseline) {
                                Text("audio_title")
                                    .font(.system(size: 22, weight: .bold))
                                    .foregroundColor(primaryTextColor)

                                Spacer(minLength: 8)

                                NavigationLink {
                                    AudioBookmarksListScreen()
                                } label: {
                                    Text("bookmarks_audio_see_all")
                                        .font(.system(size: 16, weight: .semibold))
                                        .foregroundColor(selectedThemeColorManager.selectedColor)
                                }
                            }

                            VStack(spacing: 12) {
                                ForEach(Array(audioBookmarksPreview.enumerated()), id: \.element.id) { idx, bookmark in
                                    AudioSurahListRow(
                                        listPosition: idx + 1,
                                        surahTitleEn: bookmark.surahTitleEn,
                                        surahTitleAr: bookmark.surahTitleAr,
                                        ayahNumber: bookmark.ayahNumber,
                                        reciterNameEn: bookmark.reciterNameEn,
                                        portraitURLString: bookmark.portraitURLString,
                                        accentColor: selectedThemeColorManager.selectedColor,
                                        preferredReciterId: $preferredAudioReciterId,
                                        navigationReciter: bookmark.asPlayerReciterDisplayItem(),
                                        onDownloadTap: { showDownloadManager = true }
                                    ) {
                                        Menu {
                                            Button(role: .destructive, action: {
                                                audioBookmarksViewModel.remove(id: bookmark.id)
                                            }) {
                                                Label("bookmarks_audio_remove", systemImage: "bookmark.slash")
                                            }
                                        } label: {
                                            Image(systemName: "ellipsis")
                                                .font(.system(size: 16, weight: .semibold))
                                                .frame(width: 28)
                                                .foregroundStyle(selectedThemeColorManager.selectedColor)
                                        }
                                        .buttonStyle(.plain)
                                    }
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
            .onAppear {
                audioBookmarksViewModel.reloadFromStore()
            }
            .sheet(isPresented: $showDownloadManager) {
                DownloadManagerSheet()
            }
        }
    }
}

// MARK: - All audio bookmarks

private struct AudioBookmarksListScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @ObservedObject private var audioBookmarksViewModel = AudioBookmarksViewModel.shared
    @AppStorage(UserDefaultsManager.Keys.quranPreferredAudioReciterEdition) private var preferredAudioReciterId: String = ""
    @State private var showDownloadManager = false

    private var backgroundColor: Color {
        colorScheme == .dark ? .black : Color.app
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 12) {
                ForEach(Array(audioBookmarksViewModel.bookmarks.enumerated()), id: \.element.id) { idx, bookmark in
                    AudioSurahListRow(
                        listPosition: idx + 1,
                        surahTitleEn: bookmark.surahTitleEn,
                        surahTitleAr: bookmark.surahTitleAr,
                        ayahNumber: bookmark.ayahNumber,
                        reciterNameEn: bookmark.reciterNameEn,
                        portraitURLString: bookmark.portraitURLString,
                        accentColor: selectedThemeColorManager.selectedColor,
                        preferredReciterId: $preferredAudioReciterId,
                        navigationReciter: bookmark.asPlayerReciterDisplayItem(),
                        onDownloadTap: { showDownloadManager = true }
                    ) {
                        Menu {
                            Button(role: .destructive, action: {
                                audioBookmarksViewModel.remove(id: bookmark.id)
                            }) {
                                Label("bookmarks_audio_remove", systemImage: "bookmark.slash")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: 16, weight: .semibold))
                                .frame(width: 28)
                                .foregroundStyle(selectedThemeColorManager.selectedColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 120)
        }
        .background(backgroundColor.ignoresSafeArea())
        .navigationTitle("audio_title")
        .navigationBarTitleDisplayMode(.large)
        .onAppear {
            audioBookmarksViewModel.reloadFromStore()
        }
        .sheet(isPresented: $showDownloadManager) {
            DownloadManagerSheet()
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
        .environmentObject(SelectedThemeColorManager())
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
