//
//  DiskCache.swift
//  Quran App
//
//  Tiny generic key/value cache that stores raw bytes under
//  `Caches/<namespace>/`. Use for any API response we want to render instantly
//  on the next launch (reciters, stories, etc.) without forcing the underlying
//  models to be `Encodable`.
//

import Foundation

final class DiskCache {
    /// Default cache used by `ReciterRepository`. Other features can create
    /// their own instance with a different namespace.
    static let shared = DiskCache(namespace: "APICache")

    private let directoryURL: URL?
    private let fileManager = FileManager.default

    init(namespace: String) {
        self.directoryURL = fileManager
            .urls(for: .cachesDirectory, in: .userDomainMask)
            .first?
            .appendingPathComponent(namespace, isDirectory: true)
    }

    func data(for key: String) -> Data? {
        guard let url = fileURL(for: key) else { return nil }
        return try? Data(contentsOf: url)
    }

    func setData(_ data: Data, for key: String) {
        guard let directoryURL, let url = fileURL(for: key) else { return }
        try? fileManager.createDirectory(at: directoryURL, withIntermediateDirectories: true)
        try? data.write(to: url, options: .atomic)
    }

    func remove(for key: String) {
        guard let url = fileURL(for: key) else { return }
        try? fileManager.removeItem(at: url)
    }

    private func fileURL(for key: String) -> URL? {
        directoryURL?.appendingPathComponent(sanitize(key))
    }

    /// Strip path separators so keys can never escape the cache directory.
    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
    }
}
