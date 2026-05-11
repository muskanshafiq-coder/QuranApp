//
//  ReadingSurahBookmark.swift
//

import Foundation

/// Quran Reader tab bookmark (shown under Bookmarks → Reading).
struct ReadingSurahBookmark: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    let surahNumber: Int
    let ayahNumber: Int
    let page: Int
    let juz: Int
    let hizbQuarter: Int
    let surahTitleEn: String
    let surahTitleAr: String?
    let createdAt: Date

    init(
        id: UUID = UUID(),
        surahNumber: Int,
        ayahNumber: Int,
        page: Int,
        juz: Int,
        hizbQuarter: Int,
        surahTitleEn: String,
        surahTitleAr: String?,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.surahNumber = surahNumber
        self.ayahNumber = ayahNumber
        self.page = page
        self.juz = juz
        self.hizbQuarter = hizbQuarter
        self.surahTitleEn = surahTitleEn
        self.surahTitleAr = surahTitleAr
        self.createdAt = createdAt
    }
}
