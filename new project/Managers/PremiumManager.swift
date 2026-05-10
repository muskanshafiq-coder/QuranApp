//
//  PremiumManager.swift
//

import Foundation
//import RevenueCat
import Combine

final class PremiumManager: NSObject, ObservableObject {

    static let shared = PremiumManager()

    @Published private(set) var isPremium: Bool = true

    private let defaults = UserDefaults.standard
    private let cacheKey = "is_premium_user"

    private override init() {
//        isPremium = defaults.bool(forKey: cacheKey)
        super.init()
    }

    // MARK: - Manual sync
    func syncWithRevenueCat() {
        Task {
            do {
//                let info = try await Purchases.shared.customerInfo()
//                let active = info.entitlements.active[AppConfig.RevenueCat.entitlementId] != nil
//                await MainActor.run { updatePremiumStatus(active) }
            } catch {
                print("⚠️ PremiumManager: RevenueCat sync failed — \(error.localizedDescription)")
            }
        }
    }

    // MARK: - Status update (always call on MainActor)
//    @MainActor
//    func updatePremiumStatus(_ value: Bool) {
//        guard isPremium != value else { return }
//        isPremium = value
//        defaults.set(value, forKey: cacheKey)
//    }
}

//// MARK: - PurchasesDelegate
//extension PremiumManager: PurchasesDelegate {
//    func purchases(_ purchases: Purchases, receivedUpdated customerInfo: CustomerInfo) {
//        let active = customerInfo.entitlements.active[AppConfig.RevenueCat.entitlementId] != nil
//        Task { await MainActor.run { updatePremiumStatus(active) } }
//    }
//}
