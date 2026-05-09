//
//  ReciterFilter.swift 
// 
import Foundation

public protocol ReciterRow {
    var type: String { get }
}

public enum ReciterFilter: Equatable, Sendable {
    case duaa
    case tilawats
    case featured
    case popular
    /// All rows except `duaa` and `tilawates-and-rouqia`.
    case all
}

public extension Array where Element: ReciterRow {
    func filtered(by option: ReciterFilter) -> [Element] {
        switch option {
        case .duaa:     return filter { $0.type == "duaa" }
        case .tilawats: return filter { $0.type == "tilawates-and-rouqia" }
        case .featured: return filter { $0.type == "featured" }
        case .popular:  return filter { $0.type == "popular" }
        case .all:
            return filter { $0.type != "duaa" && $0.type != "tilawates-and-rouqia" }
        }
    }
}

// MARK: - IslamicCloudReciterDTO 
//
// Defensive trim + lowercase so casing variations from the API 
extension IslamicCloudReciterDTO: ReciterRow {
    public var type: String {
        reciterListType?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}
