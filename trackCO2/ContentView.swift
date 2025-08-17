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
    @State var hasntPaid: Bool = false
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            SummaryView()
                .onAppear() {
                    if store.purchasedSubscriptions.isEmpty || store.purchasedProducts.isEmpty {
                        hasntPaid = true
                    }
                }
                .fullScreenCover(isPresented: $hasntPaid) {
                    PaywallView()
                }
        }
    }
}

#Preview {
    ContentView()
}
