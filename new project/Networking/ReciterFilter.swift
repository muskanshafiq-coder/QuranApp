//
//  ReciterFilter.swift 
// 
import Foundation

public protocol ReciterRow {
    var type: String { get }
}

public enum ReciterFilter: Equatable, Sendable {
    case duaa
    case tilawats
    case featured
    case popular
    /// All rows except `duaa` and `tilawates-and-rouqia`.
    case all
}

public extension Array where Element: ReciterRow {
    func filtered(by option: ReciterFilter) -> [Element] {
        switch option {
        case .duaa:     return filter { $0.type == "duaa" }
        case .tilawats: return filter { $0.type == "tilawates-and-rouqia" }
        case .featured: return filter { $0.type == "featured" }
        case .popular:  return filter { $0.type == "popular" }
        case .all:
            return filter { $0.type != "duaa" && $0.type != "tilawates-and-rouqia" }
        }
    }
}

extension IslamicCloudReciterDTO: ReciterRow {
    public var type: String {
        reciterListType?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}

enum ReciterRepository {

    @discardableResult
    static func loadReciters(
        update: @MainActor @escaping ([IslamicCloudReciterDTO]) -> Void
    ) async -> Bool {
        let key = IslamicCloudAPIClient.cacheKey(for: AppConfig.IslamicCloud.recitersPath)
        return await load(
            cacheKey: key,
            decode: { (envelope: IslamicCloudRecitersEnvelope) in envelope.data?.reciters ?? [] },
            fetch: { try await IslamicCloudAPIClient.shared.fetchReciters(cache: true) },
            isUsable: { !$0.isEmpty },
            update: update
        )
    }

    @discardableResult
    static func loadReciterDetail(
        slug: String,
        update: @MainActor @escaping (IslamicCloudReciterDetailPayload) -> Void
    ) async -> Bool {
        let trimmed = slug.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return false }
        let key = IslamicCloudAPIClient.cacheKey(
            for: AppConfig.IslamicCloud.recitersPath + "/" + trimmed
        )
        return await load(
            cacheKey: key,
            decode: { (envelope: IslamicCloudReciterDetailEnvelope) in envelope.data },
            fetch: { try await IslamicCloudAPIClient.shared.fetchReciterDetail(slug: trimmed, cache: true) },
            isUsable: { _ in true },
            update: update
        )
    }

    private static func load<Envelope: Decodable, Value>(
        cacheKey: String,
        decode: (Envelope) -> Value?,
        fetch: () async throws -> Value,
        isUsable: (Value) -> Bool,
        update: @MainActor @escaping (Value) -> Void
    ) async -> Bool {
        var applied = false

        if let data = DiskCache.shared.data(for: cacheKey),
           let envelope = try? JSONDecoder().decode(Envelope.self, from: data),
           let value = decode(envelope),
           isUsable(value) {
            await update(value)
            applied = true
        }

        do {
            let fresh = try await fetch()
            await update(fresh)
            applied = true
        } catch {}

        return applied
    }
}
