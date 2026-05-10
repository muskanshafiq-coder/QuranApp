//
//  ReciterPlaybackTranslation.swift
//

import Foundation
enum ReciterPlaybackTranslation {
    private static let legacyToEdition: [String: String] = [
        "ar": "quran-buck",
        "ur": "ur.jalandhry",
        "en": "en.shakir",
        "en_yusuf_ali": "en.yusufali",
        "en_phonetic": "en.transliteration"
    ]

    private static func edition(for storageId: String) -> String? {
        if storageId.contains(".") { return storageId }
        return legacyToEdition[storageId]
    }

    static func loadMap(surahNumber: Int) async -> [Int: String] {
        let ids = UserDefaultsManager.shared.quranSelectedTranslationIds
        for raw in ids {
            if raw == "quran-buck" { continue }
            guard let ed = edition(for: raw) else { continue }
            if ed == "en.transliteration" {
                if let m = try? await QuranAPIClient.shared.fetchPhoneticTransliteration(surahNumber: surahNumber) {
                    return m
                }
            } else {
                if let m = try? await QuranAPIClient.shared.fetchTranslatedSurah(surahNumber: surahNumber, editionIdentifier: ed) {
                    return m
                }
            }
        }
        return (try? await QuranAPIClient.shared.fetchTranslatedSurah(surahNumber: surahNumber, editionIdentifier: "en.yusufali")) ?? [:]
    }
}
