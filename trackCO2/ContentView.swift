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
    @Environment(Store.self) private var store
    @State private var showWhatsNew = false

    private var currentVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }

    var body: some View {
        if store.isLoading {
            ProgressView()
        } else if !hasCompletedOnboarding {
            OnboardingView()
                .environment(store)
                .onChange(of: store.hasPaid) { _, paid in
                    guard paid else { return }
                    hasCompletedOnboarding = true
                }
                .subscriptionStatusTask(for: store.groupId) { status in
                    guard hasActiveSubscription(status) else { return }
                    hasCompletedOnboarding = true
                }
        } else {
            TabView {
                SummaryView()
                    .tabItem {
                        Label("Home", systemImage: "house.fill")
                    }

                TripsView()
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

    private func checkWhatsNew() {
        guard hasCompletedOnboarding else { return }
        guard lastSeenVersion != currentVersion else { return }
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
