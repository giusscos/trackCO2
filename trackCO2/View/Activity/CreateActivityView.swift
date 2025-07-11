//
//  CreateActivityView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import SwiftData
import SwiftUI
import TipKit

struct CreateActivityView: View {
    @Environment(\.dismiss) var dismiss
    @Environment(\.modelContext) var modelContext
    
    enum Field: Hashable {
        case activityName
        case activityDescription
    }
    
    @FocusState private var focusedField: Field?
    
    @State private var type: ActivityEmissionType = ActivityEmissionType.car
    @State private var activityName: String = ""
    @State private var activityDescription: String = ""
    @State private var emissionType: EmissionUnit = EmissionUnit.kgCO2e
    @State private var co2Emission: Double = 0.0
    
    @State private var stepSize: Double = 1.0
    
    private let stepOptions: [Double] = [0.01, 0.1, 1, 10, 100]
    
    private let multiplierTip = SelectPlusMultiplierTip()
    
    private var isFormValid: Bool {
        !activityName.isEmpty
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker(selection: $type) {
                        ForEach(ActivityEmissionType.allCases, id: \.self) { type in
                            Text("\(type.emoji) \(type.rawValue) (\(type.quantityUnit))")
                        }
                    } label: {
                        Text("Activity type")
                            .font(.headline)
                    }
                } header: {
                    Text("Type")
                }
                
                Section {
                    TextField("Name", text: $activityName)
                        .focused($focusedField, equals: .activityName)
                        .submitLabel(.next)
                        .onSubmit {
                            focusedField = .activityDescription
                        }
                    
                    TextField("Description", text: $activityDescription)
                        .focused($focusedField, equals: .activityName)
                        .submitLabel(.done)
                        .onSubmit {
                            focusedField = nil
                        }
                } header: {
                    Text("Info")
                }
                
                Section {
                    VStack (alignment: .leading) {
                        Picker(selection: $emissionType) {
                            ForEach(EmissionUnit.allCases, id: \.self) { emissionType in
                                Text("\(emissionType)")
                            }
                        } label: {
                            Text("CO2 unit")
                                .font(.headline)
                        }
                        
                        Text("CO2e that is equivalent to CO2eq")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    
                    Text("CO2 amount")
                        .font(.headline)
                    
                    HStack(alignment: .center, spacing: 16) {
                        Button {
                            withAnimation {
                                co2Emission -= stepSize
                            }
                        } label: {
                            Label("Minus", systemImage: "minus")
                                .font(.title)
                                .fontWeight(.bold)
                                .labelStyle(.iconOnly)
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
                        
                        VStack(spacing: 4) {
                            Text("(\(type.quantityUnit))")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            
                            Text("\(co2Emission, specifier: "%.2f")")
                                .font(.largeTitle)
                                .fontWeight(.bold)
                                .contentTransition(.numericText(value: co2Emission))
                            
                            Text("x\(stepSize, specifier: "%.2f")")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
//                        .frame(minWidth: 80)
                        
                        Button {
                            withAnimation {
                                co2Emission += stepSize
                            }
                        } label: {
                            Label("Plus", systemImage: "plus")
                                .font(.title)
                                .fontWeight(.bold)
                                .labelStyle(.iconOnly)
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
                    .padding(.vertical)
                    .frame(maxWidth: .infinity, alignment: .center)
                } header: {
                    Text("Amount")
                }
                .listRowSeparator(.hidden)
            }
            .navigationTitle("Create Activity")
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Save") {
                        addActivity()
                    }
                    .disabled(!isFormValid)
                }
            }
        }
    }
    
    private func addActivity() {
        if !activityName.isEmpty {
         
            let newActivity = Activity(
                type: type,
                name: activityName,
                activityDescription: activityDescription,
                quantityUnit: type.quantityUnit,
                emissionUnit: emissionType,
                co2Emission: co2Emission
            )
            
            modelContext.insert(newActivity)
            
            dismiss()
        }
    }
}

#Preview {
    CreateActivityView()
}
