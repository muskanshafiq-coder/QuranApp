//
//  ReciterPlaybackPopupCoordinator.swift
//  new project
//
//  Bridges SwiftUI screens that want to start reciter audio with the
//  UIKit `MainTabBarController`, which actually owns the LNPopupController
//  presentation. SwiftUI calls `present(session:)`; the tab bar controller
//  observes `requestedSession` and presents the popup content VC.
//
//  Mirrors the `SleepViewModel.selectedPlayItem` pattern.
//

import Foundation
import Combine

@MainActor
final class ReciterPlaybackPopupCoordinator: ObservableObject {
    static let shared = ReciterPlaybackPopupCoordinator()

    /// Latest session the UI requested to play. The presenter clears it back
    /// to `nil` once it has been consumed (or when the popup is dismissed),
    /// so re-publishing the same session re-presents it.
    @Published var requestedSession: ReciterPlaybackSession?

    /// When `true` the popup should open in full-screen on present;
    /// when `false` (e.g. auto-advance via the queue) it stays minimized.
    @Published var openFullScreenOnPresent: Bool = true

    /// True while the popup is currently presented (mini bar visible or expanded).
    @Published private(set) var isPopupActive: Bool = false

    private init() {}

    func present(session: ReciterPlaybackSession, openFullScreen: Bool = true) {
        openFullScreenOnPresent = openFullScreen
        requestedSession = session
    }

    /// Called by the popup container after presenting so the published value
    /// can fire again for the next user tap (even if the same session).
    func didConsumeRequest() {
        requestedSession = nil
    }

    func setPopupActive(_ active: Bool) {
        guard isPopupActive != active else { return }
        isPopupActive = active
    }
}
