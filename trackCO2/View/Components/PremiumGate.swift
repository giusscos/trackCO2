//
//  PremiumGate.swift
//  trackCO2
//

import SwiftUI

enum PremiumFeature: String, CaseIterable, Identifiable {
    case trips
    case tips
    case trends
    case weatherForecast
    case calendar
    case customActivities
    case appIcons
    case customizeHome

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .trips: return "map.fill"
        case .tips: return "lightbulb.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .weatherForecast: return "cloud.sun.fill"
        case .calendar: return "calendar"
        case .customActivities: return "plus.circle.fill"
        case .appIcons: return "app.badge.fill"
        case .customizeHome: return "arrow.up.arrow.down"
        }
    }

    var accent: Color {
        switch self {
        case .trips: return .blue
        case .tips: return .yellow
        case .trends: return .purple
        case .weatherForecast: return .cyan
        case .calendar: return .green
        case .customActivities: return .mint
        case .appIcons: return .orange
        case .customizeHome: return .indigo
        }
    }

    /// Short name for the paywall feature grid.
    var paywallTitle: LocalizedStringKey {
        switch self {
        case .trips: return "paywall.feature.trips"
        case .tips: return "paywall.feature.tips"
        case .trends: return "paywall.feature.trends"
        case .weatherForecast: return "paywall.feature.weather"
        case .calendar: return "paywall.feature.calendar"
        case .customActivities: return "paywall.feature.customActivities"
        case .appIcons: return "paywall.feature.appIcons"
        case .customizeHome: return "paywall.feature.customizeHome"
        }
    }

    var paywallSubtitle: LocalizedStringKey {
        switch self {
        case .trips: return "paywall.feature.trips.detail"
        case .tips: return "paywall.feature.tips.detail"
        case .trends: return "paywall.feature.trends.detail"
        case .weatherForecast: return "paywall.feature.weather.detail"
        case .calendar: return "paywall.feature.calendar.detail"
        case .customActivities: return "paywall.feature.customActivities.detail"
        case .appIcons: return "paywall.feature.appIcons.detail"
        case .customizeHome: return "paywall.feature.customizeHome.detail"
        }
    }

    var navigationTitle: LocalizedStringKey {
        switch self {
        case .trips: return "Trips"
        case .tips: return "Activity Tips"
        case .trends: return "Trends"
        case .weatherForecast: return "Weather Forecast"
        case .calendar: return "Activity Calendar"
        case .customActivities: return "Create Activity"
        case .appIcons: return "Select Icon"
        case .customizeHome: return "Customize Home"
        }
    }

    var headline: LocalizedStringKey {
        switch self {
        case .trips: return "premium.trips.title"
        case .tips: return "premium.tips.title"
        case .trends: return "premium.trends.title"
        case .weatherForecast: return "premium.weather.title"
        case .calendar: return "premium.calendar.title"
        case .customActivities: return "premium.customActivities.title"
        case .appIcons: return "premium.appIcons.title"
        case .customizeHome: return "premium.customizeHome.title"
        }
    }

    var message: LocalizedStringKey {
        switch self {
        case .trips: return "premium.trips.message"
        case .tips: return "premium.tips.message"
        case .trends: return "premium.trends.message"
        case .weatherForecast: return "premium.weather.message"
        case .calendar: return "premium.calendar.message"
        case .customActivities: return "premium.customActivities.message"
        case .appIcons: return "premium.appIcons.message"
        case .customizeHome: return "premium.customizeHome.message"
        }
    }
}

/// Shows `content` to Claud+ members and an upsell screen to everyone else.
struct PremiumGate<Content: View>: View {
    enum Presentation {
        /// Pushed inside an existing NavigationStack.
        case push
        /// Root of a sheet: wraps in a NavigationStack with a close button.
        case modal
        /// Root of a tab: wraps in a NavigationStack without a close button.
        case tab
    }

    let feature: PremiumFeature
    var presentation: Presentation = .push
    @ViewBuilder let content: () -> Content

    @Environment(Store.self) private var store

    var body: some View {
        if store.hasPaid {
            content()
        } else {
            switch presentation {
            case .push:
                PremiumLockedView(feature: feature, showsCloseButton: false)
            case .modal, .tab:
                NavigationStack {
                    PremiumLockedView(feature: feature, showsCloseButton: presentation == .modal)
                }
            }
        }
    }
}

struct PremiumLockedView: View {
    let feature: PremiumFeature
    var showsCloseButton: Bool = false

    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                ZStack(alignment: .bottomTrailing) {
                    Circle()
                        .fill(feature.accent.gradient.opacity(0.18))
                        .frame(width: 120, height: 120)
                        .overlay {
                            Image(systemName: feature.icon)
                                .font(.system(size: 48, weight: .semibold))
                                .foregroundStyle(feature.accent.gradient)
                        }

                    Image(systemName: "lock.fill")
                        .font(.footnote.weight(.bold))
                        .foregroundStyle(.white)
                        .padding(8)
                        .background(Circle().fill(Color.accentColor))
                }
                .padding(.top, 32)

                VStack(spacing: 8) {
                    Text("Claud+")
                        .font(.caption.weight(.bold))
                        .textCase(.uppercase)
                        .foregroundStyle(.tint)

                    Text(feature.headline)
                        .font(.title2.weight(.bold))

                    Text(feature.message)
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                Button {
                    showPaywall = true
                } label: {
                    Text("premium.cta")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                }
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)
                .padding(.top, 8)

                Text("premium.footnote")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)
            .frame(maxWidth: .infinity)
        }
        .navigationTitle(feature.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if showsCloseButton {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Label("Close", systemImage: "xmark")
                    }
                }
            }
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                highlighted: feature,
                onPurchaseComplete: { showPaywall = false },
                onClose: { showPaywall = false }
            )
        }
    }
}

/// Small Home card inviting free users to try Claud+.
struct ClaudPlusBannerView: View {
    @State private var showPaywall = false

    var body: some View {
        Button {
            showPaywall = true
        } label: {
            HStack(spacing: 14) {
                Image(systemName: "sparkles")
                    .font(.title2.weight(.semibold))
                    .foregroundStyle(.tint)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(Color.accentColor.opacity(0.15)))

                VStack(alignment: .leading, spacing: 2) {
                    Text("premium.banner.title")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(.primary)
                    Text("premium.banner.message")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showPaywall) {
            PaywallView(
                onPurchaseComplete: { showPaywall = false },
                onClose: { showPaywall = false }
            )
        }
    }
}

#Preview {
    NavigationStack {
        PremiumLockedView(feature: .trips)
    }
    .environment(Store())
}
