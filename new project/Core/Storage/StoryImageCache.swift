//
//  StoryImageCache.swift
//

import Foundation
import UIKit

final class StoryImageCache {
    static let shared = StoryImageCache()

    private let fileManager = FileManager.default
    private let queue = DispatchQueue(label: "StoryImageCache", qos: .utility)

    private static let dirName = "StoryImageCache"

    private init() {}

    private var cacheDirectory: URL? {
        fileManager.urls(for: .cachesDirectory, in: .userDomainMask).first?
            .appendingPathComponent(Self.dirName, isDirectory: true)
    }

    private func ensureDir() {
        guard let dir = cacheDirectory else { return }
        try? fileManager.createDirectory(at: dir, withIntermediateDirectories: true)
    }

    private func filename(for url: URL) -> String {
        let str = url.absoluteString
        let hash = str.hashValue
        let ext = url.pathExtension.isEmpty ? "img" : url.pathExtension
        return "\(abs(hash)).\(ext)"
    }

    /// Returns local file URL if this image is already cached.
    func cachedFileURL(for remoteURL: URL?) -> URL? {
        guard let remote = remoteURL, let dir = cacheDirectory else { return nil }
        let fileURL = dir.appendingPathComponent(filename(for: remote))
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }

    /// Downloads the image and saves to cache. Returns local file URL on success. Call from background.
    func downloadAndCache(from remoteURL: URL) async -> URL? {
        guard let dir = cacheDirectory else { return nil }
        ensureDir()
        let fileURL = dir.appendingPathComponent(filename(for: remoteURL))
        if fileManager.fileExists(atPath: fileURL.path) { return fileURL }
        guard let (data, _) = try? await URLSession.shared.data(from: remoteURL),
              !data.isEmpty,
              UIImage(data: data) != nil else { return nil }
        try? data.write(to: fileURL)
        return fileManager.fileExists(atPath: fileURL.path) ? fileURL : nil
    }
}
