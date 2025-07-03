//
//  CompensationView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftData
import SwiftUI

struct CompensationView: View {
    @Query var activities: [Activity] = []
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Compensation")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    ListCompensationView()
                } label: {
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            
            Text("\(calculateCO2Totals(activities: activities).compensation, specifier: "%.2f")")
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
    CompensationView()
}
