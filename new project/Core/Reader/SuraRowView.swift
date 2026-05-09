//
//  SuraRowView.swift
//  Quran App
//
//  Created by apple on 05/02/2026.
//

import SwiftUI

struct SuraRowView: View {
    let surah: SurahItem
    @Environment(\.colorScheme) var colorScheme
    @Binding var isTranslationEnabled: Bool
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("\(surah.number)")
                .font(.system(size: 10, design: .rounded))
                .foregroundColor(.gray)

            VStack(alignment: .leading, spacing: 4) {
                Text(surah.displayName(translationEnabled: isTranslationEnabled))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(colorScheme == .dark ? .white : .black)

                Text(String.localizedStringWithFormat(
                    NSLocalizedString("quran_ayas_count", comment: ""),
                    surah.numberOfAyahs
                ))
                .font(.system(size: 12))
                .foregroundColor(.gray)
            }

            Spacer()

            Text(surah.nameArabic)
                .font(.custom("A Thuluth", size: 16))
                .fontWeight(.medium)
                .environment(\.layoutDirection, .rightToLeft)
        }
        .padding(8)
    }

    private var revelationLabel: String {
        surah.isMeccan
        ? "quran_meccan"
        : "quran_medinan"
    }
}
