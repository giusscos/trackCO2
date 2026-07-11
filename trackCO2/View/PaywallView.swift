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

private struct PaywallBenefitRow: View {
    let icon: String
    let accent: Color
    let text: LocalizedStringKey
    let index: Int

    @State private var appeared = false
    @State private var iconBounce = false

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(accent.gradient.opacity(0.22))
                    .frame(width: 42, height: 42)

                Image(systemName: icon)
                    .font(.body.weight(.semibold))
                    .foregroundStyle(accent.gradient)
                    .symbolEffect(.bounce, value: iconBounce)
            }

            Text(text)
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 10)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(accent.opacity(0.09))
                .overlay {
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(accent.opacity(0.18), lineWidth: 1)
                }
        }
        .opacity(appeared ? 1 : 0)
        .offset(x: appeared ? 0 : -28)
        .scaleEffect(appeared ? 1 : 0.94, anchor: .leading)
        .onAppear {
            let delay = 0.18 + Double(index) * 0.11
            withAnimation(.spring(duration: 0.58, bounce: 0.34).delay(delay)) {
                appeared = true
            }
            Task {
                try? await Task.sleep(for: .seconds(delay + 0.22))
                iconBounce.toggle()
            }
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
        var id: String { icon }
        let icon: String
        let accent: Color
        let text: LocalizedStringKey
    }
    
    private let benefits: [Benefit] = [
        Benefit(icon: "chart.bar.fill", accent: .green, text: "Log daily activities and see your real CO₂ footprint grow over time."),
        Benefit(icon: "map.fill", accent: .blue, text: "Compare transport options and always pick the greenest route."),
        Benefit(icon: "figure.walk", accent: .mint, text: "Auto-sync steps and walking distance from Apple Health."),
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
}
