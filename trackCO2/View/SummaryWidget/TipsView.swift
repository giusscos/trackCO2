//
//  TipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftData
import SwiftUI

struct TipsView: View {
    @Query var activities: [Activity]
    
    var tipMessage: String {
        guard let mostUsed = findMostUsedActivity(activities: activities) else {
            return "Start tracking your activities to get personalized tips!"
        }
        if mostUsed.type.isCO2Reducing {
            return "Great job! Your most frequent activity is \(mostUsed.type.emoji) \(mostUsed.name.lowercased()). Keep it up! 🌱"
        } else {
            return "Try to reduce your \(mostUsed.type.emoji) \(mostUsed.name.lowercased()) activity."
        }
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            NavigationLink {
                ListTipsView()
            } label: {
                HStack {
                    Text("Tips")
                        .frame(maxWidth: .infinity, alignment: .leading)
                
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
