//
//  DownloadManagerViewModel.swift
//  new project
//
//  Aggregates download usage across reciters and exposes "clear" actions.
//  Today nothing actually gets persisted to disk yet, so the view shows
//  "Zero KB" / "No downloads"; once a real downloads store is added,
//  inject it here and the UI keeps working as-is.
//

import Foundation
import Combine
struct DownloadManagerReciterEntry: Identifiable, Hashable {
    let id: String
    let reciterName: String
    let bytesOnDisk: Int64

    var formattedSize: String {
        ByteCountFormatter.string(fromByteCount: bytesOnDisk, countStyle: .file)
    }
}

@MainActor
final class DownloadManagerViewModel: ObservableObject {
    @Published private(set) var totalBytes: Int64 = 0
    @Published private(set) var perReciter: [DownloadManagerReciterEntry] = []

    init() {
        refresh()
    }

    var hasDownloads: Bool { totalBytes > 0 || !perReciter.isEmpty }

    /// User-facing total. Falls back to a localized "Zero KB" for the empty state.
    var formattedTotalSize: String {
        guard totalBytes > 0 else {
            return NSLocalizedString("download_manager_zero_kb", comment: "")
        }
        return ByteCountFormatter.string(fromByteCount: totalBytes, countStyle: .file)
    }

    /// Re-reads usage. Hook real storage providers here when implemented.
    func refresh() {
        totalBytes = 0
        perReciter = []
    }

    /// Wipes everything and refreshes the published state.
    func clearAllDownloads() {
        // TODO: Wire to the real download store (audio cache + downloaded suras).
        refresh()
    }

    /// Removes downloads for a single reciter and refreshes.
    func removeDownloads(forReciterId id: String) {
        // TODO: Wire to the real per-reciter download store.
        perReciter.removeAll { $0.id == id }
        recomputeTotal()
    }

    private func recomputeTotal() {
        totalBytes = perReciter.reduce(0) { $0 + $1.bytesOnDisk }
    }
}
