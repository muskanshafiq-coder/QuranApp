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

class MainTabBarController: UITabBarController {
    private var languageManager: AppLanguageManager
    private var themeManager: ThemeManager
    private var selectedThemeColorManager: SelectedThemeColorManager
    private var themeColorSubscription: AnyCancellable?
//    private let sleepViewModel = SleepViewModel()
    private var selectedPlayItemCancellable: AnyCancellable?

    init(
        languageManager: AppLanguageManager,
        themeManager: ThemeManager,
        selectedThemeColorManager: SelectedThemeColorManager
    ) {
        self.languageManager = languageManager
        self.themeManager = themeManager
        self.selectedThemeColorManager = selectedThemeColorManager
        super.init(nibName: nil, bundle: nil)
        themeColorSubscription = selectedThemeColorManager.$selectedColor
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateThemeAppearance()
            }
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
            themeColorSubscription?.cancel()
            themeColorSubscription = selectedThemeColorManager.$selectedColor
                .receive(on: DispatchQueue.main)
                .sink { [weak self] _ in
                    self?.updateThemeAppearance()
                }
        }

        if isViewLoaded {
            updateThemeAppearance()
        }
    }
//    private lazy var sleepPopupBar = SleepPopupBarViewController()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTabs()
        setupAppearance()
        setupNotificationObservers()
        observeSleepPlayItem()
//        popupBar.customBarViewController = sleepPopupBar

        // iOS 26+ specific behavior
        if #available(iOS 26.0, *) {
            self.tabBarMinimizeBehavior = .onScrollDown
        }

        // Start Sleep stories fetch early so Featured / Recently Added isn’t late on first open.
        Task(priority: .userInitiated) {
//            await sleepViewModel.loadCategoriesAndStories()
        }
    }

    private func observeSleepPlayItem() {
//        selectedPlayItemCancellable = sleepViewModel.$selectedPlayItem
//            .dropFirst()
//            .receive(on: DispatchQueue.main)
//            .sink { [weak self] item in
//                guard let self else { return }
//                if let item = item {
//                    self.presentSleepPlayer(item: item)
//                }
//            }
    }

    private func presentSleepPlayer() {
//        let contentVC = SleepPlayContentViewController(
//            item: item,
//            playback: sleepViewModel.sharedPlayback,
//            viewModel: sleepViewModel
//        )
//        let openFull = sleepViewModel.openPopupFullScreenWhenPresenting
//        sleepViewModel.openPopupFullScreenWhenPresenting = true
//        presentPopupBar(with: contentVC, openPopup: openFull, animated: true)
//        if !openFull {
//            DispatchQueue.main.async { contentVC.refreshBarContent() }
//        }
    }
    
    private func setupNotificationObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openHadithOfTheDayTab),
            name: NSNotification.Name("NavigateToHadithOfTheDay"),
            object: nil
        )
//        // Listen for Theme Change
//        NotificationCenter.default.addObserver(
//            self,
//            selector: #selector(handleThemeChange),
//            name: AppNotificationManager.Name.themeDidChange,
//            object: nil
//        )
    }
    
    @objc private func openHadithOfTheDayTab() {
        selectedIndex = 3 // Today tab (index 0=Prayer, 1=Qibla, 2=Sleep, 3=Today, 4=More)
    }
    @objc private func handleThemeChange() {
        updateThemeAppearance()
    }
    private func setupTabs() {
        func hostedPlayer() -> UIHostingController<AnyView> {
            let root = PlayerView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
                .environmentObject(selectedThemeColorManager)
            return UIHostingController(rootView: AnyView(root))
        }

        let tabs: [(UIViewController, String, String)] = [
            (hostedPlayer(), "tab_player", "prayer"),
            (hostedPlayer(), "tab_sleep", "sleep"),
            (hostedPlayer(), "tab_today", "dabba"),
            (hostedPlayer(), "tab_reader", "sleep"),
            (hostedPlayer(), "tab_bookmarks", "more")
        ]
        
        viewControllers = tabs.enumerated().map { (index, element) in
            let (vc, titleKey, imageName) = element
            
            vc.tabBarItem = UITabBarItem(
                title: NSLocalizedString(titleKey, comment: "Main tab bar title"),
                image: UIImage(named: imageName)?
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

extension MainTabBarController: UITabBarControllerDelegate {}
extension UIImage {
    func resized(to size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
