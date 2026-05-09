//
//  PlayerReciterCircleItem.swift 
// 

import SwiftUI

struct PlayerReciterCircleItem: View {
    let item: PlayerReciterDisplayItem

    var body: some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(Color.gray.opacity(0.25))

                if let url = item.portraitURL {
                    AsyncImage(url: url) { phase in
                        if case .success(let img) = phase {
                            img.resizable()
                                .scaledToFill()
                                .frame(width: 70, height: 70)
                                .clipShape(Circle())
                        }
                    }
                    .frame(width: 70, height: 70)
                }
            }
            .frame(width: 70, height: 70)

            Text(item.englishName)
                .font(.caption)
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .frame(width: 80)
        }
    }
}
