//
//  ShareHelper.swift
//

import UIKit

enum ShareHelper {

    private static let popoverDelegate = TopAnchoredPopoverDelegate()

    static func presentShareSheet(items: [Any]) {
        presentShareSheet(items: items, onCompleted: nil)
    }

    /// Presents the share sheet anchored to the top of the screen and forwards the
    /// system completion result via `onCompleted` (only when the share actually
    /// succeeded — cancels are ignored).
    static func presentShareSheet(items: [Any], onCompleted: (() -> Void)?) {
        guard let topVC = topMostViewController() else { return }

        let activityVC = TopAnchoredActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )

        if let onCompleted {
            activityVC.completionWithItemsHandler = { _, completed, _, _ in
                guard completed else { return }
                DispatchQueue.main.async(execute: onCompleted)
            }
        }

        if let popover = activityVC.popoverPresentationController {
            popover.delegate = popoverDelegate
            popover.sourceView = topVC.view
            popover.sourceRect = topAnchorRect(in: topVC.view)
            popover.permittedArrowDirections = .up
        }

        topVC.present(activityVC, animated: true)
    }

    private static func topAnchorRect(in view: UIView) -> CGRect {
        let topInset = view.safeAreaInsets.top
        return CGRect(
            x: view.bounds.midX - 1,
            y: max(topInset, 44) + 4,
            width: 2,
            height: 2
        )
    }

    static func topMostViewController() -> UIViewController? {
        let scenes = UIApplication.shared.connectedScenes
        let activeScene = scenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive } ?? scenes.first as? UIWindowScene

        guard let rootVC = activeScene?
            .windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController else {
            return nil
        }
        return topMost(of: rootVC)
    }

    private static func topMost(of vc: UIViewController) -> UIViewController {
        if let presented = vc.presentedViewController {
            return topMost(of: presented)
        }
        if let nav = vc as? UINavigationController, let visible = nav.visibleViewController {
            return topMost(of: visible)
        }
        if let tab = vc as? UITabBarController, let selected = tab.selectedViewController {
            return topMost(of: selected)
        }
        return vc
    }
}

private final class TopAnchoredActivityViewController: UIActivityViewController {
    override var modalPresentationStyle: UIModalPresentationStyle {
        get { .popover }
        set { /* lock to popover */ }
    }
}

private final class TopAnchoredPopoverDelegate: NSObject, UIPopoverPresentationControllerDelegate {
    func adaptivePresentationStyle(
        for controller: UIPresentationController
    ) -> UIModalPresentationStyle {
        .none
    }

    func adaptivePresentationStyle(
        for controller: UIPresentationController,
        traitCollection: UITraitCollection
    ) -> UIModalPresentationStyle {
        .none
    }
}
