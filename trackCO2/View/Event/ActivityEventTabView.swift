//
//  ActivityEventTabView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityEventTabView: View {
    var activity: Activity
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Pre-set activity")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(activity.type.emoji)
                    .font(.largeTitle)
                
                Text(activity.name)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            HStack (alignment: .lastTextBaseline, spacing: 2) {
                Text("\(activity.co2Emission, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .padding(.top, 8)
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    ActivityEventTabView(
        activity: Activity(name: "Car")
    )
}
