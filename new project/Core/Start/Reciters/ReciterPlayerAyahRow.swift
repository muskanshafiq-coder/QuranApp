//
//  ReciterPlayerAyahRow.swift
//

import SwiftUI

struct ReciterPlayerAyahRow: View {
    let ayah: AyahItem
    let translation: String?
    let isActive: Bool
    let onSeekToAyah: () -> Void

    @AppStorage(UserDefaultsManager.Keys.quranFontFamily) private var quranFontFamily: String = "SF font"
    @AppStorage(UserDefaultsManager.Keys.quranFontSize) private var quranFontSize: Double = 20

    private static let fontNameMap: [String: String] = [
        "Me Quran": "me_quran",
        "PDMS Saleem Quran Font": "PDMS Saleem QuranFont",
        "Al Qalam Quran Majeed Web": "Al Qalam Quran Majeed",
        "Droid Arabic Naskh": "Droid Arabic Naskh",
        "Noto Kufi Arabic": "Noto Kufi Arabic",
        "Noto Naskh Arabic": "Noto Naskh Arabic",
        "Noto Nastaliq Urdu": "Noto Nastaliq Urdu",
        "Scheherazade": "Scheherazade New"
    ]

    private var ayahFont: Font {
        let size = CGFloat(quranFontSize > 0 ? quranFontSize : 20)
        if quranFontFamily == "SF font" {
            return .system(size: size, weight: .regular)
        }
        let fontName = Self.fontNameMap[quranFontFamily] ?? quranFontFamily
        return .custom(fontName, size: size)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 0) {
            Color.accentColor
                .opacity(isActive ? 1 : 0)
                .frame(width: 3)
                .clipShape(Capsule())
                .padding(.trailing, 10)

            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    diamondBadge
                    Spacer(minLength: 8)
                    Menu {
                        Button("general_share") {}
                    } label: {
                        Image(systemName: "ellipsis")
                            .font(.system(size: 16, weight: .semibold))
                            .frame(width: 32, height: 28)
                            .contentShape(Rectangle())
                    }
                }

                Text(ayah.text)
                    .font(ayahFont)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.trailing)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .environment(\.layoutDirection, .rightToLeft)

                if let t = translation?.trimmingCharacters(in: .whitespacesAndNewlines), !t.isEmpty {
                    Text(t)
                        .font(.system(size: max(15, quranFontSize - 5), weight: .regular))
                        .foregroundColor(.white.opacity(0.72))
                        .multilineTextAlignment(.leading)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .padding(.vertical, 4)
            .padding(.horizontal, 4)
            .background(Color.white.opacity(isActive ? 0.08 : 0))
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))
        }
        .contentShape(Rectangle())
        .onTapGesture(perform: onSeekToAyah)
    }

    private var diamondBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(45))
            Text("\(ayah.numberInSurah)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white)
        }
        .frame(width: 32, height: 32)
    }
}
