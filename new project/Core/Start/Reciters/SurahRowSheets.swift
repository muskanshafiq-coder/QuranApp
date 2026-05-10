//
//  SurahRowSheets.swift
//

import SwiftUI

struct SurahOptionsFlowSheet: View {
    let surahRow: PlayerSurahRowModel
    let accentColor: Color

    @Environment(\.dismiss) private var dismiss

    let onAddToPlaylistTapped: () -> Void
    let onAddBookmark: () -> Void
    let onPlayNext: () -> Void
    let onShare: () -> Void

    var body: some View {
        NavigationStack {
            optionsBody
                .background(Color.app.ignoresSafeArea())
                .toolbar {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .accessibilityLabel(Text("alert_cancel"))
                    }
                }
        }
    }

    // MARK: - Options

    private var optionsBody: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                primaryOptionButton(
                    titleKey: "surah_options_add_playlist",
                    systemImage: "music.note.list",
                    background: accentColor
                ) {
                    dismiss()
                    onAddToPlaylistTapped()
                }

                secondaryOptionButton(titleKey: "surah_options_add_bookmark", systemImage: "bookmark") {
                    dismiss()
                    onAddBookmark()
                }

                secondaryOptionButton(titleKey: "surah_options_play_next", systemImage: "text.line.first.and.arrowtriangle.forward") {
                    dismiss()
                    onPlayNext()
                }

                secondaryOptionButton(titleKey: "surah_options_share_surah", systemImage: "square.and.arrow.up") {
                    dismiss()
                    onShare()
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 24)
            .frame(maxWidth: 700)
            .frame(maxWidth: .infinity)
        }
    }

    private func primaryOptionButton(titleKey: LocalizedStringKey, systemImage: String, background: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28)
                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.white)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(background))
        }
        .buttonStyle(.plain)
    }

    private func secondaryOptionButton(titleKey: LocalizedStringKey, systemImage: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            HStack(spacing: 12) {
                Spacer()
                Image(systemName: systemImage)
                    .font(.system(size: 18, weight: .medium))
                    .frame(width: 28)
                Text(titleKey)
                    .font(.system(size: 17, weight: .semibold))
                Spacer()
            }
            .foregroundStyle(Color.primary)
            .padding(.horizontal, 18)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity)
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(Color.card))
        }
        .buttonStyle(.plain)
    }
}
