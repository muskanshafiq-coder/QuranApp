//
//  ReciterPlayerAyahRow.swift
//

import SwiftUI

struct ReciterPlayerAyahRow: View {
    let ayah: AyahItem
    let isAyahBookmarked: Bool
    let accentColor: Color
    let onToggleAyahBookmark: () -> Void
    let onShareAyah: () -> Void
    let onPlayAyah: () -> Void
    let onShowTranslation: () -> Void
    let onRepeatOption: () -> Void

    @AppStorage(UserDefaultsManager.Keys.quranFontSize) private var quranFontSize: Double = 20

    private var ayahFont: Font {
        let size = CGFloat(quranFontSize > 0 ? quranFontSize : 22)
        return QuranAyahDisplayFont.uthmani(size: size)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top, spacing: 12) {
                diamondBadge

                VStack(alignment: .leading, spacing: 10) {
                    Text(ayah.text)
                        .font(ayahFont)
                        .foregroundStyle(.primary)
                        .multilineTextAlignment(.trailing)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                        .environment(\.layoutDirection, .rightToLeft)

                    HStack {
                        Spacer(minLength: 0)
                        ayahOptionsMenu
                    }
                }
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 4)
            .clipShape(RoundedRectangle(cornerRadius: 2, style: .continuous))

            Rectangle()
                .fill(Color.primary.opacity(0.12))
                .frame(height: 1)
                .padding(.top, 2)
        }
    }

    private var diamondBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(accentColor, lineWidth: 1.25)
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(45))
            Text("\(ayah.numberInSurah)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(width: 32, height: 32)
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
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(accentColor)
                .frame(width: 32, height: 28)
                .contentShape(Rectangle())
        }
    }
}