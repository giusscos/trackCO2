//
//  ListActivityEventView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftData
import SwiftUI

struct ListActivityEventView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    @Query var activities: [Activity]
    
    @State private var co2EmissionsToAdd: Double = 0.0
    @State private var quantityUnitFromActivity: Double = 0.0 // km, kg, ecc
    
    @State private var selectedTab: String?
    @State private var selectedActivity: Activity?
    
    var body: some View {
        VStack {
            VStack (alignment: .leading) {
                Text("Add Event")
                    .font(.title)
                    .fontWeight(.bold)
                
                Text("Select an activity and insert the amount")
                    .font(.headline)
                    .foregroundStyle(.secondary)
            }
            .padding()
            .frame(maxWidth: .infinity, alignment: .topLeading)
            
            TabView (selection: $selectedTab) {
                ForEach(activities) { activity in
                    ActivityEventTabView(activity: activity, currentCO2Emission: co2EmissionsToAdd)
                        .tag(activity.id.uuidString)
                }
            }
            .tabViewStyle(.page)
            .indexViewStyle(.page(backgroundDisplayMode: .always))
            
            HStack (alignment: .lastTextBaseline) {
                Button {                    
                    withAnimation {
                            quantityUnitFromActivity -= 0.1
                        
                        if let selectedActivity = selectedActivity {
                            co2EmissionsToAdd = quantityUnitFromActivity *
                                                  selectedActivity.co2Emission
                        }
                    }
                } label: {
                    Label("Minus", systemImage: "minus")
                        .font(.title)
                        .fontWeight(.bold)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
                
                VStack {
                    if let selectedActivity = selectedActivity {
                        Text("(\(selectedActivity.type.quantityUnit))")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("\(quantityUnitFromActivity, specifier: "%.1f")")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .contentTransition(.numericText(value: quantityUnitFromActivity))
                }
                
                Button {
                    withAnimation {
                        quantityUnitFromActivity += 0.1
                        
                        if let selectedActivity = selectedActivity {
                            co2EmissionsToAdd = quantityUnitFromActivity *
                            selectedActivity.co2Emission
                        }
                    }
                } label: {
                    Label("Plus", systemImage: "plus")
                        .font(.title)
                        .fontWeight(.bold)
                        .labelStyle(.iconOnly)
                }
                .buttonStyle(.borderless)
                .buttonBorderShape(.circle)
            }
            .padding(.vertical, 24)
            
            Button {
                addEvent()
            } label: {
                Text("Add event")
                    .font(.headline)
                    .padding(.vertical, 8)
                    .padding(.horizontal)
                    .foregroundStyle(.background)
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .tint(.primary)
            .buttonStyle(.borderedProminent)
            .padding()
        }
        .onChange(of: selectedTab) { _, newValue in
            quantityUnitFromActivity = 0
            
            co2EmissionsToAdd = 0
            
            let matchedActivity = activities.first { $0.id.uuidString == newValue }
            if let matchedActivity = matchedActivity {
                selectedActivity = matchedActivity
            }
        }
        .onAppear() {
            if let activity = activities.first {
                selectedTab = activity.id.uuidString
            }
        }
    }
    
    private func addEvent() {
        let newEvent = ActivityEvent(
            quantity: quantityUnitFromActivity,
            activity: selectedActivity
        )
        
        modelContext.insert(newEvent)
        
        dismiss()
    }
}

#Preview {
    ListActivityEventView()
}
