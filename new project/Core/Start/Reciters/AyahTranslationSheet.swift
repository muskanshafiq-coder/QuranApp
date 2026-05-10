//
//  AyahTranslationSheet.swift
//

import SwiftUI

struct AyahTranslationSheetContext: Identifiable, Equatable {
    let id: String
    let ayahNumber: Int
    let arabicText: String
    let translation: String?

    init(ayahNumber: Int, surahNumber: Int, arabicText: String, translation: String?) {
        self.id = "\(surahNumber)-\(ayahNumber)"
        self.ayahNumber = ayahNumber
        self.arabicText = arabicText
        self.translation = translation
    }
}

struct AyahTranslationSheet: View {
    let context: AyahTranslationSheetContext

    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @Environment(\.colorScheme) private var colorScheme

    private var cardBackground: Color {
        colorScheme == .dark ? Color.white.opacity(0.08) : Color.black.opacity(0.06)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    ZStack(alignment: .topLeading) {
                        RoundedRectangle(cornerRadius: 18, style: .continuous)
                            .fill(cardBackground)

                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                ayahDiamondBadge
                                Spacer(minLength: 0)
                            }

                            Text(context.arabicText)
                                .font(.custom("A Thuluth", size: 24))
                                .multilineTextAlignment(.trailing)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                                .environment(\.layoutDirection, .rightToLeft)

                            let trimmed = context.translation?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
                            if trimmed.isEmpty {
                                Text("ayah_translation_empty")
                                    .font(.system(size: 16, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            } else {
                                Text(trimmed)
                                    .font(.system(size: 17, weight: .regular))
                                    .foregroundStyle(.secondary)
                                    .multilineTextAlignment(.leading)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                        .padding(18)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)
                .padding(.bottom, 28)
            }
            .background(Color.app.ignoresSafeArea())
            .navigationTitle("ayah_translation_sheet_title")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("alert_cancel"))
                }
            }
        }
    }

    private var ayahDiamondBadge: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .strokeBorder(selectedThemeColorManager.selectedColor, lineWidth: 1.25)
                .frame(width: 22, height: 22)
                .rotationEffect(.degrees(45))
            Text("\(context.ayahNumber)")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(.primary)
        }
        .frame(width: 32, height: 32)
    }
}
