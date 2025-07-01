//
//  DefaultActivityEventTabView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct DefaultActivityEventTabView: View {
    var predefined: PredefinedActivity
    
    var emoji: String
    
    var body: some View {
        VStack (alignment: .leading) {
            Text("Pre-set activity")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            HStack {
                Text(emoji)
                    .font(.largeTitle)
                
                Text(predefined.defaultName)
                    .font(.title)
                    .fontWeight(.bold)
            }
            
            HStack (alignment: .lastTextBaseline, spacing: 2) {
                Text("\(predefined.emissionFactor, specifier: "%.2f")")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("\(predefined.emissionUnit.rawValue)/\(predefined.quantityUnit.rawValue)")
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
    DefaultActivityEventTabView(
        predefined: PredefinedActivity(type: .car, defaultName: "Car Travel", emissionFactor: 0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        emoji: "🚗"
    )
}
