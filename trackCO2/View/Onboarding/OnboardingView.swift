//
//  OnboardingView.swift
//  trackCO2
//

import HealthKit
import HealthKitUI
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

private struct OnboardingPageLayout<Header: View, Primary: View, Secondary: View>: View {
    let hidesBackButton: Bool
    let title: LocalizedStringKey
    let description: LocalizedStringKey
    @ViewBuilder let header: () -> Header
    @ViewBuilder let primaryButton: () -> Primary
    @ViewBuilder let secondaryButton: () -> Secondary

    var body: some View {
        VStack {
            Spacer()

            header()

            Text(title)
                .font(.largeTitle)
                .fontWeight(.bold)
                .onboardingAppear(.title)

            Text(description)
                .font(.body)
                .foregroundStyle(.secondary)
                .onboardingAppear(.body)

            Spacer()

            primaryButton()
                .onboardingAppear(.button)

            secondaryButton()
                .onboardingAppear(.button)
        }
        .padding(.horizontal, 32)
        .multilineTextAlignment(.center)
        .navigationBarBackButtonHidden(hidesBackButton)
    }
}

// MARK: - Pages 1–3

private struct OnboardingWelcomePage: View {
    private let welcomeHealth = ClaudHealth(score: 0.85)

    var body: some View {
        OnboardingPageLayout(
            hidesBackButton: false,
            title: "Welcome to trackCO2!",
            description: "Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!",
            header: {
                ClaudCloudView(
                    color: welcomeHealth.cloudBodyColor,
                    baseEyeOpenness: welcomeHealth.baseEyeOpenness,
                    isHungry: false
                )
                .scaleEffect(1.5)
                .padding(.vertical, 16)
                .onboardingAppear(.icon)
            },
            primaryButton: {
                NavigationLink(destination: OnboardingActivitiesPage()) {
                    Text("Get Started")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            },
            secondaryButton: { EmptyView() }
        )
    }
}

private struct OnboardingActivitiesPage: View {
    var body: some View {
        OnboardingPageLayout(
            hidesBackButton: true,
            title: "Track Your Activities",
            description: "Log your daily activities — driving, flying, food, energy — and see your real CO₂ footprint build up over time.",
            header: {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.tint)
                    .onboardingAppear(.icon)
            },
            primaryButton: {
                NavigationLink(destination: OnboardingTripsPage()) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            },
            secondaryButton: { EmptyView() }
        )
    }
}

private struct OnboardingTripsPage: View {
    var body: some View {
        OnboardingPageLayout(
            hidesBackButton: true,
            title: "Plan Greener Trips",
            description: "Use the map to compare transport options side by side. The greenest route is always shown first.",
            header: {
                Image(systemName: "map.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.tint)
                    .onboardingAppear(.icon)
            },
            primaryButton: {
                NavigationLink(destination: OnboardingHealthKitPage()) {
                    Text("Next")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
            },
            secondaryButton: { EmptyView() }
        )
    }
}

// MARK: - Page 4 — HealthKit

private struct OnboardingHealthKitPage: View {
    @State private var navigateToPaywall = false
    @State private var isHealthAccessGranted = false
    @State private var trigger = false

    private let healthStore = HKHealthStore()
    private let readTypes: Set<HKObjectType> = [
        HKQuantityType.quantityType(forIdentifier: .stepCount)!,
        HKQuantityType.quantityType(forIdentifier: .distanceWalkingRunning)!
    ]

    var body: some View {
        OnboardingPageLayout(
            hidesBackButton: true,
            title: "Sync Your Steps",
            description: "trackCO2 can read your step count and walking distance from Apple Health to automatically log eco-friendly movement.",
            header: {
                Image(systemName: "heart.fill")
                    .font(.system(size: 90))
                    .foregroundStyle(.tint)
                    .onboardingAppear(.icon)
            },
            primaryButton: {
                Button {
                    if isHealthAccessGranted {
                        navigateToPaywall = true
                    } else if HKHealthStore.isHealthDataAvailable() {
                        trigger.toggle()
                    } else {
                        navigateToPaywall = true
                    }
                } label: {
                    Text(isHealthAccessGranted ? "Continue" : "Allow Health Access")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.tint)
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .animation(.easeInOut(duration: 0.2), value: isHealthAccessGranted)
            },
            secondaryButton: {
                Button(String(localized: "Skip")) {
                    navigateToPaywall = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
        )
        .healthDataAccessRequest(store: healthStore, readTypes: readTypes, trigger: trigger) { result in
            DispatchQueue.main.async {
                if case .success(true) = result {
                    isHealthAccessGranted = true
                }
                navigateToPaywall = true
            }
        }
        .navigationDestination(isPresented: $navigateToPaywall) {
            OnboardingPaywallPage()
        }
        .onAppear {
            HealthKitManager.shared.probeHealthKitReadAccess { granted in
                isHealthAccessGranted = granted
            }
        }
    }
}

// MARK: - Page 5 — Paywall

private struct OnboardingPaywallPage: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    var body: some View {
        PaywallView(embedsNavigationStack: false) {
            hasCompletedOnboarding = true
        }
        .navigationBarBackButtonHidden(true)
    }
}

#Preview {
    OnboardingView()
}
