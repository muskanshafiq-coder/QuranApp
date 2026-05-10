//
//  SleepAudioCard.swift
//

import SwiftUI

/// Single audio item card for Sleep sections. Tap → play screen, long press → expanded overlay.
struct SleepAudioCard: View {
    let item: SleepAudioItem
    var isIPad: Bool = false
    var namespace: Namespace.ID? = nil
    /// Unique id for matchedGeometryEffect. Must be unique within a namespace.
    /// Defaults to `item.id` but should be overridden when the same item appears in multiple sections.
    var matchedGeometryId: String? = nil
    var cardSizeOverride: CGFloat? = nil
    /// When true, title and subtitle are overlaid on the image (bottom-left); when false, they appear below.
    var titleOnImage: Bool = false
    /// Visual state for download badge next to duration.
    var downloadState: SleepViewModel.DownloadVisualState = .notDownloaded
    /// True when this item is currently in the favorites list.
    var isFavorite: Bool = false
    /// Options shown when user taps three dots next to title.
    var onDownload: (() -> Void)? = nil
    var onRemoveDownload: (() -> Void)? = nil
    var onAddToFavorite: (() -> Void)? = nil
    var onShare: (() -> Void)? = nil
    var onTap: () -> Void
    var onLongPress: () -> Void

    @State private var longPressFired = false

    private var cardSize: CGFloat {
        cardSizeOverride ?? (isIPad ? 220 : 160)
    }
    private var cornerRadius: CGFloat {
        isIPad ? 20 : 16
    }

    /// Duration as `m:ss` (e.g. `7:15`) from `item.duration`, or "—" if empty.
    private var durationDisplayText: String {
        let d = item.duration.trimmingCharacters(in: .whitespaces)
        if d.isEmpty { return "sleep_duration_none" }
        return formatSleepDurationForDisplay(d)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Thumbnail — matchedGeometryEffect so card expands from exact position
            imageSection

            // Title & subtitle below image (only when not overlaid on image)
            if !titleOnImage {
                HStack(alignment: .top, spacing: 10) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.title)
                            .font(.system(size: isIPad ? 16 : 14, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                            .lineLimit(1)
                        if !item.subtitle.isEmpty {
                            Text(item.subtitle)
                                .font(.system(size: isIPad ? 14 : 12, weight: .medium, design: .rounded))
                                .foregroundColor(.secondary)
                                .lineLimit(1)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    if let onDownload, let onAddToFavorite, let onShare {
                        Menu {
                            if downloadState == .downloaded {
                                Button { onRemoveDownload?() } label: {
                                    Label("sleep_option_remove_from_downloads", systemImage: "trash")
                                        .foregroundColor(.red)
                                }
                            } else if downloadState == .downloading {
                                Button { } label: {
                                    Label("sleep_option_downloading", systemImage: "arrow.down.circle")
                                }
                                .disabled(true)
                            } else {
                                Button { onDownload() } label: {
                                    Label("sleep_option_download", systemImage: "arrow.down.circle")
                                }
                            }
                            Button { onAddToFavorite() } label: {
                                Label(
                                    isFavorite ? "sleep_option_remove_from_favorites": "sleep_option_add_to_favorite",
                                    systemImage: isFavorite ? "bookmark.slash" : "bookmark"
                                )
                            }
                            Button { onShare() } label: {
                                Label("sleep_option_share", systemImage: "square.and.arrow.up")
                            }
                        } label: {
                            Image(systemName: "ellipsis")
                                .font(.system(size: isIPad ? 9 : 8, weight: .semibold))
                                .foregroundColor(.black)
                                .frame(width: isIPad ? 18 : 16, height: isIPad ? 18 : 16)
                                .background(Color.white)
                                .clipShape(Circle())
                        }
                        .contentShape(Circle())
                        .accessibilityLabel("sleep_accessibility_options")
                    }
                }
                .padding(.top, 10)
            }
        }
        .frame(width: cardSize, alignment: .leading)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.45, pressing: { _ in }, perform: {
            longPressFired = true
            onLongPress()
        })
        .onTapGesture {
            if longPressFired {
                longPressFired = false
                return
            }
            onTap()
        }
    }

    @ViewBuilder
    private var imageSection: some View {
        let thumb = ZStack(alignment: .bottomLeading) {
            imageView
                .frame(width: cardSize, height: cardSize)
                .clipped()
                .cornerRadius(cornerRadius)

            if !titleOnImage {
                HStack(spacing: 0) {
                    playTimePill
                    Spacer(minLength: 4)
                    HStack(spacing: 0) {
                        favoritePill
                        downloadPill
                    }
                }
                .padding(isIPad ? 10 : 8)
            }

            // Title and subtitle on the image (expanded view)
            if titleOnImage {
                LinearGradient(
                    colors: [.clear, .black.opacity(0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .cornerRadius(cornerRadius)

                VStack(alignment: .leading, spacing: 4) {
                    Text(item.title)
                        .font(.system(size: isIPad ? 18 : 16, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .lineLimit(2)
                    if !item.subtitle.isEmpty {
                        Text(item.subtitle)
                            .font(.system(size: isIPad ? 15 : 13, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .padding(isIPad ? 16 : 14)
            }
        }
        if let n = namespace {
            thumb.matchedGeometryEffect(id: matchedGeometryId ?? item.id, in: n)
        } else {
            thumb
        }
    }

    @ViewBuilder
    private var imageView: some View {
        if let remoteURL = item.imageURL {
            // 1. Check Core Data cache first (most persistent)
            if let data = SleepImageCacheStore.shared.fetchImageData(for: remoteURL.absoluteString),
               let uiImage = UIImage(data: data) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
            }
            // 2. Check disk cache (fallback)
            else if let cachedURL = StoryImageCache.shared.cachedFileURL(for: remoteURL),
               let uiImage = UIImage(contentsOfFile: cachedURL.path) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .onAppear {
                        // Save to Core Data for next time
                        if let data = try? Data(contentsOf: cachedURL) {
                            SleepImageCacheStore.shared.saveImageInBackground(data: data, for: remoteURL.absoluteString)
                        }
                    }
            }
            // 3. Load from remote and save to Core Data
            else {
                AsyncImage(url: remoteURL) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                            .onAppear {
                                Task.detached(priority: .background) {
                                    if let (data, _) = try? await URLSession.shared.data(from: remoteURL),
                                       !data.isEmpty {
                                        await SleepImageCacheStore.shared.saveImageInBackground(data: data, for: remoteURL.absoluteString)
                                    }
                                }
                            }
                    case .failure:
                        placeholderBackground
                    case .empty:
                        ProgressView()
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                    @unknown default:
                        placeholderBackground
                    }
                }
            }
        } else if let name = item.localImageName, let image = UIImage(named: name) {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
        } else {
            placeholderBackground
        }
    }

    private var placeholderBackground: some View {
        LinearGradient(
            colors: [
                Color(red: 0.25, green: 0.18, blue: 0.35),
                Color(red: 0.18, green: 0.12, blue: 0.28)
            ],
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    private var playTimePill: some View {
        let pillHeight: CGFloat = isIPad ? 32 : 28
        let corner: CGFloat = isIPad ? 16 : 12
        let shape = RoundedRectangle(cornerRadius: corner, style: .continuous)
        return HStack(spacing: 6) {
            Image(systemName: item.isLocked ? "lock.fill" : "play.fill")
                .font(.system(size: isIPad ? 12 : 10, weight: .semibold, design: .rounded))
            Text(durationDisplayText)
                .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
        }
        .foregroundColor(.white)
        .padding(.horizontal, isIPad ? 14 : 12)
        .frame(height: pillHeight)
//        .glassEffect(.regular, in: shape)
    }

    @ViewBuilder
    private var downloadPill: some View {
        let pillHeight: CGFloat = isIPad ? 32 : 28
        if !item.isLocked, downloadState == .downloaded {
            Image(systemName: "arrow.down.circle.fill")
                .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: isIPad ? 22 : 20, height: isIPad ? 22 : 20)
                .padding(.horizontal, isIPad ? 8 : 6)
                .frame(height: pillHeight)
                // .background(Color.black.opacity(0.6))
                .cornerRadius(isIPad ? 16 : 12)
                .accessibilityLabel("sleep_accessibility_downloaded")
        } else if !item.isLocked, downloadState == .downloading {
            ProgressView()
                .progressViewStyle(CircularProgressViewStyle(tint: .white))
                .scaleEffect(isIPad ? 0.8 : 0.7)
                .frame(width: isIPad ? 22 : 20, height: isIPad ? 22 : 20)
                .padding(.horizontal, isIPad ? 8 : 6)
                .frame(height: pillHeight)
        }
    }

    @ViewBuilder
    private var favoritePill: some View {
        let pillHeight: CGFloat = isIPad ? 32 : 28
        if !item.isLocked, isFavorite {
            HStack(spacing: 6) {
                Image(systemName: "bookmark.fill")
                    .font(.system(size: isIPad ? 14 : 12, weight: .semibold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, isIPad ? 5 : 2)
            .frame(height: pillHeight)
            // .background(Color.black.opacity(0.6))
            .cornerRadius(isIPad ? 16 : 12)
            .accessibilityLabel("sleep_accessibility_saved")
        }
    }
}
