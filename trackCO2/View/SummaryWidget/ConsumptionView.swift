//
//  ConsumptionView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftData
import SwiftUI

struct ConsumptionView: View {
    @Query var activities: [Activity] = []
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Consumption")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    ListConsumptionView()
                } label: {
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            
            Text("\(calculateCO2Totals(activities: activities).consumption, specifier: "%.2f")")
                .font(.title)
                .fontWeight(.bold)
            +
            Text("kg")
                .font(.caption)
                .fontWeight(.medium)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    ConsumptionView()
}
