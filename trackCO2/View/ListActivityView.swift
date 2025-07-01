//
//  ListActivityView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftData
import SwiftUI

enum ActiveListActivitySheet: Identifiable {
    case createActivity
    case editActivity(Activity)
    case detailActivity(Activity)
    case detailDefaultActivity(PredefinedActivity, String)
    
    var id: String {
        switch self {
        case .createActivity:
            return "createActivity"
        case .editActivity(let activity):
            return "editActivity-\(activity.id)"
        case .detailActivity(let activity):
            return "detailActivity-\(activity.id)"
        case .detailDefaultActivity(let predefined, _):
            return "detailDefaultActivity-\(predefined.type)"
        }
    }
}

struct ListActivityView: View {
    @Environment(\.modelContext) var modelContext
    
    @Query private var activities: [Activity]

    @State private var activeSheet: ActiveListActivitySheet?
    
    let predefinedActivities: [ActivityType: PredefinedActivity] = [
        // Vehicles
        .car: PredefinedActivity(type: .car, defaultName: "Car Travel", emissionFactor: 0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        .airplane: PredefinedActivity(type: .airplane, defaultName: "Airplane Flight", emissionFactor: 0.2, quantityUnit: .km, emissionUnit: .kgCO2e),
        .boat: PredefinedActivity(type: .boat, defaultName: "Boat Trip", emissionFactor: 0.1, quantityUnit: .km, emissionUnit: .kgCO2e),
        .motorcycle: PredefinedActivity(type: .motorcycle, defaultName: "Motorcycle Ride", emissionFactor: 0.1, quantityUnit: .km, emissionUnit: .kgCO2e),
        .bus: PredefinedActivity(type: .bus, defaultName: "Bus Travel", emissionFactor: 0.08, quantityUnit: .km, emissionUnit: .kgCO2e),
        .train: PredefinedActivity(type: .train, defaultName: "Train Travel", emissionFactor: 0.04, quantityUnit: .km, emissionUnit: .kgCO2e),
        
        // Foods
        .beef: PredefinedActivity(type: .beef, defaultName: "Beef Consumption", emissionFactor: 60.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
        .chicken: PredefinedActivity(type: .chicken, defaultName: "Chicken Consumption", emissionFactor: 6.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
        .vegetables: PredefinedActivity(type: .vegetables, defaultName: "Vegetable Consumption", emissionFactor: 1.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
        .rice: PredefinedActivity(type: .rice, defaultName: "Rice Consumption", emissionFactor: 4.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
        .dairy: PredefinedActivity(type: .dairy, defaultName: "Dairy Consumption", emissionFactor: 10.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
        
        // Energy
        .electricity: PredefinedActivity(type: .electricity, defaultName: "Electricity Usage", emissionFactor: 0.53, quantityUnit: .kWh, emissionUnit: .kgCO2e),
        
        // CO2 Reduction
        .walking: PredefinedActivity(type: .walking, defaultName: "Walking", emissionFactor: -0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        .biking: PredefinedActivity(type: .biking, defaultName: "Biking", emissionFactor: -0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
        .treePlanting: PredefinedActivity(type: .treePlanting, defaultName: "Tree Planting", emissionFactor: -20.0, quantityUnit: .tree, emissionUnit: .kgCO2e),
        .recycling: PredefinedActivity(type: .recycling, defaultName: "Recycling", emissionFactor: -0.5, quantityUnit: .kg, emissionUnit: .kgCO2e)
    ]

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(activities) { activity in
                        ActivityRowView(activity: activity)
                        .swipeActions {
                            Button(role: .destructive) {
                                modelContext.delete(activity)
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }
                            
                            Button {
                                activeSheet = .editActivity(activity)
                            } label: {
                                Label("Edit", systemImage: "pencil")
                            }
                            .tint(.blue)
                        }
                        .onTapGesture {
                            activeSheet = .detailActivity(activity)
                        }
                    }
                    
                    ForEach(ActivityType.allCases) { activityType in
                        let emoji = activityType.emoji
                        
                        if let predefined = predefinedActivities[activityType] {
                            ActivityDefaultRowView(predefined: predefined, emoji: emoji)
                                .onTapGesture {
                                    activeSheet = .detailDefaultActivity(predefined, emoji)
                                }
                        }
                    }
                }
            }
            .navigationTitle("Activities")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createActivity
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createActivity:
                    CreateActivityView()
                case .editActivity(let activity):
                    EditActivityView(activity: activity)
                case .detailActivity(let activity):
                    ActivityDetailsView(activity: activity)                        .presentationDetents([.medium])
                case .detailDefaultActivity(let predefined, let emoji):
                    ActivityDefaultDetailsView(predefined: predefined, emoji: emoji)
                        .presentationDetents([.medium])
                }
            }
        }
    }
}

#Preview {
    ListActivityView()
}
