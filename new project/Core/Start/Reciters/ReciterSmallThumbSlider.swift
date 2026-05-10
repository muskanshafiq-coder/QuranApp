//
//  ReciterSmallThumbSlider.swift
//

import SwiftUI

struct ReciterSmallThumbSlider: UIViewRepresentable {
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager
    @Binding var value: Double
    let range: ClosedRange<Double>
    /// `true` while the user is touching the thumb (scrubbing).
    var onScrubbingChanged: ((Bool) -> Void)? = nil

    func makeCoordinator() -> Coordinator {
        Coordinator(value: $value, onScrubbingChanged: onScrubbingChanged)
    }

    func makeUIView(context: Context) -> UISlider {
        let s = UISlider(frame: .zero)
        s.minimumValue = Float(range.lowerBound)
        s.maximumValue = Float(range.upperBound)
        s.value = Float(value)
        s.minimumTrackTintColor = UIColor(selectedThemeColorManager.selectedColor)
        s.maximumTrackTintColor = UIColor(selectedThemeColorManager.selectedColor).withAlphaComponent(0.22)
        s.setThumbImage(Self.thumbImage(color: .white, diameter: 10), for: .normal)
        s.setThumbImage(Self.thumbImage(color: .white, diameter: 11), for: .highlighted)
        s.setContentHuggingPriority(.required, for: .vertical)
        s.addTarget(context.coordinator, action: #selector(Coordinator.changed(_:)), for: .valueChanged)
        s.addTarget(context.coordinator, action: #selector(Coordinator.touchDown(_:)), for: .touchDown)
        s.addTarget(
            context.coordinator,
            action: #selector(Coordinator.touchUp(_:)),
            for: [.touchUpInside, .touchUpOutside, .touchCancel]
        )
        return s
    }

    func updateUIView(_ uiView: UISlider, context: Context) {
        context.coordinator.onScrubbingChanged = onScrubbingChanged
        uiView.minimumValue = Float(range.lowerBound)
        uiView.maximumValue = Float(range.upperBound)
        if abs(Double(uiView.value) - value) > 0.0001 {
            uiView.value = Float(value)
        }
        uiView.minimumTrackTintColor =  UIColor(selectedThemeColorManager.selectedColor)
        uiView.maximumTrackTintColor = UIColor(selectedThemeColorManager.selectedColor).withAlphaComponent(0.22)
    }

    final class Coordinator: NSObject {
        var value: Binding<Double>
        var onScrubbingChanged: ((Bool) -> Void)?

        init(value: Binding<Double>, onScrubbingChanged: ((Bool) -> Void)?) {
            self.value = value
            self.onScrubbingChanged = onScrubbingChanged
        }

        @objc func changed(_ sender: UISlider) {
            value.wrappedValue = Double(sender.value)
        }

        @objc func touchDown(_ sender: UISlider) {
            onScrubbingChanged?(true)
        }

        @objc func touchUp(_ sender: UISlider) {
            onScrubbingChanged?(false)
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
