//
//  ListMostUsedView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 03/07/25.
//

import SwiftData
import SwiftUI

struct ListMostUsedView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var activities: [Activity]
    
    var sortedActivities: [Activity] {
        activities.sorted { ($0.events?.count ?? 0) > ($1.events?.count ?? 0) }
    }   
    
    var body: some View {
        List {
            ForEach(sortedActivities, id: \.id) { activity in
                HStack {
                    Text(activity.type.emoji)
                    
                    VStack(alignment: .leading) {
                        Text(activity.name)
                            .font(.headline)
                        
                        Text("Used \(activity.events?.count ?? 0) \(activity.events?.count != 1 ? "times" : "time")")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteActivity(activity)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("Most Used Activities")
    }
    
    func deleteActivity(_ activity: Activity) {
        modelContext.delete(activity)
    }
}

#Preview {
    ListMostUsedView()
}
