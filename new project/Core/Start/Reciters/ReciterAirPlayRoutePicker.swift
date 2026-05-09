//
//  ReciterAirPlayRoutePicker.swift
//  new project
//
//  Created by apple on 09/05/2026.
//

import SwiftUI
import AVFoundation
import AVKit
struct ReciterAirPlayRoutePicker: UIViewRepresentable {
    let tint: UIColor

    func makeUIView(context: Context) -> AVRoutePickerView {
        let v = AVRoutePickerView(frame: .zero)
        v.prioritizesVideoDevices = false
        v.backgroundColor = .clear
        v.tintColor = tint.withAlphaComponent(0.9)
        v.activeTintColor = tint
        return v
    }

    func updateUIView(_ uiView: AVRoutePickerView, context: Context) {
        uiView.tintColor = tint.withAlphaComponent(0.9)
        uiView.activeTintColor = tint
    }
}
