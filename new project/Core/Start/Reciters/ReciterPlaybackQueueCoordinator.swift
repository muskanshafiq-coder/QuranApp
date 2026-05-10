//
//  ReciterPlaybackQueueCoordinator.swift
//

import Foundation

@MainActor
final class ReciterPlaybackQueueCoordinator {
    static let shared = ReciterPlaybackQueueCoordinator()

    private var next: ReciterPlaybackSession?

    var hasQueuedSession: Bool { next != nil }

    func enqueuePlayNext(_ session: ReciterPlaybackSession) {
        next = session
    }

    /// Returns and clears the queued session, if any.
    func dequeueNext() -> ReciterPlaybackSession? {
        defer { next = nil }
        return next
    }

    func cancelQueued() {
        next = nil
    }
}
