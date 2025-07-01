//
//  ContentView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import Charts
import SwiftData
import SwiftUI

struct CO2Data: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
}

struct ContentView: View {
    enum ActiveSheet: Identifiable {
        case createActivityEvent
        case viewActivities
        case createActivity
        
        var id: String {
            switch self {
            case .createActivityEvent:
                return "createActivityEvent"
            case .viewActivities:
                return "viewActivities"
            case .createActivity:
                return "createActivity"
            }
        }
    }
    
    @State var activeSheet: ActiveSheet?
    
    var data: [CO2Data] = [
        .init(type: "Car", count: 10),
        .init(type: "Airplane", count: 7),
        .init(type: "Meat", count: 2),
        .init(type: "Milk", count: 1),
        .init(type: "House", count: 4),
        .init(type: "Walking", count: -3),
    ]
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Grid (alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8, content: {
                        VStack(alignment: .leading)  {
                            Text("This week CO2")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Chart {
                                ForEach(data) { data in
                                    BarMark(
                                        x: .value("Shape Type", data.type),
                                        y: .value("Total Count", data.count)
                                    )
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                }
                            }
                        }
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(.regularMaterial)
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        
                        GridRow {
                            VStack (alignment: .leading) {
                                HStack {
                                    Text("Compensation")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button {
                                        
                                    } label: {
                                        Label("Navigate to", systemImage: "chevron.right")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .font(.headline)
                                
                                Text("3")
                                    .font(.title)
                                    .fontWeight(.bold)
                                +
                                Text("kg")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack (alignment: .leading) {
                                HStack {
                                    Text("Consumption")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button {
                                        
                                    } label: {
                                        Label("Navigate to", systemImage: "chevron.right")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .font(.headline)
                                
                                Text("20")
                                    .font(.title)
                                    .fontWeight(.bold)
                                +
                                Text("kg")
                                    .font(.caption)
                                    .fontWeight(.medium)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        GridRow {
                            VStack (alignment: .leading) {
                                HStack {
                                    Text("Most used")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button {
                                        
                                    } label: {
                                        Label("Navigate to", systemImage: "chevron.right")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .font(.headline)
                                .frame(maxHeight: .infinity, alignment: .top)
                                
                                Text("🚗 Car")
                                    .font(.title)
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            
                            VStack (alignment: .leading) {
                                HStack {
                                    Text("Tips")
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                    
                                    Button {
                                        
                                    } label: {
                                        Label("Navigate to", systemImage: "chevron.right")
                                            .labelStyle(.iconOnly)
                                    }
                                }
                                .font(.headline)
                                
                                Text("Try to reduce the amount of meat 🥩")
                                    .fontWeight(.bold)
                            }
                            .padding()
                            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                            .background(.regularMaterial)
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                    })
                    
                    VStack {
//                        Button {
//                            
//                        } label: {
//                            Text("Edit summary".capitalized)
//                                .font(.headline)
//                                .foregroundStyle(.background)
//                                .padding(.vertical, 8)
//                                .padding(.horizontal)
//                                .frame(maxWidth: .infinity, alignment: .center)
//                        }
//                        .tint(.primary)
//                        .buttonStyle(.borderedProminent)
                        
                        Button {
                            activeSheet = .viewActivities
                        } label: {
                            Text("See all activities".capitalized)
                                .font(.headline)
                                .padding(.vertical, 8)
                                .padding(.horizontal)
                                .foregroundStyle(.background)
                                .frame(maxWidth: .infinity, alignment: .center)
                        }
                        .tint(.primary)
                        .buttonStyle(.borderedProminent)
                    }
                    .padding(.vertical)
                }
                .padding()
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createActivityEvent
                    } label: {
                        Label("Add", systemImage: "plus.circle.fill")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            activeSheet = .createActivity
                        } label: {
                            Label("Add activity", systemImage: "plus")
                        }
                    } label: {
                        Label("More", systemImage: "ellipsis.circle.fill")
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createActivityEvent:
                    ListActivityEventView()
                case .viewActivities:
                    ListActivityView()
                        .presentationDetents([.medium, .large])
                case .createActivity:
                    CreateActivityView()
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
