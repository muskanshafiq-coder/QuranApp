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
                                    AudioBookmarkSurahRowView(
                                        bookmark: bookmark,
                                        listPosition: idx + 1,
                                        accentColor: selectedThemeColorManager.selectedColor,
                                        preferredReciterId: $preferredAudioReciterId,
                                        onDownloadTap: { showDownloadManager = true },
                                        onRemoveBookmark: {
                                            audioBookmarksViewModel.remove(id: bookmark.id)
                                        }
                                    )
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
                    AudioBookmarkSurahRowView(
                        bookmark: bookmark,
                        listPosition: idx + 1,
                        accentColor: selectedThemeColorManager.selectedColor,
                        preferredReciterId: $preferredAudioReciterId,
                        onDownloadTap: { showDownloadManager = true },
                        onRemoveBookmark: {
                            audioBookmarksViewModel.remove(id: bookmark.id)
                        }
                    )
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

// MARK: - Audio bookmark row (matches reciter surah list styling)

private struct AudioBookmarkSurahRowView: View {
    let bookmark: AudioSurahBookmark
    /// 1-based row index in the current list (bookmark order).
    let listPosition: Int
    let accentColor: Color
    @Binding var preferredReciterId: String
    let onDownloadTap: () -> Void
    let onRemoveBookmark: () -> Void

    private let rowHPadding: CGFloat = 14

    private var combinedTitle: String {
        let en = bookmark.surahTitleEn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ar = bookmark.surahTitleAr?.trimmingCharacters(in: .whitespacesAndNewlines), !ar.isEmpty else {
            return en
        }
        return "\(en) \(ar)"
    }

    private var portraitURL: URL? {
        bookmark.portraitURLString.flatMap { URL(string: $0) }
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(listPosition)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(width: 28, alignment: .leading)

            avatar
                .padding(.leading, 2)

            NavigationLink {
                PlayerReciterSurahListView(
                    reciter: bookmark.asPlayerReciterDisplayItem(),
                    preferredReciterId: $preferredReciterId
                )
            } label: {
                VStack(alignment: .leading, spacing: 4) {
                    Text(combinedTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.leading)
                        .lineLimit(2)
                        .minimumScaleFactor(0.85)
                    Text(bookmark.reciterNameEn)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.leading, 8)

            Button(action: onDownloadTap) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)

            Menu {
                Button(role: .destructive, action: onRemoveBookmark) {
                    Label("bookmarks_audio_remove", systemImage: "bookmark.slash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28)
                    .foregroundStyle(accentColor)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, rowHPadding)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(Color.card)
        )
    }

    @ViewBuilder
    private var avatar: some View {
        Group {
            if let url = portraitURL {
                CachedRemoteImage(url: url)
                    .aspectRatio(contentMode: .fill)
                    .frame(width: 48, height: 48)
                    .clipShape(Circle())
            } else {
                Circle()
                    .fill(Color.primary.opacity(0.08))
                    .frame(width: 48, height: 48)
                    .overlay {
                        Image(systemName: "person.fill")
                            .font(.system(size: 20, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
            }
        }
        .accessibilityHidden(true)
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
