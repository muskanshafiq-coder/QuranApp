//
//  PlaylistSuccessFeedback.swift
//

import AlertKit
import Foundation

enum PlaylistSuccessFeedback {
    static func presentPlaylistCreated() {
        AlertKitAPI.present(
            title: NSLocalizedString("playlist_success_created_title", comment: ""),
            subtitle: nil,
            icon: .done,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentPlaylistRenamed() {
        AlertKitAPI.present(
            title: NSLocalizedString("playlist_success_renamed_title", comment: ""),
            subtitle: nil,
            icon: .done,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }
}
