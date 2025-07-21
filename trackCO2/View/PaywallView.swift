//
//  PaywallView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import StoreKit
import SwiftUI

struct PaywallView: View {
    enum ActiveSheet: Identifiable {
        case lifetimePlan
        case onboarding
        
        var id: String {
            switch self {
            case .lifetimePlan:
                return "lifetimePlan"
            case .onboarding:
                return "onboarding"
            }
        }
    }
    @Environment(\.colorScheme) var colorScheme

    @State var storeKit = Store()
    
    @State var activeSheet: ActiveSheet?
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true
    
    var body: some View {
        NavigationStack {
            VStack {
                HStack {
                    Button(action: {
                        activeSheet = .onboarding
                    }) {
                        Label("Onboarding", systemImage: "chevron.backward")
                    }
                    .accessibilityLabel("Repeat Onboarding")
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                SubscriptionStoreView(groupID: storeKit.groupId) {
                    VStack {
                        VStack {
                            Button {
                                activeSheet = .lifetimePlan
                            } label: {
                                Label("Save with Lifetime plans", systemImage: "sparkle")
                                    .font(.headline)
                            }
                            .tint(.purple)
                            .buttonStyle(.borderedProminent)
                            .buttonBorderShape(.capsule)
                            
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
                        .frame(maxHeight: .infinity, alignment: .center)
                            
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
                }
                .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
                .subscriptionStoreButtonLabel(.multiline)
                .storeButton(.visible, for: .restorePurchases)
                .tint(.primary)
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .onboarding:
                    OnboardingView(onFinish: {
                        hasCompletedOnboarding = true
                        activeSheet = nil
                    })
                    .interactiveDismissDisabled()
                case .lifetimePlan:
                    PaywallLifetimeView()
                        .presentationDetents(.init([.medium]))
                }
            }
        }
    }
}

#Preview {
    PaywallView()
}
