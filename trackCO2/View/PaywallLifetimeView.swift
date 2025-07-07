//
//  PaywallLifetimeView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 07/07/25.
//

import StoreKit
import SwiftUI

struct PaywallLifetimeView: View {
    @Environment(\.colorScheme) var colorScheme
    
    @State var storeKit = Store()
    
    var body: some View {
        StoreView(ids: storeKit.productLifetimeIds)
    }
}

#Preview {
    PaywallLifetimeView()
}
