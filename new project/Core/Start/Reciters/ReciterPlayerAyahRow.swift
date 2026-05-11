//
//  ReciterPlayerAyahRow.swift
//

import SwiftUI

struct ReciterPlayerAyahRow: View {
    let ayah: AyahItem
    /// Transliteration and/or translations from Quran options, in selection order.
    let translationTexts: [String]
    let isAyahBookmarked: Bool
    let accentColor: Color
    let onToggleAyahBookmark: () -> Void
    let onShareAyah: () -> Void
    let onPlayAyah: () -> Void
    let onShowTranslation: () -> Void
    let onRepeatOption: () -> Void

    @Environment(\.colorScheme) private var colorScheme
    @AppStorage(UserDefaultsManager.Keys.quranFontSize) private var quranFontSize: Double = 20
    @AppStorage(UserDefaultsManager.Keys.quranFontFamily) private var storedQuranFontFamily: String = QuranAyahDisplayFont.freeReciterArabicFontFamilyId
    @ObservedObject private var premiumManager = PremiumManager.shared

    /// One size for transliteration + every translation (matches reference “supplementary” band).
    private var supplementaryFontSize: CGFloat {
        let base = CGFloat(quranFontSize > 0 ? quranFontSize : 22)
        return min(max(round(base * 0.58), 13), 17)
    }

    private var supplementaryTextColor: Color {
        Color(uiColor: .secondaryLabel)
    }

    private var ayahFont: Font {
        let size = CGFloat(quranFontSize > 0 ? quranFontSize : 22)
        return QuranAyahDisplayFont.reciterArabicFont(
            storedFamilyId: storedQuranFontFamily,
            size: size,
            isPremiumUser: premiumManager.isPremium
        )
    }

    private var resolvedArabicFontFamilyId: String {
        premiumManager.isPremium ? storedQuranFontFamily : QuranAyahDisplayFont.freeReciterArabicFontFamilyId
    }

    /// Naskh-style Nabi needs a bit more line leading to match print-like references.
    private var arabicLineSpacing: CGFloat {
        resolvedArabicFontFamilyId == QuranAyahDisplayFont.freeReciterArabicFontFamilyId ? 10 : 6
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 14) {
                diamondBadge

                VStack(alignment: .leading, spacing: 0) {
                    Text(ayah.text)
                        .font(ayahFont)
                        .foregroundStyle(Color(uiColor: .label))
                        .multilineTextAlignment(.trailing)
                        .lineSpacing(arabicLineSpacing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    if !translationTexts.isEmpty {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(Array(translationTexts.enumerated()), id: \.offset) { _, line in
                                Text(line)
                                    .font(.system(size: supplementaryFontSize, weight: .regular, design: .default))
                                    .foregroundStyle(supplementaryTextColor)
                                    .multilineTextAlignment(.leading)
                                    .lineSpacing(5)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                        .padding(.top, 16)
                    }

                    HStack {
                        Spacer(minLength: 0)
                        ayahOptionsMenu
                    }
                    .padding(.top, translationTexts.isEmpty ? 10 : 14)
                }
            }
            .padding(.vertical, 18)

            Rectangle()
                .fill(Color(uiColor: .separator).opacity(colorScheme == .dark ? 0.5 : 0.85))
                .frame(height: 1)
        }
    }

    private var diamondBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(accentColor, lineWidth: 1)
                .frame(width: 21, height: 21)
                .rotationEffect(.degrees(45))
            Text("\(ayah.numberInSurah)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(uiColor: .label))
        }
        .frame(width: 30, height: 30)
        .padding(.top, 2)
    }

    private var ayahOptionsMenu: some View {
        Menu {
            if isAyahBookmarked {
                Button(action: onToggleAyahBookmark) {
                    Label("ayah_menu_remove_bookmark", systemImage: "bookmark.fill")
                }
            } else {
                Button(action: onToggleAyahBookmark) {
                    Label("ayah_menu_add_bookmark", systemImage: "bookmark")
                }
            }

            Button(action: onShareAyah) {
                Label("ayah_menu_share", systemImage: "square.and.arrow.up")
            }

            Button(action: onPlayAyah) {
                Label("ayah_menu_play", systemImage: "play")
            }

            Button(action: onShowTranslation) {
                Label("ayah_menu_translation", systemImage: "globe")
            }

            Divider()

            Menu {
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_once", systemImage: "repeat.1")
                }
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_twice", systemImage: "repeat")
                }
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_three", systemImage: "repeat")
                }
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_four", systemImage: "repeat")
                }
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_loop", systemImage: "repeat")
                }
                Button {
                    onRepeatOption()
                } label: {
                    Label("ayah_repeat_cancel", systemImage: "xmark")
                }
            } label: {
                Label("ayah_menu_repeat", systemImage: "repeat")
            }
        } label: {
            Image(systemName: "ellipsis")
                .font(.system(size: 17, weight: .medium))
                .foregroundStyle(accentColor)
                .frame(width: 36, height: 30)
                .contentShape(Rectangle())
        }
    }
}