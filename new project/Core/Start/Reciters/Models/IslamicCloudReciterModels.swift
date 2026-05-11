//
//  IslamicCloudReciterModels.swift
//

import Foundation

private enum IslamicCloudReciterJSONKey: String, CodingKey {
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

private func decodeSurahCountString(from c: KeyedDecodingContainer<IslamicCloudReciterJSONKey>) -> String? {
    if let s = try? c.decode(String.self, forKey: .surahCount) { return s }
    if let i = try? c.decode(Int.self, forKey: .surahCount) { return String(i) }
    return nil
}

private enum IslamicCloudReciterSurahJSONKey: String, CodingKey {
    case number, slug, audio
    case nameEn = "name_en"
    case nameAr = "name_ar"
    case ayahCount = "ayah_count"
}

private func decodeAyahCount(from c: KeyedDecodingContainer<IslamicCloudReciterSurahJSONKey>) -> Int {
    if let i = try? c.decode(Int.self, forKey: .ayahCount) { return i }
    if let s = try? c.decode(String.self, forKey: .ayahCount), let v = Int(s) { return v }
    return 0
}

struct PlayerReciterDisplayItem: Identifiable, Hashable, Codable {
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

    init(id: String, englishName: String = "", arabicDisplayName: String? = nil, portraitURL: URL? = nil) {
        self.id = id
        self.englishName = englishName
        self.arabicDisplayName = arabicDisplayName
        self.portraitURL = portraitURL
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: IslamicCloudReciterJSONKey.self)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        reciterListType = try c.decodeIfPresent(String.self, forKey: .reciterListType)
        surahCount = decodeSurahCountString(from: c)
    }
}

extension IslamicCloudReciterDTO: ReciterRow {
    public var type: String {
        reciterListType?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: IslamicCloudReciterJSONKey.self)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        bio = try c.decodeIfPresent(String.self, forKey: .bio)
        image = try c.decodeIfPresent(String.self, forKey: .image)
        url = try c.decodeIfPresent(String.self, forKey: .url)
        reciterListType = try c.decodeIfPresent(String.self, forKey: .reciterListType)
        surahs = try c.decodeIfPresent([IslamicCloudReciterSurahItemDTO].self, forKey: .surahs) ?? []
        surahCount = decodeSurahCountString(from: c)
    }
}

extension IslamicCloudReciterDetailPayload {
    /// Synthetic reciter used when presenting `ReciterSurahNowPlayingView` from the Reader tab (no streaming audio list).
    static let readerTabReciterSlug = "quran-reader-tab"

    /// Empty `surahs` so next/previous use Reader tab surah list instead of API playables.
    static var readerTabPlaybackDetail: IslamicCloudReciterDetailPayload {
        IslamicCloudReciterDetailPayload(
            slug: readerTabReciterSlug,
            nameEn: "",
            nameAr: nil,
            bio: nil,
            surahCount: nil,
            image: nil,
            url: nil,
            reciterListType: nil,
            surahs: []
        )
    }

    init(
        slug: String,
        nameEn: String,
        nameAr: String?,
        bio: String?,
        surahCount: String?,
        image: String?,
        url: String?,
        reciterListType: String?,
        surahs: [IslamicCloudReciterSurahItemDTO]
    ) {
        self.slug = slug
        self.nameEn = nameEn
        self.nameAr = nameAr
        self.bio = bio
        self.surahCount = surahCount
        self.image = image
        self.url = url
        self.reciterListType = reciterListType
        self.surahs = surahs
    }

    /// Surahs that have a non-empty `audio` URL, ordered by surah number.
    func playableSurahsSortedByNumber() -> [IslamicCloudReciterSurahItemDTO] {
        surahs
            .filter { !($0.audio?.trimmingCharacters(in: .whitespacesAndNewlines) ?? "").isEmpty }
            .sorted { $0.number < $1.number }
    }

    /// Next surah after `currentNumber` in play order; optional shuffle and wrap for repeat-all.
    func nextPlayableSurah(after currentNumber: Int, shuffle: Bool, wrap: Bool) -> IslamicCloudReciterSurahItemDTO? {
        let list = playableSurahsSortedByNumber()
        guard !list.isEmpty else { return nil }
        if shuffle {
            let others = list.filter { $0.number != currentNumber }
            if let pick = others.randomElement() { return pick }
            return list.first
        }
        guard let i = list.firstIndex(where: { $0.number == currentNumber }) else { return list.first }
        if i + 1 < list.count { return list[i + 1] }
        return wrap ? list.first : nil
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

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: IslamicCloudReciterSurahJSONKey.self)
        number = try c.decode(Int.self, forKey: .number)
        slug = try c.decode(String.self, forKey: .slug)
        nameEn = try c.decode(String.self, forKey: .nameEn)
        nameAr = try c.decodeIfPresent(String.self, forKey: .nameAr)
        audio = try c.decodeIfPresent(String.self, forKey: .audio)
        ayahCount = decodeAyahCount(from: c)
    }

    init(number: Int, slug: String, nameEn: String, nameAr: String?, ayahCount: Int, audio: String?) {
        self.number = number
        self.slug = slug
        self.nameEn = nameEn
        self.nameAr = nameAr
        self.ayahCount = ayahCount
        self.audio = audio
    }

    init(readerSurah surah: SurahItem) {
        let ar = surah.nameArabic.trimmingCharacters(in: .whitespacesAndNewlines)
        self.init(
            number: surah.number,
            slug: "surah-\(surah.number)",
            nameEn: surah.nameEnglish,
            nameAr: ar.isEmpty ? nil : ar,
            ayahCount: surah.numberOfAyahs,
            audio: nil
        )
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
