//
//  SegmentedControlStyle.swift
//  new project
//
//  Created by apple on 11/05/2026.
//

import SwiftUI

enum SegmentedControlStyle {

    static func apply(for colorScheme: ColorScheme) {
        let appearance = UISegmentedControl.appearance()

        appearance.selectedSegmentTintColor = UIColor(
            Color(hex: colorScheme == .light ? "#d8dcde" : "#414648")
        )

        appearance.setTitleTextAttributes(
            [.foregroundColor: colorScheme == .dark ? UIColor.white : UIColor.black],
            for: .selected
        )

        appearance.setTitleTextAttributes(
            [.foregroundColor: UIColor.label],
            for: .normal
        )
    }
}
