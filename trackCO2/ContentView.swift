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
    @State var store = Store()
    
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    
    var body: some View {
        NavigationStack {
            if store.isLoading {
                ProgressView()
            } else if !hasCompletedOnboarding {
                OnboardingView(onFinish: {
                    hasCompletedOnboarding = true
                })
            } else if !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty {
                SummaryView()
            } else {
                PaywallView()
            }
        }
    }
}

#Preview {
    ContentView()
}
