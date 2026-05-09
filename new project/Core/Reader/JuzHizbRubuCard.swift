//
//  JuzHizbRubuCard.swift
//  new project
//
//  Created by apple on 10/05/2026.
//

import SwiftUI

struct JuzHizbRubuCard: View {
    let item: JuzHizbRubuItem

    /// Sequential Hizb number: Juz 1 → Hizb 1–2, Juz 2 → Hizb 3–4, etc.
    private var hizbNumber: Int {
        (item.index - 1) / 4 + 1
    }

    /// Progress within current Hizb: 2nd Rubu → 0.25, 3rd → 0.50, 4th → 0.75 (each Hizb has 4 Rubu)
    private var hizbProgressTrim: Double {
        let posInHizb = (item.index - 1) % 4
        return Double(posInHizb) * 0.25
    }

    /// Arabic text with decorative Quranic symbols (e.g. Rub El Hizb ۞, End of Ayah ۝, Sajdah ۩) removed.
    private var displayArabicText: String {
        let symbolsToRemove: [Character] = [
            "\u{06DE}", // ۞ Arabic Star of Rub El Hizb
            "\u{06DD}", // ۝ Arabic End of Ayah
            "\u{06E9}"  // ۩ Arabic Place of Sajdah
        ]
        return item.arabicText
            .filter { !symbolsToRemove.contains($0) }
            .trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                if (item.index - 1) % 4 == 0 {
                    Circle()
//                        .stroke(
//                            ThemeColorManager.shared.currentThemeColor,
//                            style: StrokeStyle(
//                                lineWidth: 6,
//                                lineCap: .round,
//                                lineJoin: .round
//                            )
//                        )
                        .frame(width: 32, height: 32)
                        .overlay(
                            Text("\(hizbNumber)")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.gray)
                        )
                } else {
                    let strokeStyle = StrokeStyle(lineWidth: 6, lineCap: .round, lineJoin: .round)
                    ZStack {
                        Circle()
                            .trim(from: hizbProgressTrim, to: 1)
                            .stroke(Color.gray.opacity(0.5), style: strokeStyle)
                            .rotationEffect(.degrees(-90))
                        Circle()
                            .trim(from: 0, to: hizbProgressTrim)
//                            .stroke(ThemeColorManager.shared.currentThemeColor, style: strokeStyle)
                            .rotationEffect(.degrees(-90))
                    }
                    .frame(width: 32, height: 32)
                }
            }
            .frame(width: 32, height: 32)
            
            VStack(alignment: .leading, spacing: 6) {
                HStack{
                    Text(displayArabicText)
                        .font(.custom("Noto Nastaliq Urdu", size: 15))
                        .lineLimit(1)
                        .hidden()
                        .frame(width: 140)
                        .overlay(alignment: .trailing) {
                            Text(displayArabicText)
                                .font(.custom("Noto Nastaliq Urdu", size: 15))
                                .fontWeight(.bold)
                                .foregroundColor(Color(UIColor.label))
                                .lineLimit(1)
                                .fixedSize(horizontal: true, vertical: false)
                                .environment(\.layoutDirection, .rightToLeft)
                        }
                        .clipped()
                    Spacer()
                }
                Text("quran_sura_ayah")
                    .font(.system(size: 13, weight: .regular, design: .rounded))
                    .foregroundColor(Color(UIColor.secondaryLabel))
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
    }
}
