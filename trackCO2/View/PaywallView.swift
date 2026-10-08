//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    /// The locked feature that opened the paywall; it leads the header and the feature grid.
    var highlighted: PremiumFeature? = nil
    var onPurchaseComplete: (() -> Void)? = nil
    /// When set, the paywall can be dismissed without purchasing.
    var onClose: (() -> Void)? = nil

    @Environment(Store.self) private var store

    @State private var selectedProductID = Store.yearlyID
    @State private var didUnlock = false
    @State private var trialEligibleIDs: Set<String> = []
    @State private var isPurchasing = false
    @State private var isRestoring = false
    @State private var message: String? = nil
    @State private var showingFamilyLifetime = false
    @State private var headerAppeared = false

    private let happyHealth = ClaudHealth(score: 0.95)

    private var orderedFeatures: [PremiumFeature] {
        guard let first = highlighted else { return PremiumFeature.allCases }
        return [first] + PremiumFeature.allCases.filter { $0 != first }
    }

    private var products: [Product] { store.paywallProducts }

    private var selectedProduct: Product? {
        products.first { $0.id == selectedProductID } ?? products.first
    }

    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()

            if didUnlock {
                ClaudPlusWelcomeView {
                    onPurchaseComplete?()
                }
                .transition(.opacity.combined(with: .scale(scale: 0.96)))
            } else {
                paywallContent
                    .transition(.opacity)
            }
        }
        .onAppear {
            if store.hasPaid { onPurchaseComplete?() }
        }
        .onChange(of: store.hasPaid) { _, paid in
            guard paid else { return }
            withAnimation(.spring(duration: 0.5, bounce: 0.2)) { didUnlock = true }
        }
        .task(id: products.map(\.id)) { await loadTrialEligibility() }
        .sheet(isPresented: $showingFamilyLifetime) {
            PaywallLifetimeView()
                .presentationDetents([.medium])
        }
    }

    private func hasEligibleTrial(_ product: Product) -> Bool {
        product.freeTrialPeriod != nil && trialEligibleIDs.contains(product.id)
    }

    private func loadTrialEligibility() async {
        var eligible: Set<String> = []
        for product in products where product.freeTrialPeriod != nil {
            if await product.subscription?.isEligibleForIntroOffer == true {
                eligible.insert(product.id)
            }
        }
        trialEligibleIDs = eligible
    }

    private var paywallContent: some View {
        ZStack(alignment: .topLeading) {
            Circle()
                .fill((highlighted?.accent ?? .green).opacity(0.16))
                .frame(width: 340, height: 340)
                .blur(radius: 80)
                .offset(y: -190)
                .frame(maxWidth: .infinity)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    header
                    featureGrid
                    pricingSection
                    footer
                }
            }
            // Pinned so the purchase button is always visible without scrolling.
            .safeAreaInset(edge: .bottom, spacing: 0) {
                ctaSection
                    .padding(.top, 20)
                    .padding(.bottom, 8)
                    .background(
                        LinearGradient(
                            colors: [Color(.systemBackground).opacity(0), Color(.systemBackground)],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }

            if let onClose {
                Button(action: onClose) {
                    Image(systemName: "xmark")
                        .font(.subheadline.weight(.bold))
                        .foregroundStyle(.secondary)
                        .frame(width: 32, height: 32)
                        .background(.ultraThinMaterial, in: Circle())
                }
                .accessibilityLabel(Text("Not now"))
                .padding(.leading, 20)
                .padding(.top, 8)
            }
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            HStack(alignment: .bottom, spacing: 0) {
                ErtEarthView(baseEyeOpenness: 1, isHungry: false)
                    .scaleEffect(0.62)
                    .frame(width: 70, height: 70)
                    .offset(x: 10)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 16)

                ClaudCloudView(
                    color: happyHealth.cloudBodyColor,
                    baseEyeOpenness: happyHealth.baseEyeOpenness,
                    isHungry: false
                )
                .scaleEffect(headerAppeared ? 1 : 0.55)
                .frame(width: 124, height: 100)
                .zIndex(1)

                TriTreeView(baseEyeOpenness: 1, isHungry: false)
                    .scaleEffect(0.62)
                    .frame(width: 66, height: 76)
                    .offset(x: -10)
                    .opacity(headerAppeared ? 1 : 0)
                    .offset(y: headerAppeared ? 0 : 16)
            }
            .padding(.top, 36)
            .padding(.bottom, 2)
            .onAppear {
                withAnimation(.spring(duration: 0.62, bounce: 0.3).delay(0.05)) { headerAppeared = true }
            }

            Text("Claud+")
                .font(.caption.weight(.bold))
                .textCase(.uppercase)
                .foregroundStyle(.secondary)

            Text(highlighted?.headline ?? "paywall.title")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .multilineTextAlignment(.center)

            Text(highlighted?.message ?? "paywall.subtitle")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.horizontal, 32)
        }
        .padding(.bottom, 18)
    }

    // MARK: - Features

    // Two-column grid keeps the features and the plans close to the fold on most phones.
    private var featureGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
            ForEach(orderedFeatures) { feature in
                let isHighlighted = feature == highlighted
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 8) {
                        Image(systemName: feature.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(feature.accent.gradient)
                            .frame(width: 28, height: 28)
                            .background(feature.accent.opacity(0.15), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                        Text(feature.paywallTitle)
                            .font(.subheadline.weight(.semibold))
                            .lineLimit(1)
                            .minimumScaleFactor(0.75)
                    }
                    Text(feature.paywallSubtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2, reservesSpace: true)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(10)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
                .overlay {
                    if isHighlighted {
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(feature.accent.opacity(0.6), lineWidth: 1.5)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 20)
    }

    // MARK: - Pricing

    @ViewBuilder
    private var pricingSection: some View {
        if products.isEmpty {
            placeholderPricing
        } else {
            VStack(spacing: 10) {
                ForEach(products) { product in
                    productCard(product)
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private func productCard(_ product: Product) -> some View {
        let isSelected = selectedProductID == product.id
        let isYearly = product.id == Store.yearlyID

        return Button {
            withAnimation(.spring(duration: 0.2, bounce: 0.1)) {
                selectedProductID = product.id
            }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(planName(for: product))
                            .font(.headline)
                        if hasEligibleTrial(product), let trial = product.freeTrialText {
                            badge(String(format: String(localized: "paywall.badge.trial"), trial).uppercased())
                        } else if isYearly {
                            badge(String(localized: "paywall.badge.bestValue"))
                        }
                    }
                    Text(planSubtitle(for: product))
                        .font(.caption)
                        .foregroundStyle(isYearly && savingsPercent(for: product) != nil ? Color.green : Color.secondary)
                }

                Spacer()

                Text(product.displayPrice)
                    .font(.headline)

                ZStack {
                    Circle()
                        .strokeBorder(isSelected ? Color.primary : Color.secondary.opacity(0.4), lineWidth: 1.5)
                        .frame(width: 22, height: 22)
                    if isSelected {
                        Circle()
                            .fill(Color.primary)
                            .frame(width: 12, height: 12)
                    }
                }
            }
            .padding(14)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .strokeBorder(isSelected ? Color.primary : .clear, lineWidth: 1.5)
            }
            .contentShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        }
        .buttonStyle(.plain)
        .sensoryFeedback(.selection, trigger: selectedProductID)
    }

    private func badge(_ text: String) -> some View {
        Text(verbatim: text)
            .font(.system(size: 10, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(Color.green, in: Capsule())
    }

    private func planName(for product: Product) -> String {
        switch product.id {
        case Store.yearlyID: return String(localized: "paywall.plan.yearly")
        case Store.monthlyID: return String(localized: "paywall.plan.monthly")
        case Store.lifetimeID: return String(localized: "paywall.plan.lifetime")
        default: return product.displayName
        }
    }

    /// Yearly vs. twelve monthly payments, rounded down so we never overstate the saving.
    private func savingsPercent(for yearly: Product) -> Int? {
        guard yearly.id == Store.yearlyID,
              let monthly = products.first(where: { $0.id == Store.monthlyID }) else { return nil }
        let fullYear = NSDecimalNumber(decimal: monthly.price * 12).doubleValue
        let yearlyPrice = NSDecimalNumber(decimal: yearly.price).doubleValue
        guard fullYear > 0, yearlyPrice < fullYear else { return nil }
        let percent = Int(((fullYear - yearlyPrice) / fullYear * 100).rounded(.down))
        return percent > 0 ? percent : nil
    }

    private func planSubtitle(for product: Product) -> String {
        switch product.id {
        case Store.yearlyID:
            if let percent = savingsPercent(for: product) {
                return String(format: String(localized: "paywall.plan.yearly.savings"), product.monthlyEquivalentText, percent)
            }
            return String(localized: "paywall.plan.billedYearly")
        case Store.monthlyID:
            return String(localized: "paywall.plan.billedMonthly")
        default:
            return String(localized: "paywall.plan.oneTime")
        }
    }

    private var placeholderPricing: some View {
        VStack(spacing: 10) {
            ForEach(["paywall.plan.monthly", "paywall.plan.yearly", "paywall.plan.lifetime"], id: \.self) { key in
                HStack {
                    Text(LocalizedStringKey(key))
                        .font(.headline)
                    Spacer()
                    Text(verbatim: "–")
                }
                .padding(14)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
            }
        }
        .padding(.horizontal, 20)
        .redacted(reason: .placeholder)
    }

    // MARK: - CTA

    private var ctaTitle: String {
        if let product = selectedProduct, hasEligibleTrial(product), let trial = product.freeTrialText {
            return String(format: String(localized: "paywall.cta.trial"), trial)
        }
        return String(localized: "paywall.cta.unlock")
    }

    /// What the user will be charged, shown right under the button (required for free trials).
    private var ctaDisclosure: String? {
        guard let product = selectedProduct else { return nil }
        if product.subscription == nil {
            return String(localized: "paywall.disclosure.lifetime")
        }
        if hasEligibleTrial(product), let trial = product.freeTrialText {
            return String(format: String(localized: "paywall.disclosure.trial"), trial, product.pricePerPeriodText)
        }
        return String(format: String(localized: "paywall.disclosure.subscription"), product.pricePerPeriodText)
    }

    private var ctaSection: some View {
        VStack(spacing: 8) {
            Button {
                guard let product = selectedProduct else { return }
                Task { await purchase(product) }
            } label: {
                ZStack {
                    if isPurchasing {
                        ProgressView()
                            .tint(Color(.systemBackground))
                    } else {
                        Text(verbatim: ctaTitle)
                            .font(.headline)
                            .contentTransition(.opacity)
                    }
                }
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.accentColor, in: Capsule())
            }
            .disabled(isPurchasing || products.isEmpty)
            .animation(.easeInOut(duration: 0.2), value: ctaTitle)

            if let ctaDisclosure {
                Text(verbatim: ctaDisclosure)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .contentTransition(.opacity)
                    .animation(.easeInOut(duration: 0.2), value: ctaDisclosure)
            }
        }
        .padding(.horizontal, 20)
    }

    private func purchase(_ product: Product) async {
        isPurchasing = true
        message = nil
        defer { isPurchasing = false }
        do {
            if let transaction = try await store.purchase(product) {
                store.recordEntitlement(for: transaction)
            }
        } catch {
            message = String(localized: "paywall.error.purchase")
        }
    }

    private func restore() async {
        isRestoring = true
        message = nil
        defer { isRestoring = false }
        if !(await store.restorePurchases()) {
            message = String(localized: "paywall.restore.none")
        }
    }

    // MARK: - Footer

    private var footer: some View {
        VStack(spacing: 12) {
            if let message {
                Text(verbatim: message)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            Button {
                Task { await restore() }
            } label: {
                if isRestoring {
                    ProgressView()
                } else {
                    Text("paywall.restore")
                        .font(.subheadline.weight(.medium))
                        .foregroundStyle(.secondary)
                }
            }
            .disabled(isRestoring)

            Button {
                showingFamilyLifetime = true
            } label: {
                Label("paywall.familyLifetime", systemImage: "person.2.fill")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            if let onClose {
                Button(action: onClose) {
                    Text("paywall.continueFree")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .underline()
                }
            }

            Text("paywall.autoRenew")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)

            HStack(spacing: 16) {
                if let terms = URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/") {
                    Link("Terms of use", destination: terms)
                }
                Text(verbatim: "·")
                if let privacy = URL(string: "https://giusscos.com/work/claud/privacy/") {
                    Link("Privacy Policy", destination: privacy)
                }
            }
            .font(.caption2)
            .foregroundStyle(.tertiary)
        }
        .padding(.top, 20)
        .padding(.bottom, 16)
    }
}

// MARK: - Welcome to Claud+

private struct ClaudPlusWelcomeView: View {
    let onContinue: () -> Void

    @State private var appeared = false
    @State private var burst = false

    private let happyHealth = ClaudHealth(score: 1)
    private let confettiColors: [Color] = [.green, .mint, .blue, .yellow, .orange, .cyan]

    var body: some View {
        ZStack {
            Circle()
                .fill(Color.green.opacity(0.18))
                .frame(width: 360, height: 360)
                .blur(radius: 90)
                .offset(y: -120)

            confetti

            VStack(spacing: 0) {
                Spacer()

                ClaudCloudView(
                    color: happyHealth.cloudBodyColor,
                    baseEyeOpenness: happyHealth.baseEyeOpenness,
                    isHungry: false
                )
                .scaleEffect(appeared ? 1.6 : 0.6)
                .opacity(appeared ? 1 : 0)
                .padding(.bottom, 56)

                Text("paywall.welcome.title")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .multilineTextAlignment(.center)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 12)

                Text("paywall.welcome.message")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
                    .padding(.top, 12)
                    .opacity(appeared ? 1 : 0)

                Spacer()

                Button(action: onContinue) {
                    Text("paywall.welcome.cta")
                        .font(.headline)
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.accentColor, in: Capsule())
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 44)
                .opacity(appeared ? 1 : 0)
            }
        }
        .sensoryFeedback(.success, trigger: appeared)
        .onAppear {
            withAnimation(.spring(duration: 0.8, bounce: 0.35)) { appeared = true }
            withAnimation(.easeOut(duration: 1.6)) { burst = true }
        }
    }

    private var confetti: some View {
        ZStack {
            ForEach(0..<28, id: \.self) { i in
                let angle = Double(i) / 28.0 * 2 * .pi
                let distance: CGFloat = 150 + CGFloat((i * 37) % 90)
                Image(systemName: i.isMultiple(of: 3) ? "leaf.fill" : "circle.fill")
                    .font(.system(size: i.isMultiple(of: 3) ? 14 : 7))
                    .foregroundStyle(confettiColors[i % confettiColors.count])
                    .rotationEffect(.degrees(burst ? Double(i * 47) : 0))
                    .offset(
                        x: burst ? cos(angle) * distance : 0,
                        y: burst ? sin(angle) * distance + 80 : 0
                    )
                    .opacity(burst ? 0 : 1)
            }
        }
        .offset(y: -120)
        .allowsHitTesting(false)
    }
}

#Preview {
    PaywallView()
        .environment(Store())
}
