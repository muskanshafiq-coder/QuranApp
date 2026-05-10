//
//  ContinueReadingCard.swift
//

import SwiftUI

struct ContinueReadingCard: View {
    let progress: ReadingProgress
    let surah: SurahItem
    var isTranslationEnabled: Bool = false
    @Binding var showBookmarks: Bool
    @Environment(\.colorScheme) var colorScheme
     var body: some View {
         VStack{
             HStack(alignment: .center, spacing: 12) {
                 HStack(alignment: .center, spacing: 12) {
                     Text("\(progress.surahNumber)")
                         .font(.system(size: 10, design: .rounded))
                         .foregroundColor(Color.gray)
                     VStack(alignment: .leading, spacing: 4) {
                         Text(surah.displayName(translationEnabled: isTranslationEnabled))
                             .font(.system(size: 16, weight: .semibold, design: .rounded))
                             .foregroundColor(colorScheme == .dark ? .white : .black)
                         Text(String.localizedStringWithFormat(
                             NSLocalizedString("quran_juz_hizb_ayah", comment: ""),
                             progress.juz,
                             hizbNumber,
                             progress.ayahNumber
                         ))
                             .font(.system(size: 12, weight: .regular, design: .rounded))
                             .foregroundColor(Color.gray)
                     }
                 }
                 Spacer()
                 Text(surah.nameArabic)
                     .font(.custom("A Thuluth", size: 16))
                     .environment(\.layoutDirection, .rightToLeft)
             }
             .padding(.horizontal)
             .padding(.top, 8)
            .padding(.bottom, 16)
             Divider()
                 .padding(.horizontal)
                 .padding(.vertical, 8)
             Button(action: { showBookmarks = true }) {
                 HStack {
                     Text("quran_my_bookmarks")
                         .font(.system(size: 14, weight: .medium, design: .rounded))
//                         .foregroundColor(ThemeColorManager.shared.currentThemeColor)
                     Spacer()
                     Image(systemName: "chevron.right")
                         .font(.system(size: 10, weight: .semibold))
                         .foregroundColor(.gray)
                         .flipsForRightToLeftLayoutDirection(true)
                     
                 }
                 .padding(.horizontal)
                 .padding(.bottom, 16)
             }
         }
         .background(.card)
        .cornerRadius(24)
    }
    
    private var hizbNumber: Int {
        (progress.hizbQuarter + 3) / 4
    }
    
    private var quarterFraction: String {
        let quarter = (progress.hizbQuarter - 1) % 4 + 1
        return "\(quarter)/4"
    }
}
