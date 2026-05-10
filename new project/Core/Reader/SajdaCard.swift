//
//  SajdaCard.swift
//

import SwiftUI

struct SajdaCard: View {
    let item: SajdaDisplayItem
    @Environment(\.colorScheme) var colorScheme
    private var subtitle: String {
        item.obligatory
        ? "quran_sura_ayah_obligatory"
        : "quran_sura_ayah_recommended"
    }
    
    var body: some View {
        HStack{
            HStack(alignment: .center, spacing: 12) {
                Text("\(item.index)")
                    .font(.system(size: 10, design: .rounded))
                    .foregroundColor(.gray)
                
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.arabicText)
                        .font(.custom("Noto Nastaliq Urdu", size: 15))
                        .lineLimit(1)
                        .hidden()
                        .frame(width: 140)
                        .overlay(alignment: .trailing) {
                            Text(item.arabicText)
                                .font(.custom("Noto Nastaliq Urdu", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor.label))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        .clipped()
                    Text(subtitle)
                        .font(.system(size: 12))
                        .foregroundColor(.gray)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 10)
            Spacer()
        }
    }
}
