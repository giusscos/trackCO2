//
//  ActivityDefaultDetailsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityDefaultDetailsView: View {
    var predefined: PredefinedActivity
    
    var emoji: String
    
    @State private var emissionNumberSize: Double = 0
    
    var body: some View {
        VStack {
            Text(emoji)
                .font(.largeTitle)
            
            Group {
                Text("\(predefined.type.rawValue)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(predefined.defaultName)
                .font(.title)
                .fontWeight(.bold)
            
                        
            GeometryReader { reader in
                let size = reader.size
                
                HStack (alignment: .lastTextBaseline, spacing: 0) {
                    Text("\(predefined.emissionFactor, specifier: "%.1f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .onAppear() {
                            emissionNumberSize = size.width / 2
                        }
                    
                    Text("\(predefined.emissionUnit.rawValue)/\(predefined.quantityUnit.rawValue)")
                        .font(.subheadline)
                        .fontWeight(.medium)
                }
                .offset(x: emissionNumberSize - 30, y: 0)
            }
        }
        .padding()
    }
}

#Preview {
    ActivityDefaultDetailsView(
        predefined: PredefinedActivity(type: .car, defaultName: "Car Travel", emissionFactor: 0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        emoji: "🚗"
    )
}
