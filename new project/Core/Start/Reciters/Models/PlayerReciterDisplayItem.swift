//
//  PlayerReciterDisplayItem.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import Foundation

struct PlayerReciterDisplayItem: Identifiable, Hashable {
    let id: String
    let englishName: String
    let arabicDisplayName: String?
    let portraitURL: URL?

    init(dto: IslamicCloudReciterDTO) {
        id = dto.slug
        englishName = dto.nameEn
        let ar = dto.nameAr?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        arabicDisplayName = ar.isEmpty ? nil : ar
        portraitURL = dto.image
            .flatMap { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .flatMap { URL(string: $0) }
    }
}

struct IslamicCloudReciterDTO: Decodable {
    let slug: String
    let nameEn: String
    let nameAr: String?
    let bio: String?
    let surahCount: String?
    let image: String?
    let url: String?
    /// `featured` = home carousel; `standard` = main reciter list (single `/reciters` payload).
    let reciterListType: String?

    enum CodingKeys: String, CodingKey {
        case slug
        case nameEn = "name_en"
        case nameAr = "name_ar"
        case bio
        case surahCount = "surah_count"
        case image
        case url
        case reciterListType = "type"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        reciterListType = try c.decodeIfPresent(String.self, forKey: .reciterListType)
        if let s = try? c.decode(String.self, forKey: .surahCount) {
            surahCount = s
        } else if let i = try? c.decode(Int.self, forKey: .surahCount) {
            surahCount = String(i)
        } else {
            surahCount = nil
        }
    }
}
struct IslamicCloudReciterDetailPayload: Decodable {
    let slug: String
    let nameEn: String
    let nameAr: String?
    let bio: String?
    let surahCount: String?
    let image: String?
    let url: String?
    let reciterListType: String?
    let surahs: [IslamicCloudReciterSurahItemDTO]

    enum CodingKeys: String, CodingKey {
        case slug
        case nameEn = "name_en"
        case nameAr = "name_ar"
        case bio
        case surahCount = "surah_count"
        case image
        case url
        case reciterListType = "type"
        case surahs
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        reciterListType = try c.decodeIfPresent(String.self, forKey: .reciterListType)
        surahs = try c.decodeIfPresent([IslamicCloudReciterSurahItemDTO].self, forKey: .surahs) ?? []
        if let s = try? c.decode(String.self, forKey: .surahCount) {
            surahCount = s
        } else if let i = try? c.decode(Int.self, forKey: .surahCount) {
            surahCount = String(i)
        } else {
            surahCount = nil
        }
    }
}
struct IslamicCloudReciterSurahItemDTO: Decodable, Identifiable, Hashable {
    var id: Int { number }
    let number: Int
    let slug: String
    let nameEn: String
    let nameAr: String?
    let ayahCount: Int
    let audio: String?

    enum CodingKeys: String, CodingKey {
        case number, slug, audio
        case nameEn = "name_en"
        case nameAr = "name_ar"
        case ayahCount = "ayah_count"
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        number = try c.decode(Int.self, forKey: .number)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        audio = try c.decodeIfPresent(String.self, forKey: .audio)
        if let i = try? c.decode(Int.self, forKey: .ayahCount) {
            ayahCount = i
        } else if let s = try? c.decode(String.self, forKey: .ayahCount), let v = Int(s) {
            ayahCount = v
        } else {
            ayahCount = 0
        }
    }
}
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

// MARK: - App models (from API)
struct SurahItem: Identifiable {
    let id: Int
    let number: Int
    let nameArabic: String
    let nameEnglish: String
    let numberOfAyahs: Int
    let revelationType: String
    
    var isMeccan: Bool { revelationType.lowercased() == "meccan" }
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
// MARK: - Surah content (verses)
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
    /// API returns Bool for non-sajda ayahs and object { id, recommended, obligatory } for sajda ayahs
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
struct IslamicCloudReciterDetailEnvelope: Decodable {
    let code: Int?
    let status: String?
    let data: IslamicCloudReciterDetailPayload?
}
struct IslamicCloudRecitersEnvelope: Decodable {
    let code: Int?
    let status: String?
    let data: IslamicCloudRecitersPayload?
}

struct IslamicCloudRecitersPayload: Decodable {
    let reciters: [IslamicCloudReciterDTO]

    enum CodingKeys: String, CodingKey { case reciters }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        reciters = try c.decodeIfPresent([IslamicCloudReciterDTO].self, forKey: .reciters) ?? []
    }
}
