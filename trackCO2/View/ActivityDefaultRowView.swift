//
//  ActivityDefaultRowView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityDefaultRowView: View {
    var predefined: PredefinedActivity
    
    var emoji: String
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text(emoji)
                
                Text(predefined.defaultName)
            }
            .font(.title)
            .fontWeight(.bold)
            
            Text("\(predefined.emissionFactor, specifier: "%.2f") \(predefined.emissionUnit.rawValue)/\(predefined.quantityUnit.rawValue)")
                .font(.headline)
                .foregroundStyle(predefined.type.isCO2Reducing ? .green : .red)
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    ActivityDefaultRowView(
        predefined: PredefinedActivity(type: .car, defaultName: "Car Travel", emissionFactor: 0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        emoji: "🚗")
}
