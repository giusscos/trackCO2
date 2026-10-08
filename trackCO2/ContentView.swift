//
//  ContentView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import SwiftData
import SwiftUI
import StoreKit

let defaultAppIcon = "claud"

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""
    @AppStorage("didSeedDefaultActivities") private var didSeedDefaultActivities = false
    @Environment(\.modelContext) private var modelContext
    @Environment(Store.self) private var store
    @State private var showWhatsNew = false
    @State private var didCheckExistingSubscription = false

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        if !hasCompletedOnboarding {
            // Shown right away; products keep loading in the background for the paywall at the end.
            OnboardingView()
                .environment(store)
                .onAppear(perform: seedDefaultActivitiesIfNeeded)
                // Reinstalling members skip onboarding. Purchases made inside it are handled by the paywall,
                // which shows its welcome screen first.
                .onChange(of: store.isLoading) { _, loading in
                    guard !loading, store.hasPaid else { return }
                    hasCompletedOnboarding = true
                }
                .subscriptionStatusTask(for: store.groupId) { status in
                    guard !didCheckExistingSubscription, status.value != nil else { return }
                    didCheckExistingSubscription = true
                    if hasActiveSubscription(status) { hasCompletedOnboarding = true }
                }
        } else if store.isLoading {
            ProgressView()
        } else {
            TabView {
                SummaryView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                PremiumGate(feature: .trips, presentation: .tab) {
                    TripsView()
                }
                    .tabItem {
                        Label("Trips", systemImage: "map.fill")
                    }

                ListActivityView()
                    .tabItem {
                        Label("Activities", systemImage: "list.bullet")
                    }
            }
            .onAppear {
                UITextField.appearance().clearButtonMode = .whileEditing
                seedDefaultActivitiesIfNeeded()
                checkWhatsNew()
            }
            .fullScreenCover(isPresented: $showWhatsNew, onDismiss: {
                lastSeenVersion = currentVersion
            }) {
                WhatsNewView()
            }
            .onChange(of: hasCompletedOnboarding) { _, completed in
                guard completed else { return }
                checkWhatsNew()
            }
        }
    }

    /// Gives new users a ready-to-log activity list instead of an empty Home.
    private func seedDefaultActivitiesIfNeeded() {
        guard !didSeedDefaultActivities else { return }
        didSeedDefaultActivities = true

        let existingCount = (try? modelContext.fetchCount(FetchDescriptor<Activity>())) ?? 0
        guard existingCount == 0 else { return }

        for template in defaultActivities {
            modelContext.insert(Activity(
                type: template.type,
                name: template.type.defaultNameKey,
                activityDescription: template.activityDescription,
                quantityUnit: template.quantityUnit,
                emissionUnit: template.emissionUnit,
                co2Emission: template.co2Emission
            ))
        }
    }

    private func checkWhatsNew() {
        guard hasCompletedOnboarding else { return }
        guard lastSeenVersion != currentVersion else { return }
        // Fresh installs just finished onboarding; only updating users need What's New.
        guard !lastSeenVersion.isEmpty else {
            lastSeenVersion = currentVersion
            return
        }
        showWhatsNew = true
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
}

#Preview {
    ContentView()
        .environment(Store())
}
