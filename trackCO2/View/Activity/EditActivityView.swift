//
//  EditActivityView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 30/06/25.
//

import SwiftData
import SwiftUI
import TipKit

struct EditActivityView: View {
    @Environment(\.modelContext) var modelContext
    @Environment(\.dismiss) var dismiss
    
    @Bindable var activity: Activity
    
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
    
    @State private var isDeletingActivity: Bool = false
    
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
                    
                    HStack (spacing: 24) {
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
                        
                        HStack(alignment: .center, spacing: 16) {
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
                
                Section {
                    Button(role: .destructive) {
                        isDeletingActivity = true
                    } label: {
                        Text("Delete activity".capitalized)
                            .padding(8)
                            .font(.headline)
                            .frame(maxWidth: .infinity, alignment: .center)
                    }
                    .buttonStyle(.borderedProminent)
                }
                .listRowSeparator(.hidden)
                .listRowInsets(.init(top: 0, leading: 0, bottom: 0, trailing: 0))
                .listRowBackground(Color.clear)
            }
            .onAppear() {
                type = activity.type
                activityName = activity.name
                activityDescription = activity.activityDescription
                emissionType = activity.emissionUnit
                co2Emission = activity.co2Emission
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
                        editActivity()
                    }
                    .disabled(!isFormValid)
                }
            }
            .alert("Are you sure you want to delete this activity?", isPresented: $isDeletingActivity) {
                                
                Button("Delete", role: .destructive) {
                    modelContext.delete(activity)
                    
                    dismiss()
                }
            }
        }
    }
    
    private func editActivity() {
        if !activityName.isEmpty {
            activity.type = type
            activity.name = activityName
            activity.activityDescription = activityDescription
            activity.quantityUnit = type.quantityUnit
            activity.emissionUnit = emissionType
            activity.co2Emission = co2Emission
            
            dismiss()
        }
    }
}

#Preview {
    EditActivityView(activity: Activity(name: "Car"))
}
