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
            NavigationLink {
                ListCompensationView()
            } label: {
                HStack {
                    Text("Compensation")
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .lineLimit(1)

                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 6) {
                Image(systemName: "leaf.fill")
                    .font(.title3)
                    .foregroundStyle(.green)
                (
                    Text("\(calculateCO2Totals(activities: activities).compensation, specifier: "%.2f")")
                        .font(.title)
                        .fontWeight(.bold)
                    +
                    Text("kg")
                        .font(.caption)
                        .fontWeight(.medium)
                )
            }
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    CompensationView()
}
