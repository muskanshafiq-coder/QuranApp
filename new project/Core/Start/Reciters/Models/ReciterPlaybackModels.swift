//
//  ReciterPlaybackModels.swift
//

import Foundation

struct ReciterPlaybackSession: Identifiable {
    let id: String
    let detail: IslamicCloudReciterDetailPayload
    let surah: IslamicCloudReciterSurahItemDTO

    init(detail: IslamicCloudReciterDetailPayload, surah: IslamicCloudReciterSurahItemDTO) {
        self.id = "\(detail.slug)-\(surah.number)"
        self.detail = detail
        self.surah = surah
    }
}

struct PlayerSurahRowModel: Identifiable, Hashable {
    var id: Int { number }
    let number: Int
    let englishLine: String
    let arabicLine: String
    let audioURL: URL?

    init(surah: IslamicCloudReciterSurahItemDTO) {
        number = surah.number
        let en = surah.nameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        englishLine = en.lowercased().hasPrefix("surah") ? en : "Surah \(en)"
        arabicLine = surah.nameAr?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        audioURL = surah.audio.flatMap { URL(string: $0) }
    }
}

struct AyahItem: Identifiable {
    let id: Int
    let numberInSurah: Int
    let text: String
    let juz: Int
    let hizbQuarter: Int
    let page: Int
}
