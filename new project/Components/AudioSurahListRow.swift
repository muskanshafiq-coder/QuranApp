//
//  AudioSurahListRow.swift
//

import SwiftUI

/// Shared audio row: index, circular portrait, surah title (EN + AR), reciter name, download, trailing menu.
/// Used by bookmarks and playlists.
struct AudioSurahListRow<MenuAccessory: View>: View {
    let listPosition: Int
    let surahTitleEn: String
    let surahTitleAr: String?
    let reciterNameEn: String
    let portraitURLString: String?
    let accentColor: Color
    @Binding var preferredReciterId: String
    let navigationReciter: PlayerReciterDisplayItem
    let onDownloadTap: () -> Void
    @ViewBuilder var menuAccessory: () -> MenuAccessory

    private let rowHPadding: CGFloat = 14

    private var combinedTitle: String {
        let en = surahTitleEn.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let ar = surahTitleAr?.trimmingCharacters(in: .whitespacesAndNewlines), !ar.isEmpty else {
            return en
        }
        return "\(en) \(ar)"
    }

    private var portraitURL: URL? {
        portraitURLString.flatMap { URL(string: $0) }
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
                    reciter: navigationReciter,
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
                    Text(reciterNameEn)
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

            menuAccessory()
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
