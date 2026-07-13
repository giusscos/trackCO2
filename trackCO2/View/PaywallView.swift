//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    var embedsNavigationStack: Bool = true
    var onPurchaseComplete: (() -> Void)? = nil
    
    @Environment(Store.self) private var storeKit
    
    @State private var showingLifetimePlan = false
    
    private let paywallHealth = ClaudHealth(score: 0.85)
    
    private struct Benefit: Identifiable {
        var id: String { icon }
        let icon: String
        let accent: Color
        let text: LocalizedStringKey
    }
    
    private let benefits: [Benefit] = [
        Benefit(icon: "chart.bar.fill", accent: .green, text: "Log daily activities and see your real CO₂ footprint grow over time."),
        Benefit(icon: "map.fill", accent: .blue, text: "Compare transport options and always pick the greenest route."),
        Benefit(icon: "figure.walk", accent: .mint, text: "Auto-sync steps and walking distance from Apple Health."),
        Benefit(icon: "cloud.sun.fill", accent: .cyan, text: "Weather-smart nudges: get prompted to walk or cycle when air is clean and skies are clear."),
        Benefit(icon: "lightbulb.fill", accent: .yellow, text: "Get weekly insights and tips to reduce your impact.")
    ]
    
    var body: some View {
        Group {
            if embedsNavigationStack {
                NavigationStack {
                    paywallContent
                }
            } else {
                paywallContent
            }
        }
        .onInAppPurchaseCompletion { _, result in
            await handleInAppPurchaseCompletion(result)
        }
        .subscriptionStatusTask(for: storeKit.groupId) { status in
            guard hasActiveSubscription(status) else { return }
            completePurchase()
        }
        .onChange(of: storeKit.hasPaid) { _, paid in
            guard paid else { return }
            completePurchase()
        }
    }

    @MainActor
    private func completePurchase() {
        onPurchaseComplete?()
    }

    private func handleInAppPurchaseCompletion(_ result: Result<Product.PurchaseResult, Error>) async {
        switch result {
        case .success(let purchaseResult):
            switch purchaseResult {
            case .success(let verification):
                if let transaction = try? storeKit.checkVerified(verification) {
                    storeKit.recordEntitlement(for: transaction)
                    await storeKit.updateCustomerProductStatus()
                    await transaction.finish()
                }
                completePurchase()
            case .pending:
                await storeKit.updateCustomerProductStatus()
                if storeKit.hasPaid {
                    completePurchase()
                }
            case .userCancelled:
                break
            @unknown default:
                break
            }
        case .failure:
            break
        }
    }

    private func hasActiveSubscription(_ status: EntitlementTaskState<[Product.SubscriptionInfo.Status]>) -> Bool {
        guard let statuses = status.value else { return false }
        return statuses.contains { subscriptionStatus in
            switch subscriptionStatus.state {
            case .subscribed, .inGracePeriod, .inBillingRetryPeriod:
                return true
            default:
                return false
            }
        }
    }
    
    private var paywallContent: some View {
        SubscriptionStoreView(groupID: storeKit.groupId) {
            VStack(spacing: 16) {
                VStack(spacing: 6) {
                    ClaudCloudView(
                        color: paywallHealth.cloudBodyColor,
                        baseEyeOpenness: paywallHealth.baseEyeOpenness,
                        isHungry: false
                    )
                    .scaleEffect(1.2)
                    .padding(.vertical, 8)

                    Text("Unlock Premium")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Understand your impact and make greener choices every day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 10) {
                    ForEach(Array(benefits.enumerated()), id: \.element.id) { index, benefit in
                        PaywallBenefitRow(
                            icon: benefit.icon,
                            accent: benefit.accent,
                            text: benefit.text,
                            index: index
                        )
                    }
                }

                Button {
                    showingLifetimePlan = true
                } label: {
                    Label("Save with Lifetime plans", systemImage: "sparkle")
                        .font(.headline)
                }
                .modifier(GlassLifetimeButtonStyle())

                HStack {
                    Link("Terms of use", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        .foregroundColor(.primary)
                        .buttonStyle(.plain)

                    Text("and")
                        .foregroundStyle(.secondary)

                    Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
                        .foregroundColor(.primary)
                        .buttonStyle(.plain)
                }
                .font(.caption)
            }
            .padding(.vertical)
            .padding(.bottom, 24)
            .frame(maxWidth: .infinity)
        }
        .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
        .subscriptionStoreButtonLabel(.multiline)
        .backgroundStyle(.clear)
        .subscriptionStorePickerItemBackground(.thinMaterial)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .sheet(isPresented: $showingLifetimePlan) {
            PaywallLifetimeView()
                .presentationDetents(.init([.medium]))
        }
    }
}

#Preview {
    PaywallView()
        .environment(Store())
}
