//
//  HideNavBarOnSwipe.swift
//  new project
//
//  SwiftUI's `ScrollView` does not drive `UINavigationController.hidesBarsOnSwipe`
//  (that only works for UIKit-managed scroll views). This file implements the
//  same UX by reading the content offset via a `PreferenceKey` and toggling
//  `setNavigationBarHidden(_:animated:)` on the nearest navigation controller.
//

import SwiftUI
import UIKit

// MARK: - Scroll offset → preference

/// Named coordinate space for the reciter now-playing `ScrollView`.
enum ReciterNowPlayingScrollSpace {
    static let name = "reciterNowPlayingScroll"
}

struct ScrollTopMinYForNavBarPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .infinity

    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        let next = nextValue()
        if next.isFinite {
            value = next
        }
    }
}

/// Where to insert `ToolbarSpacer` when supported (iOS 26+).
enum ToolbarSpacerIfAvailableSide {
    case leading
    case trailing
}

extension View {
    /// Place on content inside a `ScrollView` that uses `.coordinateSpace(name:)`
    /// matching `ReciterNowPlayingScrollSpace.name`.
    func reportScrollTopMinYForNavigationBar() -> some View {
        background(
            GeometryReader { geo in
                Color.clear.preference(
                    key: ScrollTopMinYForNavBarPreferenceKey.self,
                    value: geo.frame(in: .named(ReciterNowPlayingScrollSpace.name)).minY
                )
            }
        )
    }

    /// Drives the UIKit navigation bar (including SwiftUI `.toolbar` items)
    /// for the nearest `UINavigationController`.
    func navigationBarUIKitHidden(_ hidden: Bool) -> some View {
        background(NavigationBarUIKitVisibilityBridge(isHidden: hidden))
    }

    /// Inserts `ToolbarSpacer` on supported OS versions (e.g. between leading controls, or trailing groups).
    @ViewBuilder
    func toolbarSpacerIfAvailable(_ side: ToolbarSpacerIfAvailableSide = .trailing) -> some View {
        if #available(iOS 26.0, *) {
            self.toolbar {
                switch side {
                case .leading:
                    ToolbarSpacer(placement: .topBarLeading)
                case .trailing:
                    ToolbarSpacer(placement: .topBarTrailing)
                }
            }
        } else {
            self
        }
    }
}

// MARK: - UIKit bridge

private struct NavigationBarUIKitVisibilityBridge: UIViewRepresentable {
    let isHidden: Bool

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> UIView {
        UIView()
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        guard context.coordinator.lastApplied != isHidden else { return }
        context.coordinator.lastApplied = isHidden

        // We deliberately avoid `setNavigationBarHidden(_:animated:)` because
        // it shrinks/expands the safe area and yanks the SwiftUI scroll
        // content. Instead, animate the bar's translation + alpha so the
        // layout stays constant — only the bar visually slides off / back in.
        DispatchQueue.main.async {
            guard let bar = uiView.nearestNavigationController()?.navigationBar else { return }
            applyVisibility(to: bar, hidden: isHidden)
        }
    }

    private func applyVisibility(to bar: UINavigationBar, hidden: Bool) {
        let height = bar.bounds.height > 0 ? bar.bounds.height : 44
        let targetY: CGFloat = hidden ? -height : 0
        let targetAlpha: CGFloat = hidden ? 0 : 1

        UIView.animate(
            withDuration: 0.28,
            delay: 0,
            options: [.beginFromCurrentState, .curveEaseInOut, .allowUserInteraction],
            animations: {
                bar.transform = CGAffineTransform(translationX: 0, y: targetY)
                bar.alpha = targetAlpha
            },
            completion: nil
        )
    }

    final class Coordinator {
        var lastApplied: Bool?
    }
}

private extension UIView {
    /// Walks the responder chain to find a `UINavigationController` hosting this view.
    func nearestNavigationController() -> UINavigationController? {
        var responder: UIResponder? = self
        while let current = responder {
            if let nav = current as? UINavigationController {
                return nav
            }
            if let vc = current as? UIViewController, let nav = vc.navigationController {
                return nav
            }
            responder = current.next
        }
        return nil
    }
}
