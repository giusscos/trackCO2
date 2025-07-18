//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    @Environment(\.colorScheme) var colorScheme

    @State var storeKit = Store()
    
    @State private var showLifetimePlans: Bool = false
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    @State private var showOnboarding: Bool = false
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        showOnboarding = true
                    }) {
                        Label("Onboarding", systemImage: "chevron.backward")
                    }
                    .accessibilityLabel("Repeat Onboarding")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                SubscriptionStoreView(groupID: storeKit.groupId) {
                    VStack {
                        Image(colorScheme == .dark ? "paywall-dark" : "paywall-light")
                            .resizable()
                            .frame(minWidth: 150, maxWidth: 350, minHeight: 150, maxHeight: 350)
                            .aspectRatio(1/1, contentMode: .fit)
                        
                        Text("Track your carbon footprint")
                            .font(.title)
                            .fontWeight(.semibold)
                        
                        Text("Add your personal activities and see how much CO2 you're saving every day.")
                            .multilineTextAlignment(.center)
                            .font(.title3)
                            .foregroundColor(.secondary)
                        
                        
                    }
                }
                .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
                .subscriptionStoreButtonLabel(.multiline)
                .storeButton(.visible, for: .restorePurchases)
                .subscriptionStorePolicyDestination(url: URL(string: "https://giusscos.it/privacy")!, for: .privacyPolicy)
                .subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, for: .termsOfService)
                .tint(.primary)
                .interactiveDismissDisabled()
                
                Button {
                    showLifetimePlans = true
                } label: {
                    HStack (alignment: .center, spacing: 8) {
                        Text("Save with lifetime plans")
                        
                        Image(systemName: "chevron.right.circle.fill")
                    }
                    .font(.headline)
                }
                .foregroundStyle(.purple)
                .buttonStyle(.plain)
            }
            .sheet(isPresented: $showLifetimePlans) {
                PaywallLifetimeView()
                    .presentationDetents(.init([.medium]))
            }
            .sheet(isPresented: $showOnboarding) {
                OnboardingView(onFinish: {
                    hasCompletedOnboarding = true
                    showOnboarding = false
                })
                .interactiveDismissDisabled()
            }
        }
    }
}

#Preview {
    PaywallView()
}
