//
//  SleepItemOptionsSheet.swift
//  Quran App
//

import SwiftUI

/// Sheet shown on long tap: content card (picture + title/subtitle) and options (Download, Add to Favorite, Share).
/// Set `optionsOnly: true` to show only the three options (no card), e.g. from the play screen three dots.
struct SleepItemOptionsSheet: View {
    let item: SleepAudioItem
    let onDownload: () -> Void
    let onRemoveDownload: () -> Void
    let downloadState: SleepViewModel.DownloadVisualState
    let onAddToFavorite: () -> Void
    /// Whether the item is currently in favorites, used to toggle text/icon.
    let isFavorite: Bool
    let onShare: () -> Void
    /// When true, only the options list is shown (Download, Add to Favorite, Share). When false, the card is shown above the list.
    var optionsOnly: Bool = false
    @Environment(\.dismiss) private var dismiss
    @Environment(\.colorScheme) private var colorScheme

    private let cardHeight: CGFloat = 180
    private let cornerRadius: CGFloat = 20

    var body: some View {
        VStack(spacing: 0) {
            if !optionsOnly {
                // Content card (picture + title, subtitle)
                cardView
                    .padding(.horizontal, 24)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
            }

            // Options list (only these three)
            VStack(spacing: 0) {
                if downloadState == .downloaded {
                    optionRow(
                        title: "sleep_option_remove_from_downloads",
                        icon: "trash",
                        isDestructive: true
                    ) {
                        onRemoveDownload()
                    }
                } else if downloadState == .downloading {
                    optionRow(
                        title: "sleep_option_downloading",
                        icon: "arrow.down.circle"
                    ) {
                    }
                    .disabled(true)
                } else {
                    optionRow(
                        title: "sleep_option_download",
                        icon: "arrow.down.circle"
                    ) {
                        onDownload()
                    }
                }
                optionRow(
                    title: isFavorite ? "sleep_option_remove_from_favorites": "sleep_option_add_to_favorite",
                    icon: isFavorite ? "bookmark.slash" : "bookmark"
                ) {
                    onAddToFavorite()
                }
                optionRow(
                    title: "sleep_option_share",
                    icon: "square.and.arrow.up"
                ) {
                    onShare()
                }
            }
            .background(colorScheme == .dark ? Color(white: 0.15) : Color.white)
            .cornerRadius(cornerRadius)
            .padding(.horizontal, 24)
            .padding(.top, optionsOnly ? 20 : 0)
            .padding(.bottom, 32)
        }
        .compatibleSheetPresentation()
    }

    private var cardView: some View {
        ZStack(alignment: .bottomLeading) {
            // Background / image
            Group {
                if let url = item.imageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                        case .failure:
                            placeholderGradient
                        case .empty:
                            ProgressView()
                                .frame(maxWidth: .infinity, maxHeight: .infinity)
                        @unknown default:
                            placeholderGradient
                        }
                    }
                } else if let name = item.localImageName, let image = UIImage(named: name) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    placeholderGradient
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: cardHeight)
            .clipped()
            .cornerRadius(cornerRadius)

            // Gradient overlay for text
            LinearGradient(
                colors: [.clear, .black.opacity(0.8)],
                startPoint: .top,
                endPoint: .bottom
            )
            .cornerRadius(cornerRadius)

            // Title & subtitle
            VStack(alignment: .leading, spacing: 4) {
                Text(item.title)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                if !item.subtitle.isEmpty {
                    Text(item.subtitle)
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.9))
                }
            }
            .padding(16)
        }
    }

    private var placeholderGradient: some View {
        LinearGradient(
            colors: [
                Color(red: 0.3, green: 0.2, blue: 0.4),
                Color(red: 0.2, green: 0.15, blue: 0.3)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private func optionRow(
        title: String,
        icon: String,
        isDestructive: Bool = false,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            HStack {
                Text(title)
                    .font(.system(size: 14, weight: .medium, design: .rounded))
                    .foregroundColor(isDestructive ? .red : (colorScheme == .dark ? .white : .black))
                Spacer()
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(
                        isDestructive ? .red.opacity(0.9) : (colorScheme == .dark ? .white.opacity(0.7) : .black.opacity(0.6))
                    )
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - iOS 15.6 compatibility
private extension View {
    @ViewBuilder
    func compatibleSheetPresentation() -> some View {
        if #available(iOS 16.0, *) {
            self
                .presentationDetents([.medium, .large])
                .presentationDragIndicator(.visible)
        } else {
            self
        }
    }
}
