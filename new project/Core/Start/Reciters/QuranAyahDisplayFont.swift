//
//  QuranAyahDisplayFont.swift
//

import CoreText
import SwiftUI
import UIKit

/// Madinah Uthmani HAFS — `Resources/fonts/KFGQPCUthmanic.otf` (see `UIAppFonts`).
enum QuranAyahDisplayFont {
    static let uthmaniHafsPostScriptName = "KFGQPC Uthmanic Script HAFS"

    /// Free tier Arabic font in reciter ayah rows (`Resources/fonts/Nabi Regular.ttf`).
    static let freeReciterArabicFontFamilyId = "Nabi"

    /// PostScript name from the font’s `name` table (id 6) is `Nabi`; `UIFont` may still need explicit registration.
    private static let nabiPreferredPostScriptName = "Nabi"

    private static var didRegisterBundledFonts = false
    private static var resolvedNabiFontNameForSwiftUI: String = nabiPreferredPostScriptName

    /// Call once early in app launch so `Nabi Regular.ttf` is guaranteed registered (matches Info.plist entry).
    static func registerBundledReciterFonts() {
        guard !didRegisterBundledFonts else { return }
        didRegisterBundledFonts = true

        let candidates: [(String, String?)] = [
            ("Nabi Regular", "Resources/fonts"),
            ("Nabi Regular", nil),
            ("Nabi-Regular", "Resources/fonts"),
            ("Nabi-Regular", nil)
        ]
        for (base, sub) in candidates {
            let url = Bundle.main.url(forResource: base, withExtension: "ttf", subdirectory: sub)
                ?? Bundle.main.url(forResource: base, withExtension: "ttf")
            guard let url else { continue }
            var error: Unmanaged<CFError>?
            _ = CTFontManagerRegisterFontsForURL(url as CFURL, .process, &error)
        }

        if UIFont(name: nabiPreferredPostScriptName, size: 20) != nil {
            resolvedNabiFontNameForSwiftUI = nabiPreferredPostScriptName
        } else if let fromFamily = UIFont.fontNames(forFamilyName: "Nabi").first, UIFont(name: fromFamily, size: 20) != nil {
            resolvedNabiFontNameForSwiftUI = fromFamily
        } else {
            resolvedNabiFontNameForSwiftUI = nabiPreferredPostScriptName
        }
    }

    static func uthmani(size: CGFloat) -> Font {
        .custom(uthmaniHafsPostScriptName, size: size)
    }

    /// Arabic body for reciter surah rows: premium users use the selected family from settings; others always use Nabi.
    static func reciterArabicFont(storedFamilyId: String, size: CGFloat, isPremiumUser: Bool) -> Font {
        registerBundledReciterFonts()
        let id = isPremiumUser ? storedFamilyId : Self.freeReciterArabicFontFamilyId
        return fontForStoredFamilyId(id, size: size)
    }

    private static func fontForStoredFamilyId(_ id: String, size: CGFloat) -> Font {
        if id == "SF font" {
            return .system(size: size, weight: .regular)
        }
        let customPostScript: [String: String] = [
            freeReciterArabicFontFamilyId: resolvedNabiFontNameForSwiftUI,
            "Me Quran": "me_quran",
            "PDMS Saleem Quran Font": "PDMS Saleem QuranFont",
            "Al Qalam Quran Majeed Web": "Al Qalam Quran Majeed",
            "Droid Arabic Naskh": "Droid Arabic Naskh",
            "Noto Kufi Arabic": "Noto Kufi Arabic",
            "Noto Naskh Arabic": "Noto Naskh Arabic",
            "Noto Nastaliq Urdu": "Noto Nastaliq Urdu",
            "Scheherazade": "Scheherazade New"
        ]
        if let ps = customPostScript[id] {
            return .custom(ps, size: size)
        }
        return uthmani(size: size)
    }

    /// Resolved name for previews / diagnostics (after `registerBundledReciterFonts()`).
    static var nabiResolvedFontName: String {
        registerBundledReciterFonts()
        return resolvedNabiFontNameForSwiftUI
    }
}
