//
//  ReaderQuranBook.swift
//

import SwiftUI

struct ReaderQuranBook: Identifiable, Hashable {
    enum CoverStyle: Hashable {
        case standard
        case madinah
        case tajweed
        case qiraat
        case translation
        case generic
    }

    let id: Int
    let title: String
    let language: String
    let category: String
    let size: String?
    let downloadURL: URL?
    let thumbnailURL: URL?
    let coverStyle: CoverStyle

    var coverColors: [Color] {
        switch coverStyle {
        case .standard:
            return [
                Color(red: 0.95, green: 0.96, blue: 0.98),
                Color(red: 0.78, green: 0.84, blue: 0.94),
            ]
        case .madinah:
            return [
                Color(red: 0.98, green: 0.98, blue: 0.99),
                Color(red: 0.85, green: 0.90, blue: 0.96),
            ]
        case .tajweed:
            return [
                Color(red: 0.12, green: 0.32, blue: 0.22),
                Color(red: 0.05, green: 0.18, blue: 0.12),
            ]
        case .qiraat:
            return [
                Color(red: 0.42, green: 0.16, blue: 0.20),
                Color(red: 0.22, green: 0.07, blue: 0.10),
            ]
        case .translation:
            return [
                Color(red: 0.16, green: 0.36, blue: 0.44),
                Color(red: 0.06, green: 0.22, blue: 0.28),
            ]
        case .generic:
            return [
                Color(red: 0.94, green: 0.90, blue: 0.82),
                Color(red: 0.78, green: 0.69, blue: 0.55),
            ]
        }
    }
}

extension ReaderQuranBook {
    init(dto: QuranPDFDTO) {
        self.id = dto.id
        self.title = dto.title
        self.language = dto.language
        self.category = dto.category
        self.size = dto.size
        self.downloadURL = dto.downloadURL
        self.thumbnailURL = dto.thumbnailURL
        self.coverStyle = ReaderQuranBook.style(for: dto.category)
    }

    private static func style(for category: String) -> CoverStyle {
        switch category.lowercased() {
        case "standard":    return .standard
        case "madinah":     return .madinah
        case "tajweed":     return .tajweed
        case "qiraat":      return .qiraat
        case "translation": return .translation
        default:            return .generic
        }
    }
}
