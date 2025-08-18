//
//  ListActivityEventView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 01/07/25.
//

import SwiftData
import SwiftUI
import TipKit

struct ListActivityEventView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    @Environment(\.verticalSizeClass) var verticalSizeClass

    
    @Query var activities: [Activity]
    
    @State private var co2EmissionsToAdd: Double = 0.0
    @State private var quantityUnitFromActivity: Double = 0.0 // km, kg, ecc
    
    @State private var selectedTab: String?
    @State private var selectedActivity: Activity?
    
    @State private var stepSize: Double = 1.0
    
    private let stepOptions: [Double] = [0.01, 0.1, 1, 10, 100]
    
    private var multiplierTip = SelectPlusMultiplierTip()
    
    var isHorizontal: Bool { verticalSizeClass == .compact }
    
    var body: some View {
        NavigationStack {
            VStack {
                TabView (selection: $selectedTab) {
                    ForEach(activities) { activity in
                        ActivityEventTabView(activity: activity, currentCO2Emission: co2EmissionsToAdd)
                            .tag(activity.id.uuidString)
                    }
                }
                .tabViewStyle(.page)
                .indexViewStyle(.page(backgroundDisplayMode: .always))
                
                HStack(alignment: .center, spacing: 16) {
                    Button(action: {
                        withAnimation {
                            quantityUnitFromActivity = max(0, quantityUnitFromActivity - stepSize)
                            if let selectedActivity = selectedActivity {
                                co2EmissionsToAdd = quantityUnitFromActivity * selectedActivity.co2Emission
                            }
                        }
                    }) {
                        Image(systemName: "minus")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .contextMenu {
                        ForEach(stepOptions, id: \..self) { option in
                            Button(action: {
                                stepSize = option
                            }) {
                                Text(option == floor(option) ? String(format: "%.0f", option) : String(option))
                                if stepSize == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    
                    VStack(spacing: 4) {
                        if let selectedActivity = selectedActivity {
                            Text(verbatim: "(\(selectedActivity.type.quantityUnit))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        
                        Text("\(quantityUnitFromActivity, specifier: "%.2f")")
                            .font(.largeTitle)
                            .fontWeight(.bold)
                            .contentTransition(.numericText(value: quantityUnitFromActivity))
                        
                        Text("x\(stepSize, specifier: "%.2f")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(minWidth: 80)
                    
                    Button(action: {
                        withAnimation {
                            quantityUnitFromActivity = min(1000, quantityUnitFromActivity + stepSize)
                            if let selectedActivity = selectedActivity {
                                co2EmissionsToAdd = quantityUnitFromActivity * selectedActivity.co2Emission
                            }
                        }
                    }) {
                        Image(systemName: "plus")
                            .font(.title)
                            .fontWeight(.bold)
                    }
                    .contextMenu {
                        ForEach(stepOptions, id: \..self) { option in
                            Button(action: {
                                stepSize = option
                            }) {
                                Text(option == floor(option) ? String(format: "%.0f", option) : String(option))
                                if stepSize == option {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                    .buttonStyle(.borderless)
                    .buttonBorderShape(.circle)
                    .popoverTip(multiplierTip)
                }
                
                if !isHorizontal {
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
            }
            .navigationTitle("Add event")
            .toolbar {
                if isHorizontal {
                    ToolbarItem(placement: .topBarTrailing) {
                        Button("Save") {
                            addEvent()
                        }
                    }
                }
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

