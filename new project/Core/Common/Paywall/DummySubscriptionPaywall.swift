//
//  DummySubscriptionPaywall.swift
//

import Combine
import SwiftUI

/// Presents a placeholder subscription UI from anywhere in the app.
@MainActor
final class DummyPaywallPresenter: ObservableObject {
    static let shared = DummyPaywallPresenter()

    @Published var isPresented = false

    private init() {}

    func present() {
        isPresented = true
    }

    func dismiss() {
        isPresented = false
    }
}

struct DummySubscriptionPaywallView: View {
    @EnvironmentObject private var selectedThemeColorManager: SelectedThemeColorManager

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(selectedThemeColorManager.selectedColor)
                    .padding(.top, 8)

                Text("dummy_paywall_title")
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)

                Text("dummy_paywall_message")
                    .font(.system(size: 16, weight: .regular))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 8)

                Spacer(minLength: 12)

                Button {
                    PremiumManager.shared.updatePremiumStatus(true)
                    DummyPaywallPresenter.shared.dismiss()
                } label: {
                    Text("dummy_paywall_subscribe")
                        .font(.system(size: 17, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                }
                .buttonStyle(.borderedProminent)
                .tint(selectedThemeColorManager.selectedColor)

                Button {
                    DummyPaywallPresenter.shared.dismiss()
                } label: {
                    Text("dummy_paywall_later")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundStyle(.secondary)
                }
                .padding(.bottom, 8)
            }
            .padding(24)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        DummyPaywallPresenter.shared.dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel(Text("alert_cancel"))
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }
}
