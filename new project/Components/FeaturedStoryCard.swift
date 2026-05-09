//
//  FeaturedStoryCard.swift
//  Quran App
//
//  Created by apple on 17/01/2026.
//

import SwiftUI
import Foundation
import UIKit

struct FeaturedStoryCard: View {
    private let story: SleepStory?
    private let audioItem: SleepAudioItem?
    var isIPad: Bool = false
    private let namespace: Namespace.ID?
    private let matchedGeometryId: String?
    
    // Controls (shown for API-backed cards, i.e. `audioItem != nil`)
    private var isFavorite: Bool = false
    private var downloadState: SleepViewModel.DownloadVisualState = .notDownloaded
    private var onDownload: (() -> Void)?
    private var onRemoveDownload: (() -> Void)?
    private var onAddToFavorite: (() -> Void)?
    private var onShare: (() -> Void)?

    init(story: SleepStory, isIPad: Bool = false) {
        self.story = story
        self.audioItem = nil
        self.isIPad = isIPad
        self.namespace = nil
        self.matchedGeometryId = nil
    }

    init(item: SleepAudioItem, isIPad: Bool = false, namespace: Namespace.ID? = nil, matchedGeometryId: String? = nil) {
        self.story = nil
        self.audioItem = item
        self.isIPad = isIPad
        self.namespace = namespace
        self.matchedGeometryId = matchedGeometryId
    }

    init(
        item: SleepAudioItem,
        isIPad: Bool = false,
        namespace: Namespace.ID? = nil,
        matchedGeometryId: String? = nil,
        isFavorite: Bool,
        downloadState: SleepViewModel.DownloadVisualState,
        onDownload: (() -> Void)? = nil,
        onRemoveDownload: (() -> Void)? = nil,
        onAddToFavorite: (() -> Void)? = nil,
        onShare: (() -> Void)? = nil
    ) {
        self.story = nil
        self.audioItem = item
        self.isIPad = isIPad
        self.namespace = namespace
        self.matchedGeometryId = matchedGeometryId
        self.isFavorite = isFavorite
        self.downloadState = downloadState
        self.onDownload = onDownload
        self.onRemoveDownload = onRemoveDownload
        self.onAddToFavorite = onAddToFavorite
        self.onShare = onShare
    }

    private var titleText: String { story?.title ?? audioItem?.title ?? "" }
    private var artistText: String {
        if let story {
            return story.artist.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        guard let item = audioItem else { return "" }
        let sub = item.subtitle.trimmingCharacters(in: .whitespacesAndNewlines)
        if !sub.isEmpty { return sub }
        return SleepStoryAuthorCache.shared.author(for: item.id)?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
    private var durationText: String {
        let raw = story?.duration ?? audioItem?.duration ?? ""
        let formatted = formatSleepDurationForDisplay(raw)
        return formatted.isEmpty ? raw : formatted
    }
    private var isLocked: Bool { story?.isLocked ?? audioItem?.isLocked ?? false }

    private var dateText: String {
        if let d = story?.date { return d }
        guard let createdAt = audioItem?.createdAt else { return "" }
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM"
        return formatter.string(from: createdAt).uppercased()
    }

    private var backgroundColorKey: String {
        story?.backgroundColor ?? audioItem?.backgroundColor ?? "purple"
    }

    private var localImageName: String? { story?.imageName ?? audioItem?.localImageName }
    private var remoteImageURL: URL? { audioItem?.imageURL }
    
    private var imageSize: CGSize {
        isIPad ? CGSize(width: 236, height: 268) : CGSize(width: 162, height: 184)
    }

    /// Wider than `imageSize.width` — card / text row only; thumbnail size unchanged.
    private var cardContentWidth: CGFloat {
        isIPad ? 310 : 210
    }

    private var cardHorizontalPadding: CGFloat { isIPad ? 24 : 20 }

    private var cardOuterWidth: CGFloat { cardContentWidth + cardHorizontalPadding * 2 }
    
    private var cornerRadius: CGFloat {
        isIPad ? 24 : 18
    }

    // MARK: - Background Gradient (fallback when no image)
    private var storyBackgroundColor: LinearGradient {
        switch backgroundColorKey.lowercased() {
        case "brown":
            return LinearGradient(
                colors: [
                    Color(red: 0.55, green: 0.42, blue: 0.33),
                    Color(red: 0.45, green: 0.33, blue: 0.26)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        case "blue":
            return LinearGradient(
                colors: [
                    Color(red: 0.25, green: 0.30, blue: 0.45),
                    Color(red: 0.18, green: 0.22, blue: 0.35)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

        default:
            return LinearGradient(
                colors: [.gray, .black],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    /// Same asset/URL as thumbnail, zoomed + blurred behind content (fallback: gradient).
    @ViewBuilder
    private var cardBackdrop: some View {
        GeometryReader { geo in
            let w = max(geo.size.width, 1)
            let h = max(geo.size.height, 1)
            let zoom: CGFloat = isIPad ? 1.65 : 1.55

            ZStack {
                Group {
                    if let name = localImageName, let uiImage = UIImage(named: name) {
                        Image(uiImage: uiImage)
                            .resizable()
                            .scaledToFill()
                            .frame(width: w * zoom, height: h * zoom)
                            .blur(radius: isIPad ? 34 : 28)
                    } else if let url = remoteImageURL {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let image):
                                image
                                    .resizable()
                                    .scaledToFill()
                                    .frame(width: w * zoom, height: h * zoom)
                                    .blur(radius: isIPad ? 34 : 28)
                            case .failure:
                                Rectangle().fill(storyBackgroundColor)
                            case .empty:
                                ZStack {
                                    Rectangle().fill(storyBackgroundColor)
                                    ProgressView()
                                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                                }
                            @unknown default:
                                Rectangle().fill(storyBackgroundColor)
                            }
                        }
                    } else {
                        Rectangle().fill(storyBackgroundColor)
                    }
                }
                .frame(width: w, height: h)
                .clipped()

                LinearGradient(
                    colors: [
                        Color.black.opacity(0.12),
                        Color.black.opacity(0.38)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
            }
        }
        .allowsHitTesting(false)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            
            // MARK: - Image Container (centered; narrower than card text width)
            if let namespace, let matchedGeometryId {
                HStack {
                    Spacer(minLength: 0)
                    ZStack {
                        if let name = localImageName, let image = UIImage(named: name) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize.width, height: imageSize.height)
                                .clipped()
                                .cornerRadius(cornerRadius)
                        } else if let url = remoteImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: imageSize.width, height: imageSize.height)
                                        .clipped()
                                        .cornerRadius(cornerRadius)
                                case .failure:
                                    EmptyView()
                                case .empty:
                                    EmptyView()
                                        .frame(width: imageSize.width, height: imageSize.height)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    .matchedGeometryEffect(id: matchedGeometryId, in: namespace)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, isIPad ? 14 : 10)
            } else {
                HStack {
                    Spacer(minLength: 0)
                    ZStack {
                        if let name = localImageName, let image = UIImage(named: name) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: imageSize.width, height: imageSize.height)
                                .clipped()
                                .cornerRadius(cornerRadius)
                        } else if let url = remoteImageURL {
                            AsyncImage(url: url) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .scaledToFill()
                                        .frame(width: imageSize.width, height: imageSize.height)
                                        .clipped()
                                        .cornerRadius(cornerRadius)
                                case .failure:
                                    EmptyView()
                                case .empty:
                                    ProgressView()
                                        .frame(width: imageSize.width, height: imageSize.height)
                                @unknown default:
                                    EmptyView()
                                }
                            }
                        }
                    }
                    .frame(width: imageSize.width, height: imageSize.height)
                    .clipped()
                    .cornerRadius(cornerRadius)
                    Spacer(minLength: 0)
                }
                .padding(.bottom, isIPad ? 14 : 10)
            }
            
            // MARK: - Title, subtitle (author), then date
            VStack(alignment: .leading, spacing: 4) {
                Text(titleText)
                    .font(.system(size: isIPad ? 24 : 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                    .truncationMode(.tail)
                    .frame(maxWidth: cardContentWidth, alignment: .leading)
                    .fixedSize(horizontal: false, vertical: true)

                if !artistText.isEmpty {
                    Text(artistText)
                        .font(.system(size: isIPad ? 16 : 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white.opacity(0.72))
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .frame(maxWidth: cardContentWidth, alignment: .leading)
                }

                if !dateText.isEmpty {
                    Text(dateText)
                        .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.55))
                        .frame(maxWidth: cardContentWidth, alignment: .leading)
                }
            }
            .frame(maxWidth: cardContentWidth, alignment: .leading)
            .padding(.bottom, isIPad ? 14 : 10)
            // MARK: - Play pill + separate actions pill
            HStack(alignment: .center, spacing: isIPad ? 12 : 10) {
                // Left: play / duration only (compact pill)
                HStack(spacing: isIPad ? 4 : 3) {
                    Image(systemName: isLocked ? "lock.fill" : "play.fill")
                        .font(.system(size: isIPad ? 12 : 10, weight: .semibold, design: .rounded))
                        .foregroundColor(.black.opacity(0.8))

                    Rectangle()
                        .fill(Color.gray.opacity(0.8))
                        .frame(width: isIPad ? 22 : 18, height: isIPad ? 6 : 5)
                        .cornerRadius(6)

                    Text(durationText)
                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
                        .foregroundColor(.black)
                }
                .padding(.horizontal, isIPad ? 12 : 10)
                .padding(.vertical, isIPad ? 6 : 5)
                .background(Color.white)
                .cornerRadius(isIPad ? 14 : 12)

                if audioItem != nil {
                    Spacer(minLength: 0)

                    // Right: filled icons only when saved / downloaded; add via menu otherwise
                    HStack(spacing: isIPad ? 8 : 6) {
                        if !isLocked {
                            if isFavorite {
                                Button {
                                    onAddToFavorite?()
                                } label: {
                                    Image(systemName: "bookmark.fill")
                                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .frame(width: isIPad ? 26 : 22, height: isIPad ? 26 : 22)
                                }
                                .buttonStyle(.plain)
                            }

                            if downloadState == .downloaded {
                                Button {
                                    onRemoveDownload?()
                                } label: {
                                    Image(systemName: "arrow.down.circle.fill")
                                        .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
                                        .foregroundColor(.white.opacity(0.9))
                                        .frame(width: isIPad ? 26 : 22, height: isIPad ? 26 : 22)
                                }
                                .buttonStyle(.plain)
                            }
                        }

                        Menu {
                            if onDownload != nil || onRemoveDownload != nil {
                                switch downloadState {
                                case .downloaded:
                                    if let onRemoveDownload {
                                        Button("sleep_option_remove_from_downloads") { onRemoveDownload() }
                                    }
                                case .downloading:
                                    Button("sleep_option_downloading") { }
                                        .disabled(true)
                                case .notDownloaded:
                                    if let onDownload {
                                        Button("sleep_option_download") { onDownload() }
                                    }
                                }
                            }

                            if let onAddToFavorite {
                                Button(
                                    isFavorite
                                        ? "sleep_option_remove_from_favorites"
                                        : "sleep_option_add_to_favorite"
                                ) {
                                    onAddToFavorite()
                                }
                            }

                            if let onShare {
                                Button("sleep_option_share") { onShare() }
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: isIPad ? 9 : 8, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: isIPad ? 17 : 15, height: isIPad ? 17 : 15)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                    }
                    .padding(.vertical, isIPad ? 2 : 2)
                }
            }
        }
        .frame(width: cardContentWidth, alignment: .leading)
        .padding(cardHorizontalPadding)
        .frame(width: cardOuterWidth, alignment: .leading)
        .background {
            self.cardBackdrop
        }
        .cornerRadius(isIPad ? 20 : 16)
        .overlay(
            RoundedRectangle(cornerRadius: isIPad ? 20 : 16)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
