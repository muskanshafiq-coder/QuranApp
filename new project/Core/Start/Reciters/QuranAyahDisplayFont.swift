//
//  QuranAyahDisplayFont.swift
//

import SwiftUI

/// Madinah Uthmani HAFS — `Resources/fonts/KFGQPCUthmanic.otf` (see `UIAppFonts`).
enum QuranAyahDisplayFont {
    static let uthmaniHafsPostScriptName = "KFGQPC Uthmanic Script HAFS"

    static func uthmani(size: CGFloat) -> Font {
        .custom(uthmaniHafsPostScriptName, size: size)
    }
}
