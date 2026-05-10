//
//  ReciterSmallThumbSlider.swift
//

import SwiftUI

struct ReciterSmallThumbSlider: UIViewRepresentable {
    @Binding var value: Double
    let range: ClosedRange<Double>
    let tint: UIColor

    func makeCoordinator() -> Coordinator { Coordinator(value: $value) }

    func makeUIView(context: Context) -> UISlider {
        let s = UISlider(frame: .zero)
        s.minimumValue = Float(range.lowerBound)
        s.maximumValue = Float(range.upperBound)
        s.value = Float(value)
        s.minimumTrackTintColor = tint
        s.maximumTrackTintColor = tint.withAlphaComponent(0.22)
        s.setThumbImage(Self.thumbImage(color: .white, diameter: 10), for: .normal)
        s.setThumbImage(Self.thumbImage(color: .white, diameter: 11), for: .highlighted)
        s.setContentHuggingPriority(.required, for: .vertical)
        s.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        return s
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        uiView.minimumValue = Float(range.lowerBound)
        uiView.maximumValue = Float(range.upperBound)
        if abs(Double(uiView.value) - value) > 0.0001 {
            uiView.value = Float(value)
        }
        uiView.minimumTrackTintColor = tint
        uiView.maximumTrackTintColor = tint.withAlphaComponent(0.22)
    }

    final class Coordinator: NSObject {
        var value: Binding<Double>
        init(value: Binding<Double>) { self.value = value }

        @objc func changed(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }
    }

    private static func thumbImage(color: UIColor, diameter: CGFloat) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: diameter, height: diameter))
        return renderer.image { ctx in
            let rect = CGRect(origin: .zero, size: CGSize(width: diameter, height: diameter))
            ctx.cgContext.setFillColor(color.cgColor)
            ctx.cgContext.fillEllipse(in: rect)
        }
    }
}
