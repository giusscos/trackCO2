//
//  OnboardingView.swift
//  trackCO2
//

import HealthKit
import StoreKit
import SwiftUI

struct OnboardingView: View {
    var body: some View {
        NavigationStack {
            OnboardingWelcomePage()
        }
    }
}

// MARK: - Appear Animation

private enum OnboardingAppearStyle {
    case icon
    case title
    case body
    case button
}

private struct OnboardingAppearAnimation: ViewModifier {
    let style: OnboardingAppearStyle
    @State private var appeared = false

    private var delay: Double {
        switch style {
        case .icon: return 0.05
        case .title: return 0.15
        case .body: return 0.28
        case .button: return 0.42
        }
    }

    func body(content: Content) -> some View {
        content
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : (style == .icon ? 0 : 20))
            .scaleEffect(appeared ? 1 : (style == .icon ? 0.55 : 1), anchor: .center)
            .onAppear {
                withAnimation(.spring(duration: 0.62, bounce: 0.28).delay(delay)) {
                    appeared = true
                }
            }
    }
}

private extension View {
    func onboardingAppear(_ style: OnboardingAppearStyle) -> some View {
        modifier(OnboardingAppearAnimation(style: style))
    }
}

// MARK: - Shared Layout

private struct OnboardingPageLayout<Destination: View, Secondary: View>: View {
    let symbol: String
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    let buttonTitle: LocalizedStringKey
    @ViewBuilder let destination: () -> Destination
    @ViewBuilder let secondaryButton: () -> Secondary

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: symbol)
                .font(.system(size: 90))
                .foregroundStyle(.tint)
                .onboardingAppear(.icon)

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .onboardingAppear(.title)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .onboardingAppear(.body)

            Spacer()

            NavigationLink(destination: destination()) {
                Text(buttonTitle)
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .onboardingAppear(.button)

            secondaryButton()
                .onboardingAppear(.button)
        }
        .padding(.horizontal, 32)
        .multilineTextAlignment(.center)
        .navigationBarBackButtonHidden(true)
    }
}

// MARK: - Pages 1–3

private struct OnboardingWelcomePage: View {
    var body: some View {
        OnboardingPageLayout(
            symbol: "leaf.circle.fill",
            title: "Welcome to trackCO2!",
            description: "Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!",
            buttonTitle: "Get Started",
            destination: { OnboardingActivitiesPage() },
            secondaryButton: { EmptyView() }
        )
    }
}

private struct OnboardingActivitiesPage: View {
    var body: some View {
        OnboardingPageLayout(
            symbol: "plus.circle.fill",
            title: "Track Your Activities",
            description: "Log your daily activities — driving, flying, food, energy — and see your real CO₂ footprint build up over time.",
            buttonTitle: "Next",
            destination: { OnboardingTripsPage() },
            secondaryButton: { EmptyView() }
        )
    }
}

private struct OnboardingTripsPage: View {
    var body: some View {
        OnboardingPageLayout(
            symbol: "map.fill",
            title: "Plan Greener Trips",
            description: "Use the map to compare transport options side by side. The greenest route is always shown first.",
            buttonTitle: "Next",
            destination: { OnboardingHealthKitPage() },
            secondaryButton: { EmptyView() }
        )
    }
}

// MARK: - Page 4 — HealthKit

private func isHealthDataDenied() -> Bool {
    guard HKHealthStore.isHealthDataAvailable() else { return true }
    let healthStore = HKHealthStore()
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let distanceType = HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    return healthStore.authorizationStatus(for: stepType) == .sharingDenied
        || healthStore.authorizationStatus(for: distanceType) == .sharingDenied
}

private func probeHealthKitReadAccess(completion: @escaping (Bool) -> Void) {
    guard HKHealthStore.isHealthDataAvailable(), !isHealthDataDenied() else {
        completion(false)
        return
    }

    let healthStore = HKHealthStore()
    let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
    let calendar = Calendar.current
    let start = calendar.startOfDay(for: Date())
    guard let end = calendar.date(byAdding: .day, value: 1, to: start) else {
        completion(false)
        return
    }

    let predicate = HKQuery.predicateForSamples(withStart: start, end: end, options: .strictStartDate)
    let query = HKStatisticsQuery(
        quantityType: stepType,
        quantitySamplePredicate: predicate,
        options: .cumulativeSum
    ) { _, _, error in
        DispatchQueue.main.async {
            if let error = error as? HKError {
                completion(error.code != .errorAuthorizationDenied && error.code != .errorAuthorizationNotDetermined)
            } else {
                completion(error == nil)
            }
        }
    }
    healthStore.execute(query)
}

private struct OnboardingHealthKitPage: View {
    @State private var navigateToPaywall = false

    var body: some View {
        VStack {
            Spacer()

            Image(systemName: "heart.fill")
                .font(.system(size: 90))
                .foregroundStyle(.tint)
                .onboardingAppear(.icon)

            Text("Sync Your Steps")
                .font(.largeTitle)
                .fontWeight(.bold)
                .onboardingAppear(.title)

            Text("trackCO2 can read your step count and walking distance from Apple Health to automatically log eco-friendly movement.")
                .font(.body)
                .foregroundStyle(.secondary)
                .onboardingAppear(.body)

            Spacer()

            Button {
                requestHealthAccessAndProceed()
            } label: {
                Text("Allow Health Access")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.tint)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .onboardingAppear(.button)

            Button(String(localized: "Skip")) {
                navigateToPaywall = true
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)
            .padding(.top, 8)
            .onboardingAppear(.button)
        }
        .padding(.horizontal, 32)
        .multilineTextAlignment(.center)
        .navigationBarBackButtonHidden(true)
        .navigationDestination(isPresented: $navigateToPaywall) {
            OnboardingPaywallPage()
        }
    }

    private func requestHealthAccessAndProceed() {
        probeHealthKitReadAccess { isAuthorized in
            if isAuthorized {
                navigateToPaywall = true
                return
            }
            guard !isHealthDataDenied() else { return }

            HealthKitManager.shared.requestAuthorization { _ in
                probeHealthKitReadAccess { granted in
                    guard granted else { return }
                    navigateToPaywall = true
                }
            }
        }
    }
}

// MARK: - Page 5 — Paywall

private struct OnboardingPaywallPage: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var storeKit = Store()
    @State private var showLifetime = false
    @State private var footerAppeared = false

    private var hasPaid: Bool {
        !storeKit.purchasedSubscriptions.isEmpty || !storeKit.purchasedProducts.isEmpty
    }

    var body: some View {
        SubscriptionStoreView(groupID: storeKit.groupId) {
            VStack {
                Button {
                    showLifetime = true
                } label: {
                    Label("Save with Lifetime plans", systemImage: "sparkle")
                        .font(.headline)
                }
                .tint(.purple)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

                Button(String(localized: "Maybe Later")) {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            .frame(minHeight: 300)
            .opacity(footerAppeared ? 1 : 0)
            .offset(y: footerAppeared ? 0 : 24)
        }
        .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .tint(.primary)
        .sheet(isPresented: $showLifetime) {
            PaywallLifetimeView()
                .presentationDetents([.medium])
        }
        .navigationBarBackButtonHidden(true)
        .onAppear {
            withAnimation(.spring(duration: 0.62, bounce: 0.28).delay(0.12)) {
                footerAppeared = true
            }
        }
        .onChange(of: hasPaid) { _, paid in
            guard paid else { return }
            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    OnboardingView()
}
