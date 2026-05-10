//
//  ReciterActionFeedback.swift
//

import AlertKit
import Foundation

enum ReciterActionFeedback {

    static func presentAddedToFavorite() {
        AlertKitAPI.present(
            title: NSLocalizedString("reciter_alert_added_favorite", comment: ""),
            subtitle: nil,
            icon: .heart,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentRemovedFromFavorite() {
        AlertKitAPI.present(
            title: NSLocalizedString("reciter_alert_removed_favorite", comment: ""),
            subtitle: nil,
            icon: .heart,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }

    static func presentShareCompleted() {
        AlertKitAPI.present(
            title: NSLocalizedString("reciter_alert_share_done", comment: ""),
            subtitle: nil,
            icon: .done,
            style: .iOS16AppleMusic,
            haptic: .success
        )
    }
}
