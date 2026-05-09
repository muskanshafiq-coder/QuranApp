//
//  PlayerReciterAvatarCell.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import SwiftUI

struct PlayerReciterAvatarCell: View {
    let item: PlayerReciterDisplayItem
    let diameter: CGFloat
    let isSelected: Bool
    /// When nil, parent should handle navigation (e.g. wrap this cell in `NavigationLink`).
    var onSelect: (() -> Void)?

    init(
        item: PlayerReciterDisplayItem,
        diameter: CGFloat,
        isSelected: Bool,
        onSelect: (() -> Void)? = nil
    ) {
        self.item = item
        self.diameter = diameter
        self.isSelected = isSelected
        self.onSelect = onSelect
    }

    var body: some View {
        Group {
            if let onSelect = onSelect {
                Button(action: onSelect) { avatarContent }
                    .buttonStyle(.plain)
            } else {
                avatarContent
            }
        }
    }

    private var avatarContent: some View {
            VStack(spacing: 10) {
                ZStack {
                    // Gradient + initials always present as fallback
                    Circle()
                        .fill(LinearGradient(
                            colors: PlayerReciterAvatarPalette.gradient(for: item.id),
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        ))

                    Text(PlayerReciterAvatarPalette.initials(for: item.englishName))
                        .font(.system(size: diameter * 0.27, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    // Portrait overlaid on top — covers initials when loaded
                    if let url = item.portraitURL {
                        AsyncImage(url: url) { phase in
                            if case .success(let img) = phase {
                                img.resizable()
                                   .aspectRatio(contentMode: .fill)
                                   .frame(width: diameter, height: diameter)
                                   .clipShape(Circle())
                            }
                        }
                        .frame(width: diameter, height: diameter)
                    }

                    if isSelected {
                     
                    }
                }
                .frame(width: diameter, height: diameter)

                Text(item.englishName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .minimumScaleFactor(0.78)
                    .frame(width: diameter + 16, alignment: .center)
            }
    }
}
enum PlayerReciterAvatarPalette {
    static func initials(for name: String) -> String {
        let parts = name.trimmingCharacters(in: .whitespaces)
            .split(whereSeparator: \.isWhitespace).map(String.init)
        guard !parts.isEmpty else { return "?" }
        if parts.count >= 2 { return "\(parts[0].prefix(1))\(parts[1].prefix(1))".uppercased() }
        return String(parts[0].prefix(2)).uppercased()
    }

    static func gradient(for id: String) -> [Color] {
        let palettes: [[Color]] = [
            [.init(red: 0.42, green: 0.28, blue: 0.62), .init(red: 0.22, green: 0.14, blue: 0.38)],
            [.init(red: 0.18, green: 0.36, blue: 0.58), .init(red: 0.08, green: 0.18, blue: 0.32)],
            [.init(red: 0.52, green: 0.22, blue: 0.28), .init(red: 0.30, green: 0.10, blue: 0.14)],
            [.init(red: 0.16, green: 0.48, blue: 0.42), .init(red: 0.06, green: 0.28, blue: 0.24)],
            [.init(red: 0.38, green: 0.35, blue: 0.18), .init(red: 0.22, green: 0.20, blue: 0.10)],
            [.init(red: 0.28, green: 0.32, blue: 0.52), .init(red: 0.14, green: 0.16, blue: 0.34)],
        ]
        var h = Hasher(); h.combine(id)
        return palettes[abs(h.finalize()) % palettes.count]
    }
}
