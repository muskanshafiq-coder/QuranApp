import Foundation

final class DiskCache {
    static let shared = DiskCache(namespace: "APICache")

    static let remoteImages = DiskCache(namespace: "RemoteImages")

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

    private func sanitize(_ key: String) -> String {
        key.replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "..", with: "_")
    }
}
