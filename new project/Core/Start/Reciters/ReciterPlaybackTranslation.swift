//
//  ReciterPlaybackTranslation.swift
//

import Foundation
enum ReciterPlaybackTranslation {
    /// Loaded text per translation edition id (same ids as `UserDefaultsManager.Keys.quranSelectedTranslationIds`).
    struct SurahTranslationMaps {
        /// Selection order excluding Arabic mushaf; only ids that successfully loaded (or fallback edition).
        let selectedTranslationIds: [String]
        let translationByAyah: [String: [Int: String]]
    }

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

    static func loadSurahTranslationMaps(surahNumber: Int) async -> SurahTranslationMaps {
        let ids = UserDefaultsManager.shared.quranSelectedTranslationIds
        var translationByAyah: [String: [Int: String]] = [:]
        for raw in ids {
            if raw == "quran-buck" { continue }
            guard let ed = edition(for: raw) else { continue }
            if ed == "en.transliteration" {
                if let m = try? await QuranAPIClient.shared.fetchPhoneticTransliteration(surahNumber: surahNumber) {
                    translationByAyah[raw] = m
                }
            } else if let m = try? await QuranAPIClient.shared.fetchTranslatedSurah(surahNumber: surahNumber, editionIdentifier: ed) {
                translationByAyah[raw] = m
            }
        }
        var selectedTranslationIds = ids.filter { $0 != "quran-buck" && translationByAyah[$0] != nil }
        if selectedTranslationIds.isEmpty {
            if let fallback = try? await QuranAPIClient.shared.fetchTranslatedSurah(surahNumber: surahNumber, editionIdentifier: "en.yusufali") {
                translationByAyah["en.yusufali"] = fallback
                selectedTranslationIds = ["en.yusufali"]
            }
        }
        return SurahTranslationMaps(selectedTranslationIds: selectedTranslationIds, translationByAyah: translationByAyah)
    }

    /// First secondary line per ayah (e.g. for a single-string preview).
    static func loadMap(surahNumber: Int) async -> [Int: String] {
        let bundle = await loadSurahTranslationMaps(surahNumber: surahNumber)
        guard let firstId = bundle.selectedTranslationIds.first else { return [:] }
        return bundle.translationByAyah[firstId] ?? [:]
    }
}
