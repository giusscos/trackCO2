//
//  ActivityRowView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftUI

struct ActivityRowView: View {
    var activity: Activity
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text(activity.type.emoji)
                
                Text(activity.name)
            }
            .font(.title)
            .fontWeight(.bold)
            
            Text("\(activity.co2Emission, specifier: "%.2f") \(activity.emissionUnit.rawValue)/\(activity.quantityUnit.rawValue)")
                .font(.headline)
                .foregroundStyle(activity.type.isCO2Reducing ? .green : activity.co2Emission > 0 ? .red : .blue)
        }
        .padding(.vertical, 8)
        
    }
}

#Preview {
    ActivityRowView(
        activity: Activity(name: "Car")
    )
}
