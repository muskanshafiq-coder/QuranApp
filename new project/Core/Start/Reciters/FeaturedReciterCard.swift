//
//  FeaturedReciterCard.swift
//

import SwiftUI

struct FeaturedReciterCard: View {
    let item: PlayerReciterDisplayItem

    private let cardSize = CGSize(width: 250, height: 300)
    private let artworkCornerRadius: CGFloat = 16

    var body: some View {
        ZStack(alignment: .bottom) {
            artwork
                .frame(width: cardSize.width, height: cardSize.height)
                .clipped()
                .overlay(
                    ShimmerSweep()
                        .allowsHitTesting(false)
                )
                .clipShape(RoundedRectangle(cornerRadius: artworkCornerRadius, style: .continuous))

            VStack(alignment: .leading, spacing: 16) {
                Text("featured_reciter_editors_pick")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.8))
                HStack {
                    Text(item.englishName)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .lineLimit(nil)

                    Spacer()

                    Image(systemName: "play.fill")
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.gray)
                        .clipShape(Circle())
                }
            }
            .padding(10)
            .background(Color.gray.opacity(0.6))
            .cornerRadius(12)
            .padding()
        }
        .frame(width: cardSize.width, height: cardSize.height)
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

// MARK: - Shimmer

/// A continuous left → right "light sweep" highlight that travels across the
/// parent view forever. Designed to be applied as an `.overlay` on top of
/// imagery for a subtle premium/featured feel.
private struct ShimmerSweep: View {
    var duration: Double = 3
    var initialDelay: Double = 0
    var bandWidthRatio: CGFloat = 0.28
    var angle: Angle = .degrees(5)
    var maxOpacity: Double = 0.1

    @State private var animate = false

    var body: some View {
        GeometryReader { geo in
            let bandWidth = max(geo.size.width * bandWidthRatio, 60)
            let travel = geo.size.width + bandWidth * 2

            LinearGradient(
                colors: [
                    .white.opacity(0),
                    .white.opacity(maxOpacity * 0.1),
                    .white.opacity(maxOpacity),
                    .white.opacity(maxOpacity * 0.1),
                    .white.opacity(0)
                ],
                startPoint: .leading,
                endPoint: .trailing
            )
            .frame(width: bandWidth, height: geo.size.height * 1.6)
            .rotationEffect(angle)
            .offset(x: animate ? travel - bandWidth : -bandWidth)
            .blendMode(.plusLighter)
            .onAppear {
                withAnimation(
                    .linear(duration: duration)
                        .delay(initialDelay)
                        .repeatForever(autoreverses: false)
                ) {
                    animate = true
                }
            }
        }
    }
}
