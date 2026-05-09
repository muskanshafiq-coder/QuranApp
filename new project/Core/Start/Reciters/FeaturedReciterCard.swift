//
//  FeaturedReciterCard.swift 
// 

import SwiftUI

struct FeaturedReciterCard: View {
    let item: PlayerReciterDisplayItem

    var body: some View {
        ZStack(alignment: .bottom) {
            artwork
                .frame(width: 200, height: 250)
                .clipped()
                .cornerRadius(16)

            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(item.englishName)
                        .fontWeight(.bold)
                        .foregroundColor(.black)
                        .lineLimit(1)

                    if let arabic = item.arabicDisplayName, !arabic.isEmpty {
                        Text(arabic)
                            .font(.caption)
                            .foregroundColor(.gray.opacity(0.8))
                            .lineLimit(1)
                    }
                }

                Spacer()

                Image(systemName: "play.fill")
                    .foregroundColor(.black)
                    .padding(8)
                    .background(Color.white)
                    .clipShape(Circle())
            }
            .padding(10)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(12)
            .padding(6)
        }
        .frame(width: 200, height: 250)
    }

    @ViewBuilder
    private var artwork: some View {
        if let url = item.portraitURL {
            AsyncImage(url: url) { phase in
                switch phase {
                case .success(let img):
                    img.resizable().scaledToFill()
                default:
                    Color.gray.opacity(0.25)
                }
            }
        } else {
            Color.gray.opacity(0.25)
        }
    }
}
