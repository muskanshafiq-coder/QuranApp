//
//  ReaderQuranBook.swift
//  new project
//
//  Created by apple on 10/05/2026.
//

import SwiftUI

struct ReaderQuranBook: Identifiable {
    let id: String
    let titleKey: String
    let coverColors: [Color]

    static let mockBooks: [ReaderQuranBook] = [
        ReaderQuranBook(
            id: "standard",
            titleKey: "reader_book_holy_quran",
            coverColors: [
                Color(red: 0.95, green: 0.96, blue: 0.98),
                Color(red: 0.78, green: 0.84, blue: 0.94),
            ]
        ),
        ReaderQuranBook(
            id: "madinah",
            titleKey: "reader_book_madinah",
            coverColors: [
                Color(red: 0.98, green: 0.98, blue: 0.99),
                Color(red: 0.85, green: 0.90, blue: 0.96),
            ]
        ),
        ReaderQuranBook(
            id: "tajweed",
            titleKey: "reader_book_tajweed",
            coverColors: [
                Color(red: 0.12, green: 0.32, blue: 0.22),
                Color(red: 0.05, green: 0.18, blue: 0.12),
            ]
        ),
    ]
}
