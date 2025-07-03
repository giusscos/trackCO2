//
//  ListConsumptionView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 03/07/25.
//

import SwiftUI
import SwiftData

struct ListConsumptionView: View {
    @Environment(\.modelContext) var modelContext
    @Query var events: [ActivityEvent]
    
    var compensationEvents: [ActivityEvent] {
        events.filter { $0.activity?.type.isCO2Reducing == false }
    }
    
    func deleteEvent(_ event: ActivityEvent) {
        DispatchQueue.main.async {
            if let realEvent = events.first(where: { $0.id == event.id }) {
                modelContext.delete(realEvent)
            }
        }
    }
    
    var body: some View {
        List {
            ForEach(compensationEvents, id: \.id) { event in
                HStack {
                    if let activity = event.activity {
                        Text(activity.type.emoji)
                        VStack(alignment: .leading) {
                            Text(activity.name)
                                .font(.headline)
                            Text("\(event.quantity, specifier: "%.2f") \(activity.quantityUnit.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                            Text("\(event.quantity * activity.co2Emission, specifier: "%.2f") \(activity.emissionUnit.rawValue)")
                                .font(.subheadline)
                                .fontWeight(.medium)
                                .foregroundStyle(.red)
                        }
                    } else {
                        Text("Unknown Activity")
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
        .navigationTitle("Consumption Events")
    }
}

#Preview {
    ListConsumptionView()
}
