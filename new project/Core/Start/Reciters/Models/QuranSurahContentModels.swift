//
//  QuranSurahContentModels.swift
//

import Foundation

struct SurahItem: Identifiable {
    let id: Int
    let number: Int
    let nameArabic: String
    let nameEnglish: String
    let numberOfAyahs: Int
    let revelationType: String

    var isMeccan: Bool { revelationType.lowercased() == "meccan" }
}

extension SurahItem {
    func displayName(translationEnabled _: Bool) -> String {
        nameEnglish
    }
}

struct QuranComTransliterationResponse: Decodable {
    let translations: [QuranComTranslationEntry]
}

struct QuranComTranslationEntry: Decodable {
    let resourceId: Int
    let text: String
    enum CodingKeys: String, CodingKey {
        case resourceId = "resource_id"
        case text
    }
}

struct SurahResponse: Decodable {
    let code: Int
    let status: String
    let data: SurahData
}

struct SurahData: Decodable {
    let number: Int
    let name: String
    let englishName: String
    let englishNameTranslation: String
    let revelationType: String
    let numberOfAyahs: Int
    let ayahs: [AyahResponse]
}

struct AyahResponse: Decodable {
    let number: Int
    let text: String
    let numberInSurah: Int
    let juz: Int
    let manzil: Int
    let page: Int
    let ruku: Int
    let hizbQuarter: Int
    var sajda: Bool { _sajdaBool ?? false }
    private let _sajdaBool: Bool?

    enum CodingKeys: String, CodingKey {
        case number, text, numberInSurah, juz, manzil, page, ruku, hizbQuarter, sajda
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = try c.decode(Int.self, forKey: .number)
        text = try c.decode(String.self, forKey: .text)
        numberInSurah = try c.decode(Int.self, forKey: .numberInSurah)
        juz = try c.decode(Int.self, forKey: .juz)
        manzil = try c.decode(Int.self, forKey: .manzil)
        page = try c.decode(Int.self, forKey: .page)
        ruku = try c.decode(Int.self, forKey: .ruku)
        hizbQuarter = try c.decode(Int.self, forKey: .hizbQuarter)
        if let b = try? c.decode(Bool.self, forKey: .sajda) {
            _sajdaBool = b
        } else {
            _ = try c.decode(SajdaAyahObject.self, forKey: .sajda)
            _sajdaBool = true
        }
    }

    private struct SajdaAyahObject: Decodable {
        let id: Int
        let recommended: Bool
        let obligatory: Bool
    }
}
