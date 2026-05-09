//
//  AllSurasListView.swift
//  new project
//
//  Created by apple on 10/05/2026.
//

import SwiftUI

struct AllSurasListView: View {
    let surahs: [SurahItem]
    @State private var searchQuery: String = ""
    @Binding var isTranslationEnabled: Bool
    // Selected surah for full screen cover
    @State private var selectedSurah: SurahItem?
    
    // MARK: - Filtered Surahs
    private var filteredSurahs: [SurahItem] {
        guard !searchQuery.trimmingCharacters(in: .whitespaces).isEmpty else {
            return surahs
        }
        
        let query = searchQuery.lowercased()
        
        return surahs.filter { surah in
            surah.nameEnglish.lowercased().contains(query) ||
            surah.nameArabic.contains(query) ||
            "\(surah.number)".contains(query)
        }
    }
    
    var body: some View {
        ZStack {
            Color.app
                .ignoresSafeArea()
            List {
                ForEach(filteredSurahs) { surah in
                    Button {
                        selectedSurah = surah
                    } label: {
                        SuraRowView(surah: surah, isTranslationEnabled: $isTranslationEnabled)
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("quran_suras")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchQuery,
//                placement: UIDevice.isIPad ? .automatic : .navigationBarDrawer(displayMode: .always)
            )
            .fullScreenCover(item: $selectedSurah) { surah in
//                SuraDetailView(surah: surah, surahs: surahs, onSwitchToSurah: { newSurah in
//                    selectedSurah = nil
//                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
//                        selectedSurah = newSurah
//                    }
//                })
            }
        }
    }
}
