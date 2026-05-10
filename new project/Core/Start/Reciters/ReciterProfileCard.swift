//
//  ReciterProfileCard.swift
//

import SwiftUI

struct ReciterProfileCard: View {
    let displayTitle: String
    let portraitImageURL: URL?
    let reciterId: String
    let bioText: String
    let recordedCount: Int
    let isLoadingDetail: Bool
    @Binding var bioExpanded: Bool

    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top, spacing: 14) {
                portrait
                    .frame(width: 72, height: 72)
                VStack(alignment: .leading, spacing: 6) {
                    Text(displayTitle)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    if bioText.isEmpty {
                        Text(String(
                            format: NSLocalizedString("player_reciter_recorded_count", comment: ""),
                            recordedCount
                        ))
                            .font(.system(size: 14, weight: .regular))
                            .foregroundColor(.secondary)
                    } else {
                        bioBlock
                    }
                }
                Spacer(minLength: 0)
            }

            HStack(spacing: 18) {
                Button {} label: {
                    HStack(spacing: 6) {
                        Image(systemName: "icloud.and.arrow.down")
                            .font(.system(size: 12, weight: .semibold))
                        Text("player_reciter_all_download")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(selectedThemeColorManager.selectedColor)
                    .clipShape(Capsule())
                }
                .buttonStyle(.plain)

                HStack(spacing: 6) {
                    Image(systemName: "film")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("player_reciter_audio_sync")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer(minLength: 0)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.card)
        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
    }

    @ViewBuilder
    private var portrait: some View {
        Circle()
            .fill(LinearGradient(
                colors: PlayerReciterAvatarPalette.gradient(for: reciterId),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            ))
            .overlay {
                if let url = portraitImageURL {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .success(let img):
                            img.resizable().aspectRatio(contentMode: .fill)
                        case .failure:
                            portraitFallback
                        default:
                            ProgressView().tint(.white.opacity(0.7))
                        }
                    }
                } else if isLoadingDetail {
                    ProgressView().tint(.white.opacity(0.7))
                } else {
                    portraitFallback
                }
            }
            .clipShape(Circle())
    }

    @ViewBuilder
    private var portraitFallback: some View {
        if !displayTitle.isEmpty {
            Text(PlayerReciterAvatarPalette.initials(for: displayTitle))
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(.white)
        }
    }

    @ViewBuilder
    private var bioBlock: some View {
        if !isLoadingDetail {
            bioTextBlock(full: bioText)
        }
    }

    private func bioTextBlock(full: String) -> some View {
        let shortLimit = 120
        let needsMore = full.count > shortLimit
        return VStack(alignment: .leading, spacing: 6) {
            if bioExpanded || !needsMore {
                Text(full)
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                if needsMore {
                    bioToggleButton(titleKey: "player_reciter_bio_less", expand: false)
                }
            } else {
                Text(String(full.prefix(shortLimit)) + "…")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                bioToggleButton(titleKey: "player_reciter_bio_more", expand: true)
            }
        }
    }

    private func bioToggleButton(titleKey: LocalizedStringKey, expand: Bool) -> some View {
        Button {
            withAnimation(.easeInOut(duration: 0.2)) { bioExpanded = expand }
        } label: {
            Text(titleKey)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(selectedThemeColorManager.selectedColor)
        }
        .buttonStyle(.plain)
    }
}
