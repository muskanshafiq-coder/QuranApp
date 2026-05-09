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
    enum Icon {
        case asset(String)
        case systemSymbol(String)
    }

    enum Content {
        case player
        case sleep
    }

    let titleKey: String
    let icon: Icon
    let content: Content
}

class MainTabBarController: UITabBarController {
    private var languageManager: AppLanguageManager
    private var themeManager: ThemeManager
    private var selectedThemeColorManager: SelectedThemeColorManager
    private var themeColorSubscription: AnyCancellable?
    private lazy var sleepViewModel: SleepViewModel = SleepViewModel()

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
    func applyEnvironment( languageManager: AppLanguageManager, themeManager: ThemeManager,
        selectedThemeColorManager: SelectedThemeColorManager ) {
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

        // iOS 26+ specific behavior
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior = .onScrollDown
        }

    }
    
    private func setupTabs() {
        let tabConfigs: [MainTab] = [
            MainTab(titleKey: "tab_player",     icon: .systemSymbol("headphones"),       content: .player),
            MainTab(titleKey: "tab_sleep",      icon: .asset("sleep"),                   content: .sleep),
            MainTab(titleKey: "tab_today",      icon: .asset("dabba"),                   content: .player),
            MainTab(titleKey: "tab_reader",     icon: .systemSymbol("book.pages.fill"),  content: .player),
            MainTab(titleKey: "tab_bookmarks",  icon: .systemSymbol("bookmark.fill"),    content: .player)
        ]

        viewControllers = tabConfigs.enumerated().map { (index, tab) in
            let hostingVC = makeHostingController(for: tab.content)

            hostingVC.tabBarItem = UITabBarItem(
                title: NSLocalizedString(tab.titleKey, comment: "Main tab bar title"),
                image: image(for: tab.icon),
                tag: index
            )

            hostingVC.view.backgroundColor = .clear
            if #available(iOS 16.0, *) {
                hostingVC.sizingOptions = .preferredContentSize
            }

            return hostingVC
        }
        self.delegate = self
    }

    private func makeHostingController(for content: MainTab.Content) -> UIHostingController<AnyView> {
        switch content {
        case .player:
            let root = PlayerView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
            return UIHostingController(rootView: AnyView(root))
        case .sleep:
            let root = SleepView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
                .environmentObject(sleepViewModel)
            return UIHostingController(rootView: AnyView(root))
        }
    }

    private func image(for icon: MainTab.Icon) -> UIImage? {
        switch icon {
        case .asset(let name):
            return UIImage(named: name)?
                .resized(to: CGSize(width: 32, height: 32))
                .withRenderingMode(.alwaysTemplate)
        case .systemSymbol(let symbolName):
            let config = UIImage.SymbolConfiguration(pointSize: 16, weight: .regular)
            return UIImage(systemName: symbolName, withConfiguration: config)?
                .withRenderingMode(.alwaysTemplate)
        }
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
