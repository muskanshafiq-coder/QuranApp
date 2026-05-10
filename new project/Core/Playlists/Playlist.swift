//
//  Playlist.swift
//

import Foundation

struct PlaylistSurahEntry: Identifiable, Codable, Equatable, Hashable {
    var id: Int { surahNumber }

    let surahNumber: Int
    /// Reciter edition slug from Islamic Cloud; empty for playlists saved before this metadata existed.
    let reciterSlug: String
    let englishLine: String
    let arabicLine: String
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
