//
//  ListMostUsedView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 03/07/25.
//

import SwiftUI
import SwiftData

struct ListMostUsedView: View {
    @Environment(\.modelContext) var modelContext
    @Query var activities: [Activity]
    
    var sortedActivities: [Activity] {
        activities.sorted { ($0.events?.count ?? 0) > ($1.events?.count ?? 0) }
    }
    
    func deleteActivity(_ activity: Activity) {
        DispatchQueue.main.async {
            if let realActivity = activities.first(where: { $0.id == activity.id }) {
                modelContext.delete(realActivity)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(sortedActivities, id: \.id) { activity in
                HStack {
                    Text(activity.type.emoji)
                    VStack(alignment: .leading) {
                        Text(activity.name)
                            .font(.headline)
                        Text("Events: \(activity.events?.count ?? 0)")
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
}

#Preview {
    ListMostUsedView()
}
