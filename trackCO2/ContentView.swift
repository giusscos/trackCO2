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
    
    @State var showPaywall: Bool = false
    
    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }
    
    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            SummaryView()
                .onAppear {
                    if hasPaid {
                        UITextField.appearance().clearButtonMode = .whileEditing
                        
                        return
                    }
                    
                    showPaywall = true
                }
                .fullScreenCover(isPresented: $showPaywall) {
                    PaywallView()
                }
                .onChange(of: hasPaid, { _, _ in
                    if !hasPaid { return }
                    
                    showPaywall = false
                })
        }
    }
}

#Preview {
    ContentView()
}
