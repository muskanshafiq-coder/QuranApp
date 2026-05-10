//
//  SurahRowActionFeedback.swift
//

import AlertKit
import Foundation
import UIKit

enum SurahRowActionFeedback {

    static func presentAddedToPlaylist(playlistName: String) {
        let fmt = NSLocalizedString("surah_alert_added_playlist_format", comment: "")
        AlertKitAPI.present(
            title: String(format: fmt, playlistName),
            subtitle: nil,
            icon: .done,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentAlreadyInPlaylist(playlistName: String) {
        let fmt = NSLocalizedString("surah_alert_already_in_playlist_format", comment: "")
        AlertKitAPI.present(
            title: String(format: fmt, playlistName),
            subtitle: nil,
            icon: .done,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentAddedToBookmark() {
        AlertKitAPI.present(
            title: NSLocalizedString("surah_alert_added_bookmark", comment: ""),
            subtitle: nil,
            icon: bookmarkIcon(),
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentAddedToQueue() {
        AlertKitAPI.present(
            title: NSLocalizedString("surah_alert_added_queue", comment: ""),
            subtitle: nil,
            icon: queueIcon(),
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    private static func bookmarkIcon() -> AlertIcon {
        if let img = UIImage(systemName: "bookmark.fill") {
            return .custom(img)
        }
        return .done
    }

    private static func queueIcon() -> AlertIcon {
        if let img = UIImage(systemName: "text.line.first.and.arrowtriangle.forward") {
            return .custom(img)
        }
        return .done
    }
}
