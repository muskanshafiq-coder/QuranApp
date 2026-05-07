//
//  MainTabBarController.swift
//  new project
//
//  Created by apple on 07/05/2026.
//

import Foundation
import UIKit
import SwiftUI
import Combine

private struct MainTab {
    let titleKey: String
    let imageName: String
}

class MainTabBarController: UITabBarController {
    private var languageManager: AppLanguageManager
    private var themeManager: ThemeManager
    private var selectedThemeColorManager: SelectedThemeColorManager
    private var themeColorSubscription: AnyCancellable?

    init(
        languageManager: AppLanguageManager,
        themeManager: ThemeManager,
        selectedThemeColorManager: SelectedThemeColorManager
    ) {
        self.languageManager = languageManager
        self.themeManager = themeManager
        self.selectedThemeColorManager = selectedThemeColorManager
        super.init(nibName: nil, bundle: nil)
        bindThemeColorChanges(to: selectedThemeColorManager)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// SwiftUI environment does not flow into `UIViewController`; `updateUIViewController` calls this when objects change.
    func applyEnvironment(
        languageManager: AppLanguageManager,
        themeManager: ThemeManager,
        selectedThemeColorManager: SelectedThemeColorManager
    ) {
        let colorManagerChanged = self.selectedThemeColorManager !== selectedThemeColorManager
        self.languageManager = languageManager
        self.themeManager = themeManager
        self.selectedThemeColorManager = selectedThemeColorManager

        if colorManagerChanged {
            bindThemeColorChanges(to: selectedThemeColorManager)
        }

        if isViewLoaded {
            updateThemeAppearance()
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
        setupNotificationObservers()

        // iOS 26+ specific behavior
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior = .onScrollDown
        }

    }

    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openHadithOfTheDayTab),
            name: NSNotification.Name("NavigateToHadithOfTheDay"),
            object: nil
        )
    }
    
    @objc private func openHadithOfTheDayTab() {
        selectedIndex = 3 // Today tab (index 0=Prayer, 1=Qibla, 2=Sleep, 3=Today, 4=More)
    }
    @objc private func handleThemeChange() {
        updateThemeAppearance()
    }
    private func setupTabs() {
        let tabConfigs: [MainTab] = [
            MainTab(titleKey: "tab_player",     imageName: "prayer"),
            MainTab(titleKey: "tab_sleep",      imageName: "sleep"),
            MainTab(titleKey: "tab_today",      imageName: "dabba"),
            MainTab(titleKey: "tab_reader",     imageName: "sleep"),
            MainTab(titleKey: "tab_bookmarks",  imageName: "more")
        ]

        func makeHostedPlayer() -> UIHostingController<AnyView> {
            let root = PlayerView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
            return UIHostingController(rootView: AnyView(root))
        }

        viewControllers = tabConfigs.enumerated().map { (index, tab) in
            let vc = makeHostedPlayer()

            vc.tabBarItem = UITabBarItem(
                title: NSLocalizedString(tab.titleKey, comment: "Main tab bar title"),
                image: UIImage(named: tab.imageName)?
                    .resized(to: CGSize(width: 32, height: 32))
                    .withRenderingMode(.alwaysTemplate),
                tag: index
            )
            
            // Safe handling for iOS 15.6+
            if let hostingVC = vc as? UIHostingController<AnyView> {
                hostingVC.view.backgroundColor = .clear
                if #available(iOS 16.0, *) {
                    hostingVC.sizingOptions = .preferredContentSize
                }
            }
            
            return vc
        }
        self.delegate = self
    }
    
    private func setupAppearance() {
        updateThemeAppearance()
    }
    
    private func updateThemeAppearance() {
        tabBar.tintColor = UIColor(selectedThemeColorManager.selectedColor)
        
        if #available(iOS 15.0, *) {
            let appearance = UITabBarAppearance()
            appearance.configureWithDefaultBackground()
            tabBar.standardAppearance = appearance
            tabBar.scrollEdgeAppearance = appearance
        }
    }

    deinit {
        themeColorSubscription?.cancel()
        NotificationCenter.default.removeObserver(self)
    }
}

extension MainTabBarController {
    private func bindThemeColorChanges(to manager: SelectedThemeColorManager) {
        themeColorSubscription?.cancel()
        themeColorSubscription = manager.$selectedColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateThemeAppearance()
            }
    }
}

extension MainTabBarController: UITabBarControllerDelegate {}
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
