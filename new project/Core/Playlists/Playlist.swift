//
//  Playlist.swift
//

import Foundation

struct PlaylistSurahEntry: Identifiable, Equatable, Hashable {
    var id: Int { surahNumber }

    let surahNumber: Int
    /// Reciter edition slug from Islamic Cloud; empty for playlists saved before this metadata existed.
    let reciterSlug: String
    let englishLine: String
    let arabicLine: String
    let reciterNameEn: String
    let portraitURLString: String?

    init(
        surahNumber: Int,
        reciterSlug: String,
        englishLine: String,
        arabicLine: String,
        reciterNameEn: String = "",
        portraitURLString: String? = nil
    ) {
        self.surahNumber = surahNumber
        self.reciterSlug = reciterSlug
        self.englishLine = englishLine
        self.arabicLine = arabicLine
        self.reciterNameEn = reciterNameEn
        self.portraitURLString = portraitURLString
    }
}

extension PlaylistSurahEntry: Codable {
    enum CodingKeys: String, CodingKey {
        case surahNumber
        case reciterSlug
        case englishLine
        case arabicLine
        case reciterNameEn
        case portraitURLString
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        surahNumber = try c.decode(Int.self, forKey: .surahNumber)
        reciterSlug = try c.decodeIfPresent(String.self, forKey: .reciterSlug) ?? ""
        englishLine = try c.decode(String.self, forKey: .englishLine)
        arabicLine = try c.decodeIfPresent(String.self, forKey: .arabicLine) ?? ""
        reciterNameEn = try c.decodeIfPresent(String.self, forKey: .reciterNameEn) ?? ""
        portraitURLString = try c.decodeIfPresent(String.self, forKey: .portraitURLString)
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(surahNumber, forKey: .surahNumber)
        try c.encode(reciterSlug, forKey: .reciterSlug)
        try c.encode(englishLine, forKey: .englishLine)
        try c.encode(arabicLine, forKey: .arabicLine)
        try c.encode(reciterNameEn, forKey: .reciterNameEn)
        try c.encodeIfPresent(portraitURLString, forKey: .portraitURLString)
    }
}

extension PlaylistSurahEntry {
    func navigationReciter(preferredSlugFallback: String) -> PlayerReciterDisplayItem {
        let slugPart = reciterSlug.trimmingCharacters(in: .whitespacesAndNewlines)
        let fallbackPart = preferredSlugFallback.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedId = slugPart.isEmpty ? fallbackPart : slugPart
        let portrait = portraitURLString.flatMap { $0.isEmpty ? nil : URL(string: $0) }
        let name = reciterNameEn.trimmingCharacters(in: .whitespacesAndNewlines)
        return PlayerReciterDisplayItem(
            id: resolvedId,
            englishName: name,
            arabicDisplayName: nil,
            portraitURL: portrait
        )
    }
}

struct Playlist: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var entries: [PlaylistSurahEntry]
    var isDownloaded: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        entries: [PlaylistSurahEntry] = [],
        isDownloaded: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.entries = entries
        self.isDownloaded = isDownloaded
        self.createdAt = createdAt
    }

    var surahCount: Int { entries.count }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case entries
        case surahIDs
        case isDownloaded
        case createdAt
    }

    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decode(UUID.self, forKey: .id)
        name = try c.decode(String.self, forKey: .name)
        isDownloaded = try c.decode(Bool.self, forKey: .isDownloaded)
        createdAt = try c.decode(Date.self, forKey: .createdAt)

        if let decodedEntries = try c.decodeIfPresent([PlaylistSurahEntry].self, forKey: .entries) {
            entries = decodedEntries
        } else if let legacy = try c.decodeIfPresent([Int].self, forKey: .surahIDs) {
            let format = NSLocalizedString("playlist_surah_row_format", comment: "")
            entries = legacy.map { n in
                PlaylistSurahEntry(
                    surahNumber: n,
                    reciterSlug: "",
                    englishLine: String(format: format, n),
                    arabicLine: ""
                )
            }
        } else {
            entries = []
        }
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(id, forKey: .id)
        try c.encode(name, forKey: .name)
        try c.encode(entries, forKey: .entries)
        try c.encode(isDownloaded, forKey: .isDownloaded)
        try c.encode(createdAt, forKey: .createdAt)
    }
}
