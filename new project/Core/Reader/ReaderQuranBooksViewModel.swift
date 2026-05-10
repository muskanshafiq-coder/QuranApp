//
//  ReaderQuranBooksViewModel.swift
//

import Foundation
import SwiftUI
import Combine

@MainActor
final class ReaderQuranBooksViewModel: ObservableObject {
    @Published private(set) var books: [ReaderQuranBook] = []
    @Published private(set) var isLoading = false
    @Published private(set) var loadError: String?

    private var hasLoaded = false

    func loadIfNeeded() async {
        guard !hasLoaded else { return }
        hasLoaded = true
        await load()
    }

    func reload() async {
        await load()
    }

    private func load() async {
        loadError = nil
        if books.isEmpty { isLoading = true }
        defer { isLoading = false }

        let didApply = await QuranPDFRepository.loadPDFs { [weak self] dtos in
            guard let self else { return }
            self.books = dtos.map(ReaderQuranBook.init(dto:))
        }

        if !didApply && books.isEmpty {
            loadError = NSLocalizedString("loading", comment: "")
        }
    }
}
