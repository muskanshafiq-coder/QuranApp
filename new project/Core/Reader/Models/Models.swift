//
//  Models.swift
//

import Foundation
// Display items for Juz/Hizb/Rubu and Sajdas sections
struct JuzHizbRubuItem: Identifiable {
    let id: Int
    let index: Int           // 1-based display order (Rubu 1, 2, ...)
    let juzNumber: Int       // 1 or 2 for first 5 rubu
    let surahNumber: Int
    let ayahNumber: Int
    let surahNameEnglish: String
    let arabicText: String
}

struct SajdaDisplayItem: Identifiable {
    let id: Int
    let index: Int
    let surahNumber: Int
    let ayahNumber: Int
    let surahNameEnglish: String
    let arabicText: String
    let recommended: Bool
    let obligatory: Bool
}
struct ReadingProgress {
    let surahNumber: Int
    let ayahNumber: Int
    let juz: Int
    let hizbQuarter: Int
}
struct SajdasMeta: Decodable {
    let count: Int
    let references: [SajdaRef]
}

struct SajdaRef: Decodable {
    let surah: Int
    let ayah: Int
    let recommended: Bool
    let obligatory: Bool
}
struct HizbQuartersMeta: Decodable {
    let count: Int
    let references: [HizbQuarterRef]
}

struct HizbQuarterRef: Decodable {
    let surah: Int
    let ayah: Int
}
struct QuranMetaData: Decodable {
    let surahs: SurahsMeta
    let hizbQuarters: HizbQuartersMeta?
    let sajdas: SajdasMeta?
    
    enum CodingKeys: String, CodingKey {
        case surahs, hizbQuarters, sajdas
    }
    
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        surahs = try c.decode(SurahsMeta.self, forKey: .surahs)
        hizbQuarters = try c.decodeIfPresent(HizbQuartersMeta.self, forKey: .hizbQuarters)
        sajdas = try c.decodeIfPresent(SajdasMeta.self, forKey: .sajdas)
    }
}
struct SurahsMeta: Decodable {
    let count: Int
    let references: [SurahReference]
}
struct SurahReference: Decodable {
    let number: Int
    let name: String           // Arabic name
    let englishName: String
    let englishNameTranslation: String
    let numberOfAyahs: Int
    let revelationType: String // "Meccan" or "Medinan"
    
    enum CodingKeys: String, CodingKey {
        case number, name, numberOfAyahs, revelationType
        case englishName
        case englishNameTranslation
    }
}
struct QuranMetaResponse: Decodable {
    let code: Int
    let status: String
    let data: QuranMetaData
}
// MARK: - Mapping
extension SurahReference {
    func toSurahItem() -> SurahItem {
        SurahItem(
            id: number,
            number: number,
            nameArabic: name,
            nameEnglish: englishName,
            numberOfAyahs: numberOfAyahs,
            revelationType: revelationType
        )
    }
}
