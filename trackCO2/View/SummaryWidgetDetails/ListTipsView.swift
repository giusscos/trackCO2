//
//  ListTipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 05/07/25.
//

import SwiftData
import SwiftUI

struct ListTipsView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var activities: [Activity]
    
    var sortedActivities: [Activity] {
        activities
            .filter { $0.events?.count ?? 0 >= 3 }
            .sorted { ($0.events?.count ?? 0) > ($1.events?.count ?? 0) }
    }
    
    func generateTip(for activity: Activity) -> String {
        if activity.type.isCO2Reducing {
            return "Great job! Your \(activity.name.lowercased()) activity is helping reduce CO2 emissions. Keep it up! 🌱"
        } else {
            return "Consider reducing your \(activity.name.lowercased()) usage or balancing it with CO2 reducing activities."
        }
    }
    
    var body: some View {
        List {
            if sortedActivities.isEmpty {
                Text("No activities found. Start tracking your activities to get personalized tips!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(sortedActivities, id: \.id) { activity in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text(activity.type.emoji)
                                .font(.title2)
                            
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                
//                                Text("Used \(activity.events?.count ?? 0) \(activity.events?.count != 1 ? "times" : "time")")
//                                    .font(.subheadline)
//                                    .foregroundStyle(.secondary)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                            if activity.type.isCO2Reducing {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }
                        
                        Text(generateTip(for: activity))
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Activity Tips")
    }
}

#Preview {
    ListTipsView()
}
