//
//  ListAllActivityEventView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 03/07/25.
//

import SwiftData
import SwiftUI

struct ListAllActivityEventView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query var events: [ActivityEvent]
    
    var body: some View {
        List {
            ForEach(events) { event in
                HStack {
                    if let activity = event.activity {
                        Text(activity.type.emoji)
                        
                        VStack(alignment: .leading) {
                            Text(activity.name).font(.headline)
                            
                            Text("\(event.quantity, specifier: "%.2f") \(activity.quantityUnit.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            
                            Text("\(event.quantity * activity.co2Emission, specifier: "%.2f") \(activity.emissionUnit.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(activity.type.isCO2Reducing ? .green : activity.co2Emission > 0 ? .red : .blue)
                        }
                    }
                }
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        deleteEvent(event)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .navigationTitle("All Events")
    }
    
    func deleteEvent(_ event: ActivityEvent) {
         modelContext.delete(event)
    }
}

#Preview {
    ListAllActivityEventView()
}
