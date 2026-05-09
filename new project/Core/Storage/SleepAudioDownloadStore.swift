import Foundation

/// Stores Sleep story audio files on-device for offline playback.
///
/// Design:
/// - File-based (no Core Data needed).
/// - Keyed by storyId + languageCode (or "default").
final class SleepAudioDownloadStore {
    static let shared = SleepAudioDownloadStore()

    private init() {}

    private static func log(_ message: String) {
        print("[SleepAudioDownloadStore] \(message)")
    }

    enum DownloadError: Error {
        case invalidRemoteURL
        case missingDocumentsDirectory
    }

    private func baseDirectory() throws -> URL {
        guard let documents = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first else {
            throw DownloadError.missingDocumentsDirectory
        }
        return documents.appendingPathComponent("SleepAudioDownloads", isDirectory: true)
    }

    private func ensureBaseDirectoryExists() throws -> URL {
        let dir = try baseDirectory()
        if !FileManager.default.fileExists(atPath: dir.path) {
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    private func safeComponent(_ raw: String) -> String {
        // Keep it simple and filesystem-safe.
        let allowed = CharacterSet.alphanumerics.union(CharacterSet(charactersIn: "-_"))
        return raw.unicodeScalars.map { allowed.contains($0) ? Character($0) : "_" }.reduce(into: "") { $0.append($1) }
    }

    func localFileURL(storyId: String, languageCode: String?, remoteURL: URL?) throws -> URL {
        let base = try ensureBaseDirectoryExists()
        let lang = (languageCode?.isEmpty == false) ? languageCode! : "default"
        let ext = (remoteURL?.pathExtension.isEmpty == false) ? remoteURL!.pathExtension : "mp3"
        let name = "\(safeComponent(storyId))__\(safeComponent(lang.lowercased())).\(ext)"
        return base.appendingPathComponent(name, isDirectory: false)
    }

    func isDownloaded(storyId: String, languageCode: String?, remoteURL: URL?) -> Bool {
        guard let remoteURL else { return false }
        if let local = try? localFileURL(storyId: storyId, languageCode: languageCode, remoteURL: remoteURL),
           FileManager.default.fileExists(atPath: local.path) {
            return true
        }

        // Default fallback for language mismatch (see resolvePlayableURL).
        if let lang = languageCode, !lang.isEmpty {
            if let localDefault = try? localFileURL(storyId: storyId, languageCode: nil, remoteURL: remoteURL),
               FileManager.default.fileExists(atPath: localDefault.path) {
                return true
            }
        }

        return false
    }

    /// Returns local file if it exists, otherwise returns the remote URL.
    func resolvePlayableURL(storyId: String, languageCode: String?, remoteURL: URL?) -> URL? {
        guard let remoteURL else { return nil }
        if let local = try? localFileURL(storyId: storyId, languageCode: languageCode, remoteURL: remoteURL),
           FileManager.default.fileExists(atPath: local.path) {
            Self.log("resolvePlayableURL: LOCAL (lang-specific). storyId=\(storyId) lang=\(languageCode ?? "default") local=\(local.path)")
            return local
        }

        // If the user downloaded while `languageCode` was nil/empty (=> "default"),
        // but later playback tries with a specific cached language code, fall back to "default".
        if let lang = languageCode, !lang.isEmpty {
            if let localDefault = try? localFileURL(storyId: storyId, languageCode: nil, remoteURL: remoteURL),
               FileManager.default.fileExists(atPath: localDefault.path) {
                Self.log("resolvePlayableURL: LOCAL (default fallback). storyId=\(storyId) requestedLang=\(lang) local=\(localDefault.path)")
                return localDefault
            }
        }

        Self.log("resolvePlayableURL: REMOTE. storyId=\(storyId) lang=\(languageCode ?? "default") remote=\(remoteURL.absoluteString)")
        return remoteURL
    }

    /// Downloads to a temporary file then moves to the final location (atomic).
    func downloadIfNeeded(storyId: String, languageCode: String?, remoteURL: URL) async throws -> URL {
        let target = try localFileURL(storyId: storyId, languageCode: languageCode, remoteURL: remoteURL)
        if FileManager.default.fileExists(atPath: target.path) {
            Self.log("downloadIfNeeded: already downloaded. storyId=\(storyId) lang=\(languageCode ?? "default") local=\(target.path)")
            return target
        }

        let dir = try ensureBaseDirectoryExists()
        Self.log("downloadIfNeeded: ensured directory. dir=\(dir.path)")

        Self.log("downloadIfNeeded: start download. storyId=\(storyId) lang=\(languageCode ?? "default") remote=\(remoteURL.absoluteString)")
        let (tempURL, _) = try await URLSession.shared.download(from: remoteURL)
        Self.log("downloadIfNeeded: downloaded to temp. storyId=\(storyId) temp=\(tempURL.path)")

        // Replace if somehow exists.
        if FileManager.default.fileExists(atPath: target.path) {
            try? FileManager.default.removeItem(at: target)
        }
        try FileManager.default.moveItem(at: tempURL, to: target)
        Self.log("downloadIfNeeded: moved to final. storyId=\(storyId) local=\(target.path) exists=\(FileManager.default.fileExists(atPath: target.path))")
        return target
    }

    /// Removes a previously-downloaded file for the given story/language if it exists.
    func removeDownload(storyId: String, languageCode: String?, remoteURL: URL?) throws {
        let target = try localFileURL(storyId: storyId, languageCode: languageCode, remoteURL: remoteURL)
        guard FileManager.default.fileExists(atPath: target.path) else { return }
        Self.log("removeDownload: removing file. storyId=\(storyId) lang=\(languageCode ?? "default") local=\(target.path)")
        try FileManager.default.removeItem(at: target)
    }
}

