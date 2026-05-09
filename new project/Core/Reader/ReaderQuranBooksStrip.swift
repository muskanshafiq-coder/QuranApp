//
//  ReaderQuranBooksStrip.swift
//  new project
//
//  Created by apple on 10/05/2026.
//

import SwiftUI

struct ReaderQuranBooksStrip: View {
    private let bookWidth: CGFloat = 108
    private let bookHeight: CGFloat = 142
    private let corner: CGFloat = 14

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 16) {
                    ForEach(ReaderQuranBook.mockBooks) { book in
                        bookCell(book)
                    }
                }
                .padding(.horizontal, 2)
                .padding(.vertical, 4)
            }
        }
    }

    private func bookCell(_ book: ReaderQuranBook) -> some View {
        Button {
            // Selection / edition picker when API is wired
        } label: {
        VStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: corner, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: book.coverColors,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: bookWidth, height: bookHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: corner, style: .continuous)
                            .stroke(Color.white.opacity(book.id == "tajweed" ? 0.15 : 0.35), lineWidth: 1)
                    )
                    .shadow(color: .black.opacity(0.35), radius: 8, x: 0, y: 4)

                // Decorative spine / motif
                if book.id == "tajweed" {
                    Image(systemName: "text.book.closed.fill")
                        .font(.system(size: 36, weight: .light))
                        .foregroundStyle(.white.opacity(0.35))
                } else {
                    RoundedRectangle(cornerRadius: 3, style: .continuous)
                        .fill(
                            book.id == "madinah"
                                ? Color.blue.opacity(0.45)
                                : Color.red.opacity(0.35)
                        )
                        .frame(width: 10, height: bookHeight * 0.55)
                        .offset(x: -bookWidth * 0.28)
                }
            }

            Text(book.titleKey)
                .font(.system(size: 13, weight: .semibold, design: .rounded))
                .foregroundColor(Color(UIColor.label))
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: bookWidth + 8)
        }
        }
        .buttonStyle(.plain)
    }
}
