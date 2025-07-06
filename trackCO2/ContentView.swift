//
//  ContentView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import SwiftData
import SwiftUI

struct ContentView: View {
    @State var store = Store()
    
    var body: some View {
        NavigationStack {
            if store.isLoading {
                ProgressView()
            } else if !store.purchasedSubscriptions.isEmpty {
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
