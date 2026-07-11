//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

private struct GlassLifetimeButtonStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.buttonStyle(.glass)
        } else {
            content
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
        }
    }
}

struct PaywallView: View {
    var embedsNavigationStack: Bool = true
    var onPurchaseComplete: (() -> Void)? = nil
    
    @State private var storeKit = Store()
    
    @State private var showingLifetimePlan = false
    
    private let paywallHealth = ClaudHealth(score: 0.85)
    
    private struct Benefit: Identifiable {
        let id = UUID()
        let icon: String
        let text: LocalizedStringKey
    }
    
    private let benefits: [Benefit] = [
        Benefit(icon: "chart.bar.fill", text: "Log daily activities and see your real CO₂ footprint grow over time."),
        Benefit(icon: "map.fill", text: "Compare transport options and always pick the greenest route."),
        Benefit(icon: "figure.walk", text: "Auto-sync steps and walking distance from Apple Health."),
        Benefit(icon: "lightbulb.fill", text: "Get weekly insights and tips to reduce your impact.")
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
        .onChange(of: storeKit.hasPaid) { _, paid in
            guard paid else { return }
            onPurchaseComplete?()
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

                    Text("Unlock trackCO2 Premium")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Understand your impact and make greener choices every day.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                VStack(alignment: .leading, spacing: 12) {
                    ForEach(benefits) { benefit in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: benefit.icon)
                                .font(.body)
                                .foregroundStyle(.tint)
                                .frame(width: 22, alignment: .center)
                                .padding(.top, 2)

                            Text(benefit.text)
                                .font(.subheadline)
                                .foregroundStyle(.primary)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

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
}
