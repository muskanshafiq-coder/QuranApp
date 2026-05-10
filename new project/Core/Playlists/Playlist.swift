//
//  Playlist.swift
//

import Foundation

struct Playlist: Identifiable, Codable, Equatable, Hashable {
    let id: UUID
    var name: String
    var surahIDs: [Int]
    var isDownloaded: Bool
    let createdAt: Date

    init(
        id: UUID = UUID(),
        name: String,
        surahIDs: [Int] = [],
        isDownloaded: Bool = true,
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.surahIDs = surahIDs
        self.isDownloaded = isDownloaded
        self.createdAt = createdAt
    }

    var surahCount: Int { surahIDs.count }
}
