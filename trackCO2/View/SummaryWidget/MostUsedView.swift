//
//  MostUsedView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import SwiftData
import SwiftUI

struct MostUsedView: View {
    @Query var activities: [Activity]
    
    var mostUsed: Activity? {
        findMostUsedActivity(activities: activities)
    }
    
    var body: some View {
        if let mostUsed = mostUsed {
            VStack (alignment: .leading) {
                HStack {
                    Text("Most used")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    NavigationLink {
                        ListMostUsedView()
                    } label: {
                        Label("Navigate to", systemImage: "chevron.right")
                            .labelStyle(.iconOnly)
                    }
                }
                .font(.headline)
                .frame(maxHeight: .infinity, alignment: .top)
                
                Text("\(mostUsed.type.emoji) \(mostUsed.type.rawValue)")
                    .font(.title)
                    .fontWeight(.bold)
                    .lineLimit(1)
            }
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16))
        }
    }
}

#Preview {
    MostUsedView()
}
