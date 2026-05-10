//
//  AudioSurahBookmark.swift
//

import Foundation

struct AudioSurahBookmark: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let reciterSlug: String
    let reciterNameEn: String
    let portraitURLString: String?
    let surahNumber: Int
    let surahTitleEn: String
    let surahTitleAr: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        reciterSlug: String,
        reciterNameEn: String,
        portraitURLString: String?,
        surahNumber: Int,
        surahTitleEn: String,
        surahTitleAr: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.reciterSlug = reciterSlug
        self.reciterNameEn = reciterNameEn
        self.portraitURLString = portraitURLString
        self.surahNumber = surahNumber
        self.surahTitleEn = surahTitleEn
        self.surahTitleAr = surahTitleAr
        self.createdAt = createdAt
    }

    func asPlayerReciterDisplayItem() -> PlayerReciterDisplayItem {
        PlayerReciterDisplayItem(
            id: reciterSlug,
            englishName: reciterNameEn,
            arabicDisplayName: nil,
            portraitURL: portraitURLString.flatMap { URL(string: $0) }
        )
    }
}
