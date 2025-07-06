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

    var body: some View {
        SubscriptionStoreView(groupID: Store().groupId) {
            VStack {
                Image(colorScheme == .dark ? "paywall-dark" : "paywall-light")
                    .resizable()
                    .frame(minWidth: 100, maxWidth: 350, minHeight: 100, maxHeight: 350)
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
        .subscriptionStoreControlStyle(.automatic, placement: .automatic)
        .subscriptionStoreButtonLabel(.automatic)
        .storeButton(.visible, for: .restorePurchases)
        .subscriptionStorePolicyDestination(url: URL(string: "https://giusscos.it/privacy")!, for: .privacyPolicy)
        .subscriptionStorePolicyDestination(url: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!, for: .termsOfService)
        .tint(.primary)
        .interactiveDismissDisabled()
    }
}

#Preview {
    PaywallView()
}
