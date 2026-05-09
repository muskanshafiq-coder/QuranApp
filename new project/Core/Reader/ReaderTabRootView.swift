//
//  ReaderTabRootView.swift
//  new project
//
//  Created by apple on 10/05/2026.
//

import SwiftUI

/// Root for the main tab bar Reader tab; same Quran experience as More → Quran, plus book strip.
struct ReaderTabRootView: View {
    var body: some View {
        AppNavigationContainer {
            QuranView(showQuranBooksStrip: true)
        }
    }
}
//
//  QuranView.swift
//  Quran App
//

import SwiftUI
enum AllSurasNavigation {
    case normal
    case search
}

/// Context for presenting SuraDetailView, optionally scrolling to a specific ayah (e.g. from Sajda).
struct SuraDetailContext: Identifiable {
    let id = UUID()
    let surah: SurahItem
    let scrollToAyahNumber: Int?
}

struct QuranView: View {
    /// When true (Reader tab), shows the horizontal Quran books strip above the main sections.
    var showQuranBooksStrip: Bool = false

    @StateObject private var viewModel = QuranViewModel()
    @Environment(\.colorScheme) private var colorScheme
    @State private var isTranslationEnabled = false
    @State private var allSurasNavigation: AllSurasNavigation? = nil
    @State private var showBookmarks = false
    @State private var showAllJuzHizb = false
    @State private var showAllSajdas = false
    @State private var surahDetailContext: SuraDetailContext?

    private var navigationTitleKey: String {
        showQuranBooksStrip ? "tab_reader" : "quran_title"
    }

    var body: some View {
        ZStack {
            Color.app
                .ignoresSafeArea()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    if showQuranBooksStrip {
                        ReaderQuranBooksStrip()
                    }
                    continueReadingSection
                    surasSection
                    juzHizbRubuSection
                    sajdasSection
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 40)
            }
        }
        .navigationTitle(navigationTitleKey)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                HStack(spacing: 16) {
                    Button(action: { allSurasNavigation = .search }) {
                        Image(systemName: "magnifyingglass")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                    Button(action: { isTranslationEnabled.toggle() }) {
                        Image(systemName: isTranslationEnabled ? "t.circle" : "t.circle.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
            }
        }
        .onAppear {
            viewModel.refreshProgressFromStorage()
        }
        NavigationLink(
            destination: Group {
                if allSurasNavigation != nil {
                    AllSurasListView(surahs: viewModel.surahs, isTranslationEnabled: $isTranslationEnabled)
                }
            },
            isActive: Binding(
                get: { allSurasNavigation != nil },
                set: { if !$0 { allSurasNavigation = nil } }
            )
        ) {
            EmptyView()
        }
        .background(
//            NavigationLink(
//                destination: QuranBookmarksView(
//                    surahs: viewModel.surahs,
//                    isTranslationEnabled: $isTranslationEnabled
//                ),
//                isActive: $showBookmarks
//            ) {
//                EmptyView()
//            }
        )
        .background(
//            NavigationLink(
//                destination: JuzHizbRubuListView(
//                    items: viewModel.juzHizbRubuItems,
//                    surahs: viewModel.surahs,
//                    viewModel: viewModel
//                )
//                .navigationTitle("quran_juz_hizb_rubu")
//                .navigationBarTitleDisplayMode(.inline),
//                isActive: $showAllJuzHizb
//            ) {
//                EmptyView()
//            }
        )
        .background(
//            NavigationLink(
//                destination: SajdasListView(
//                    items: viewModel.sajdaItems,
//                    surahs: viewModel.surahs,
//                    viewModel: viewModel
//                )
//                .navigationTitle("quran_sajdas")
//                .navigationBarTitleDisplayMode(.inline),
//                isActive: $showAllSajdas
//            ) {
//                EmptyView()
//            }
        )
        .fullScreenCover(item: $surahDetailContext) { ctx in
//            SuraDetailView(
//                surah: ctx.surah,
//                viewModel: viewModel,
//                surahs: viewModel.surahs,
//                initialScrollToAyahNumber: ctx.scrollToAyahNumber,
//                onSwitchToSurah: { newSurah in
//                    surahDetailContext = SuraDetailContext(surah: newSurah, scrollToAyahNumber: nil)
//                }
//            )
        }
    }
    
    // MARK: - Juz, Hizb & Rubu
    private var juzHizbRubuSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quran_juz_hizb_rubu")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.label))

            if viewModel.loading && viewModel.juzHizbRubuItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if viewModel.previewJuzHizbRubu.isEmpty {
                Text("loading")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(Color(UIColor.secondaryLabel))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.previewJuzHizbRubu) { item in
                        Button {
                            if let surah = viewModel.surahs.first(where: { $0.number == item.surahNumber }) {
                                surahDetailContext = SuraDetailContext(surah: surah, scrollToAyahNumber: item.ayahNumber)
                            }
                        } label: {
                            JuzHizbRubuCard(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if item.id != viewModel.previewJuzHizbRubu.last?.id {
                            Divider()
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                    if viewModel.hasMoreJuzHizbRubu {
                        Divider()
                            .padding(.horizontal)
                        seeMoreButton { showAllJuzHizb = true }
                    }
                }
                .background(.card)
                .cornerRadius(24)
            }
        }
    }
    
    // MARK: - Sajdas
    private var sajdasSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quran_sajdas")
                .font(.title2)
                .fontWeight(.bold)
            
            if viewModel.loading && viewModel.sajdaItems.isEmpty {
                ProgressView()
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
            } else if viewModel.previewSajdas.isEmpty {
                Text("loading")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
            } else {
                VStack(spacing: 0) {
                    ForEach(viewModel.previewSajdas) { item in
                        Button {
                            if let surah = viewModel.surahs.first(where: { $0.number == item.surahNumber }) {
                                surahDetailContext = SuraDetailContext(surah: surah, scrollToAyahNumber: item.ayahNumber)
                            }
                        } label: {
                            SajdaCard(item: item)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if item.id != viewModel.previewSajdas.last?.id {
                            Divider()
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }
                    if viewModel.hasMoreSajdas {
                        Divider()
                            .padding(.horizontal)
                        seeMoreButton { showAllSajdas = true }
                    }
                }
                .background(.card)
                .cornerRadius(24)
            }
        }
    }
    
    // MARK: - Continue Reading
    private var continueReadingSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("quran_continue_reading")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.label))
            
            if viewModel.loading && viewModel.surahs.isEmpty {
                continueReadingPlaceholder
            } else if let progress = viewModel.continueReadingProgress,
                      let surah = viewModel.continueReadingSurah {
                Button {
                    surahDetailContext = SuraDetailContext(surah: surah, scrollToAyahNumber: nil)
                } label: {
                    ContinueReadingCard(progress: progress, surah: surah, isTranslationEnabled: isTranslationEnabled, showBookmarks: $showBookmarks)
                }
                .buttonStyle(PlainButtonStyle())
            } else {
                Button {
                    if let surah = viewModel.surahs.first {
                        surahDetailContext = SuraDetailContext(surah: surah, scrollToAyahNumber: nil)
                    }
                } label: {
                    continueReadingPlaceholder
                }
                .buttonStyle(PlainButtonStyle())
            }
        }
    }
    
    private var continueReadingPlaceholder: some View {
        let progress = viewModel.continueReadingProgress
        let surah = viewModel.continueReadingSurah ?? viewModel.surahs.first
        return Group {
            if let p = progress, let s = surah {
                ContinueReadingCard(progress: p, surah: s, isTranslationEnabled: isTranslationEnabled, showBookmarks: $showBookmarks)
            } else if let s = surah {
                ContinueReadingCard(
                    progress: ReadingProgress(surahNumber: s.number, ayahNumber: 1, juz: 1, hizbQuarter: 1),
                    surah: s, isTranslationEnabled: isTranslationEnabled, showBookmarks: $showBookmarks
                )
            } else {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(UIColor.secondarySystemBackground))
                    .frame(height: 100)
                    .overlay(
                        ProgressView()
                    )
            }
        }
    }
    
    // MARK: - Suras
    private var surasSection: some View {
        let vm = viewModel

        return VStack(alignment: .leading, spacing: 12) {
            Text("quran_suras")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(Color(UIColor.label))

            if vm.loading && vm.surahs.isEmpty {
                surasLoadingView
            } else {
                LazyVStack(spacing: 0) {

                    // Surah list
                    ForEach(vm.previewSurahs) { surah in
                        Button {
                            surahDetailContext = SuraDetailContext(surah: surah, scrollToAyahNumber: nil)
                        } label: {
                            SuraRowView(surah: surah, isTranslationEnabled: $isTranslationEnabled)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if surah.id != vm.previewSurahs.last?.id {
                            Divider()
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                        }
                    }

                    if vm.hasMoreSuras {
                        Divider()
                            .padding(.horizontal)
                        seeMoreButton { allSurasNavigation = .normal }
                    }
                }
                .background(.card)
                .cornerRadius(24)
            }
        }
    }

    // MARK: - Shared components
    private func seeMoreButton(action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack {
                Text("quran_see_more")
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.gray)
                    .flipsForRightToLeftLayoutDirection(true)
            }
            .padding(.horizontal)
            .padding(.vertical, 14)
        }
    }

    private var surasLoadingView: some View {
        VStack(spacing: 12) {
            ProgressView()
            Text("loading")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
    }
}
