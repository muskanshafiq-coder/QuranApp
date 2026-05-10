//
//  QuranPDFRepository.swift
//

import Foundation

struct QuranPDFDTO: Decodable, Identifiable, Hashable {
    let id: Int
    let title: String
    let language: String
    let category: String
    let downloadUrl: String
    let size: String?
    let thumbnailUrl: String?

    var downloadURL: URL? {
        URL(string: downloadUrl)
    }

    var thumbnailURL: URL? {
        guard let thumbnailUrl, !thumbnailUrl.isEmpty else { return nil }
        return URL(string: thumbnailUrl)
    }
}

struct QuranPDFListEnvelope: Decodable {
    let code: Int?
    let status: String?
    let data: [QuranPDFDTO]?
}

enum QuranPDFRepository {

    @discardableResult
    static func loadPDFs(
        update: @MainActor @escaping ([QuranPDFDTO]) -> Void
    ) async -> Bool {
        let cacheKey = IslamicCloudAPIClient.cacheKey(for: AppConfig.IslamicCloud.quranPDFsPath)
        var applied = false

        if let data = DiskCache.shared.data(for: cacheKey),
           let envelope = try? JSONDecoder().decode(QuranPDFListEnvelope.self, from: data),
           let list = envelope.data,
           !list.isEmpty {
            await update(list)
            applied = true
        }

        do {
            let fresh = try await IslamicCloudAPIClient.shared.fetchQuranPDFs(cache: true)
            await update(fresh)
            applied = true
        } catch {
            #if DEBUG
            print("[QuranPDFRepository] fetch failed: \(error.localizedDescription)")
            #endif
        }

        return applied
    }
}
