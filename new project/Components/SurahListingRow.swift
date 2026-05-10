//
//  SurahListingRow.swift
//

import SwiftUI

/// Shared surah row layout used on the reciter surah list and playlist detail.
struct SurahListingRow: View {
    let number: Int
    let englishLine: String
    let arabicLine: String
    let accentColor: Color
    var onTapContent: () -> Void = {}
    var onDownload: () -> Void = {}

    private let moreAccessory: AnyView

    private let rowHPadding: CGFloat = 14

    init(
        number: Int,
        englishLine: String,
        arabicLine: String,
        accentColor: Color,
        onTapContent: @escaping () -> Void = {},
        onDownload: @escaping () -> Void = {},
        onMore: @escaping () -> Void
    ) {
        self.number = number
        self.englishLine = englishLine
        self.arabicLine = arabicLine
        self.accentColor = accentColor
        self.onTapContent = onTapContent
        self.onDownload = onDownload
        self.moreAccessory = AnyView(
            Button(action: onMore) {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .semibold))
                    .frame(width: 28)
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
        )
    }

    init(
        number: Int,
        englishLine: String,
        arabicLine: String,
        accentColor: Color,
        onTapContent: @escaping () -> Void = {},
        onDownload: @escaping () -> Void = {},
        @ViewBuilder moreAccessory: @escaping () -> some View
    ) {
        self.number = number
        self.englishLine = englishLine
        self.arabicLine = arabicLine
        self.accentColor = accentColor
        self.onTapContent = onTapContent
        self.onDownload = onDownload
        self.moreAccessory = AnyView(moreAccessory())
    }

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            Text("\(number)")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.secondary)
                .frame(width: 28, alignment: .leading)

            VStack(alignment: .leading, spacing: 4) {
                Text(englishLine)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                    .lineLimit(2)
                    .minimumScaleFactor(0.85)
                if !arabicLine.isEmpty {
                    Text(arabicLine)
                        .font(.system(size: 14, weight: .regular))
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 6)
            .contentShape(Rectangle())
            .onTapGesture(perform: onTapContent)

            Button(action: onDownload) {
                Image(systemName: "icloud.and.arrow.down")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(accentColor)
            }
            .buttonStyle(.plain)
            .padding(.trailing, 10)

            moreAccessory
        }
        .padding(.horizontal, rowHPadding)
        .padding(.vertical, 12)
    }
}
