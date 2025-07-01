//
//  ActivityDetailsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityDetailsView: View {
    var activity: Activity
    
    @State var emissionNumberSize: Double = 0

    var body: some View {
        VStack {
            Text(activity.type.emoji)
                .font(.largeTitle)
            
            Group {
                Text("\(activity.type.rawValue) (\(activity.type.quantityUnit))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            
            Text(activity.name)
                .font(.title)
                .fontWeight(.bold)
            
            
            Text(activity.activityDescription)
                .font(.headline)
            
            GeometryReader { reader in
                let size = reader.size

                HStack (alignment: .lastTextBaseline, spacing: 0) {
                        Text("\(activity.co2Emission, specifier: "%.1f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .onAppear() {
                                emissionNumberSize = size.width / 2
                            }
                        
                        Text("\(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
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
    ActivityDetailsView(
        activity: Activity(
            name: "Car",
            activityDescription: "My dayly car to go shopping, work and so on",
            co2Emission: 0.0
        )
    )
}
