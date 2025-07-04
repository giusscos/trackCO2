//
//  TipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftUI
import SwiftData

struct TipsView: View {
    @Query var activities: [Activity]
    
    var tipMessage: String {
        guard let mostUsed = findMostUsedActivity(activities: activities) else {
            return "Start tracking your activities to get personalized tips!"
        }
        if mostUsed.type.isCO2Reducing {
            return "Great job! Your most frequent activity is CO2 reducing (\(mostUsed.type.emoji) \(mostUsed.name)). Keep it up! 🌱"
        } else {
            return "Try to balance your \(mostUsed.type.emoji) \(mostUsed.name.lowercased()) with more CO2 reducing activities like walking, biking, or recycling."
        }
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            HStack {
                Text("Tips")
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    // TODO: Navigate to all tips view
                } label: {
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            
            Text(tipMessage)
                .fontWeight(.bold)
                .lineLimit(3)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TipsView()
}
