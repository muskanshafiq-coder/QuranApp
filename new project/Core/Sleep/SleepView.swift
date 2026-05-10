//
//  SleepView.swift
//

import SwiftUI

struct SleepView: View {
    @Environment(\.colorScheme) private var colorScheme
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @EnvironmentObject private var viewModel: SleepViewModel
    @Namespace private var animation
    @State private var selectedItem: SleepAudioItem?
    @State private var selectedMatchedGeometryId: String?
    @State private var showPremiumView: Bool = false

    private var isIPad: Bool {
        horizontalSizeClass == .regular
    }

    private var contentMaxWidth: CGFloat {
        isIPad ? 1000 : .infinity
    }

    var body: some View {
        AppNavigationContainer {
            ZStack {
                mainContent
                    .blur(radius: selectedItem != nil ? 12 : 0)
                    .disabled(selectedItem != nil)

                if let item = selectedItem {
                    expandedView(for: item)
                        .ignoresSafeArea()
                        .zIndex(1)
                }
            }
            .animation(.spring(response: 0.5, dampingFraction: 0.85), value: selectedItem?.id)
            .onChange(of: selectedItem) { new in
                viewModel.isOptionsOverlayVisible = (new != nil)
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(action: {}) {
                        Image(systemName: "square.and.arrow.up.fill")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
                    }
                }
            }
            .navigationTitle("sleep_title")
            .navigationBarTitleDisplayMode(.large)
            .navigationBarHidden(selectedItem != nil)
            // Stories load from cache in `SleepViewModel.init` + API refresh starts in `MainTabBarController` (avoids duplicate fetch on tab open).
            .sheet(item: $viewModel.optionsSheetItem) { item in
                let state = viewModel.downloadState(for: item)
                let isFavorite = viewModel.isFavorite(item)
                SleepItemOptionsSheet(
                    item: item,
                    onDownload: {
                        viewModel.downloadItem(item)
                        viewModel.optionsSheetItem = nil
                    },
                    onRemoveDownload: {
                        viewModel.removeDownload(for: item)
                        viewModel.optionsSheetItem = nil
                    },
                    downloadState: state,
                    onAddToFavorite: {
                        viewModel.addToFavorites(item)
                        viewModel.optionsSheetItem = nil
                    },
                    isFavorite: isFavorite,
                    onShare: {
                        viewModel.shareItem(item)
                        viewModel.optionsSheetItem = nil
                    }
                )
            }
            .sheet(isPresented: $showPremiumView) {
//                PremiumView()
                Text("This is premium")
            }
        }
        
    }

    private var mainContent: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()

            ScrollView {
                VStack(alignment: .leading, spacing: isIPad ? 32 : 24) {
                    if !viewModel.recentlyAddedItems.isEmpty {
                        recentlyAddedSectionView(items: viewModel.recentlyAddedItems)
                    }
                    if !viewModel.favoriteItems.isEmpty {
                        favoritesSectionView(items: viewModel.favoriteItems)
                    }

                    // Categories from API (Life of Prophets, History, etc.)
                    if viewModel.isLoadingCategories && viewModel.categorySections.isEmpty {
                        HStack {
                            Spacer()
                            ProgressView()
                            Spacer()
                        }
                        .padding(.vertical, 24)
                    } else if let error = viewModel.categoriesLoadError, viewModel.categorySections.isEmpty {
                        VStack(spacing: 12) {
                            Text(error)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                            Button("sleep_action_retry") {
                                Task { await viewModel.loadCategoriesAndStories() }
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 24)
                    } else {
                        ForEach(viewModel.categorySections) { section in
                            categorySectionView(section)
                        }
                    }
                }
                .frame(maxWidth: contentMaxWidth)
                .frame(maxWidth: .infinity)
            }
        }
    }

    private func favoritesSectionView(items: [SleepAudioItem]) -> some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            Text("sleep_saved_stories")
                .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, isIPad ? 24 : 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isIPad ? 16 : 12) {
                    ForEach(items) { item in
                        let mgId = "fav-\(item.id)"
                        let downloadState = viewModel.downloadState(for: item)
                        SleepAudioCard(
                            item: item,
                            isIPad: isIPad,
                            namespace: animation,
                            matchedGeometryId: mgId,
                            downloadState: downloadState,
                            isFavorite: viewModel.isFavorite(item),
                            onDownload: { viewModel.downloadItem(item) },
                            onRemoveDownload: { viewModel.removeDownload(for: item) },
                            onAddToFavorite: { viewModel.addToFavorites(item) },
                            onShare: { viewModel.shareItem(item) },
                            onTap: {
                                if PremiumManager.shared.isPremium {
                                    viewModel.selectItemForPlay(item, from: items)
                                } else {
                                    showPremiumView = true
                                }
                            },
                            onLongPress: {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                    selectedItem = item
                                    selectedMatchedGeometryId = mgId
                                }
                            }
                        )
                    }
                }
                .padding(.horizontal, isIPad ? 24 : 20)
            }
        }
    }

    private func recentlyAddedSectionView(items: [SleepAudioItem]) -> some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            Text("sleep_recently_added")
                .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                .foregroundColor(colorScheme == .dark ? .white : .black)
                .padding(.horizontal, isIPad ? 24 : 20)

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: isIPad ? 16 : 12) {
                    ForEach(items) { item in
                        let mgId = "recent-\(item.id)"
                        let isFavorite = viewModel.isFavorite(item)
                        let downloadState = viewModel.downloadState(for: item)
                        FeaturedStoryCard(
                            item: item,
                            isIPad: isIPad,
                            namespace: animation,
                            matchedGeometryId: mgId,
                            isFavorite: isFavorite,
                            downloadState: downloadState,
                            onDownload: { viewModel.downloadItem(item) },
                            onRemoveDownload: { viewModel.removeDownload(for: item) },
                            onAddToFavorite: { viewModel.addToFavorites(item) },
                            onShare: { viewModel.shareItem(item) }
                        )
                        .onTapGesture {
                            viewModel.selectItemForPlay(item, from: items)
                        }
                        .onLongPressGesture {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                selectedItem = item
                                selectedMatchedGeometryId = mgId
                            }
                        }
                    }
                }
                .padding(.horizontal, isIPad ? 24 : 20)
            }
        }
    }

    private func categorySectionView(_ section: SleepCategorySection) -> some View {
        VStack(alignment: .leading, spacing: isIPad ? 20 : 16) {
            if section.isLoading {
                HStack {
                    Text(section.category.title)
                        .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                        .foregroundColor(colorScheme == .dark ? .white : .black)
                    Spacer()
                    ProgressView()
                }
                .padding(.horizontal, isIPad ? 24 : 20)
            } else {
                Text(section.category.title)
                    .font(.system(size: isIPad ? 24 : 18, weight: .bold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)
                    .padding(.horizontal, isIPad ? 24 : 20)
            }

            if let error = section.loadError {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .padding(.horizontal, isIPad ? 24 : 20)
            } else {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: isIPad ? 16 : 12) {
                        ForEach(section.items) { item in
                            let mgId = "cat-\(section.category.id)-\(item.id)"
                            let downloadState = viewModel.downloadState(for: item)
                            SleepAudioCard(
                                item: item,
                                isIPad: isIPad,
                                namespace: animation,
                                matchedGeometryId: mgId,
                                downloadState: downloadState,
                                isFavorite: viewModel.isFavorite(item),
                                onDownload: { viewModel.downloadItem(item) },
                                onRemoveDownload: { viewModel.removeDownload(for: item) },
                                onAddToFavorite: { viewModel.addToFavorites(item) },
                                onShare: { viewModel.shareItem(item) },
                                onTap: {
                                    if PremiumManager.shared.isPremium {
                                        viewModel.selectItemForPlay(item, from: section.items)
                                    } else {
                                        showPremiumView = true
                                    }
                                },
                                onLongPress: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.85)) {
                                        selectedItem = item
                                        selectedMatchedGeometryId = mgId
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal, isIPad ? 24 : 20)
                }
            }
        }
    }

    private func expandedView(for item: SleepAudioItem) -> some View {
        GeometryReader { geo in
            ZStack {
                // Background (tap to dismiss)
                Color.black.opacity(0.3)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .contentShape(Rectangle())
                    .ignoresSafeArea()
                    .onTapGesture {
                        closeExpanded()
                    }

                VStack {
                    Spacer()

                    VStack(alignment: .leading, spacing: 16) {
                        SleepAudioCard(
                            item: item,
                            isIPad: isIPad,
                            namespace: animation,
                            matchedGeometryId: selectedMatchedGeometryId,
                            cardSizeOverride: min(geo.size.width - 56, 320),
                            titleOnImage: true,
                            downloadState: viewModel.downloadState(for: item),
                            isFavorite: viewModel.isFavorite(item),
                            onTap: {},
                            onLongPress: {}
                        )

                        VStack(spacing: 0) {
                            actionButtons(for: item)
                        }
                        .frame(maxWidth: 220)
                        .background(
                            colorScheme == .dark
                                ? Color(white: 0.15)
                                : Color(white: 0.95)
                        )
                        .cornerRadius(16)
                    }
                    .padding(.horizontal, 24)

                    Spacer()
                        .frame(height: geo.size.height * 0.35)
                }

            }
        }
        .transition(.opacity)
    }

    @ViewBuilder
    private func actionButtons(for item: SleepAudioItem) -> some View {
        let isDownloaded = viewModel.downloadState(for: item) == .downloaded
        let isFavorite = viewModel.isFavorite(item)
        Button {
            closeExpanded()
            if isDownloaded {
                viewModel.removeDownload(for: item)
            } else {
                viewModel.downloadItem(item)
            }
        } label: {
            HStack {
                Text(isDownloaded ? "sleep_option_remove_from_downloads" : "sleep_option_download")
                Spacer()
                Image(systemName: isDownloaded ? "trash" : "arrow.down.circle")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(isDownloaded ? .red : (colorScheme == .dark ? .white : .black))
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        Button {
            closeExpanded()
            viewModel.addToFavorites(item)
        } label: {
            HStack {
                Text(isFavorite ? "sleep_option_remove_from_favorites" : "sleep_option_add_to_favorite")
                Spacer()
                Image(systemName: isFavorite ? "bookmark.slash" : "bookmark")
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
        Button {
            closeExpanded()
            viewModel.shareItem(item)
        } label: {
            HStack {
                Text("sleep_option_share")
                Spacer()
                Image(systemName: "square.and.arrow.up")
                    .frame(width: 14, height: 14)
            }
            .font(.system(size: 14, weight: .medium, design: .rounded))
            .foregroundColor(colorScheme == .dark ? .white : .black)
            .padding(.horizontal, 14)
            .padding(.vertical, 10)
        }
        .buttonStyle(.plain)
    }

    private func closeExpanded() {
        viewModel.isOptionsOverlayVisible = false
        withAnimation(.spring(response: 0.5, dampingFraction: 0.85)) {
            selectedItem = nil
            selectedMatchedGeometryId = nil
        }
    }
}
