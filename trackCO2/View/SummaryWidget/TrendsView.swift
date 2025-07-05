//
//  TrendsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 05/07/25.
//

import SwiftUI
import SwiftData

struct TrendsView: View {
    @Query var activities: [Activity] = []
    
    var topActivities: [Activity] {
        getTopActivitiesByWeeklyUsage(activities: activities, limit: 4)
    }
    
    var body: some View {
        VStack (alignment: .leading) {
            NavigationLink {
                ListTrendsView()
            } label: {
                HStack {
                    Text("Trends")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)
            
            if topActivities.isEmpty {
                VStack(alignment: .leading, spacing: 12) {
                    Text("No activity data yet")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    
                    Text("Start logging activities to see your weekly trends")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical)
            } else {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(Array(topActivities.enumerated()), id: \.element.id) { index, activity in
                        HStack {
                            Text(activity.type.emoji)
                                .font(.title)
                            
                            Text(activity.type.rawValue)
                                .font(.headline)
                                .lineLimit(1)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            Text("\(calculateWeeklyUsage(activity: activity), specifier: "%.0f")\(activity.quantityUnit.rawValue)/Week")
                                .font(.headline)
                                .foregroundStyle(activity.type.isCO2Reducing ? .green : .red)
                        }
                        
                        if index < topActivities.count - 1 {
                            Divider()
                        }
                    }
                }
                .padding(.vertical)
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    TrendsView()
}
