//
//  ContentView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import SwiftData
import SwiftUI

let defaultAppIcon = "claud"

struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State var store = Store()
    @State var showPaywall: Bool = false

    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    private var showOnboarding: Binding<Bool> {
        Binding(
            get: { !hasCompletedOnboarding },
            set: { if !$0 { hasCompletedOnboarding = true } }
        )
    }

    var body: some View {
        if store.isLoading {
            ProgressView()
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
                guard hasCompletedOnboarding else { return }
                UITextField.appearance().clearButtonMode = .whileEditing
                if !hasPaid { showPaywall = true }
            }
            .fullScreenCover(isPresented: showOnboarding) {
                OnboardingView()
            }
            .fullScreenCover(isPresented: $showPaywall) {
                PaywallView()
            }
            .onChange(of: hasCompletedOnboarding) { _, completed in
                guard completed, !hasPaid else { return }
                showPaywall = true
            }
            .onChange(of: hasPaid) { _, _ in
                if !hasPaid { return }
                showPaywall = false
            }
        }
    }
}

#Preview {
    ContentView()
}
