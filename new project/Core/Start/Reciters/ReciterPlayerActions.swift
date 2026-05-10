//
//  ReciterPlayerActions.swift
//

import Foundation
import UIKit

@MainActor
enum ReciterPlayerActions {

    static func toggleFavorite(
        reciter: PlayerReciterDisplayItem,
        favorites: FavoriteRecitersViewModel
    ) {
        let added = favorites.toggle(reciter)
        if added {
            ReciterActionFeedback.presentAddedToFavorite()
        } else {
            ReciterActionFeedback.presentRemovedFromFavorite()
        }
    }

    static func openFollow(fromDetailURL detailURLString: String?, deepLinkSlug: String) {
        let trimmed = detailURLString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        if let u = URL(string: trimmed), ["http", "https"].contains(u.scheme?.lowercased() ?? "") {
            UIApplication.shared.open(u)
            return
        }
        let urlTemplate = NSLocalizedString("reciter_share_link_format", comment: "")
        let urlString = String(format: urlTemplate, deepLinkSlug)
        guard let fallback = URL(string: urlString) else { return }
        UIApplication.shared.open(fallback)
    }

    static func shareReciterProfile(
        displayTitle: String,
        fallbackEnglishName: String,
        deepLinkSlug: String,
        onFinish: @escaping () -> Void = {
            ReciterActionFeedback.presentShareCompleted()
        }
    ) {
        let name = displayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let nonEmptyName = name.isEmpty ? fallbackEnglishName : name

        let template = NSLocalizedString("reciter_share_message_format", comment: "")
        let urlTemplate = NSLocalizedString("reciter_share_link_format", comment: "")
        let link = String(format: urlTemplate, deepLinkSlug)
        let message = String(format: template, nonEmptyName, link)

        ShareHelper.presentShareSheet(items: [message]) {
            onFinish()
        }
    }

    static func shareSurahRow(
        reciterDisplayTitle: String,
        fallbackReciterEnglishName: String,
        deepLinkSlug: String,
        surahNumber: Int,
        surahEnglishLine: String
    ) {
        let reciterLabel = reciterDisplayTitle.trimmingCharacters(in: .whitespacesAndNewlines)
        let nonEmptyReciter = reciterLabel.isEmpty ? fallbackReciterEnglishName : reciterLabel
        let bodyFmt = NSLocalizedString("surah_share_body_format", comment: "")
        let urlFmt = NSLocalizedString("surah_share_link_format", comment: "")
        let url = String(format: urlFmt, deepLinkSlug, surahNumber)
        let message = String(format: bodyFmt, nonEmptyReciter, surahEnglishLine, url)
        ShareHelper.presentShareSheet(items: [message])
    }
}
