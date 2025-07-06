//
//  SummaryView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import SwiftData
import SwiftUI

struct SummaryView: View {
    enum ActiveSheet: Identifiable {
        case createActivityEvent
        case viewActivities
        case createActivity
        case selectActivities
        
        var id: String {
            switch self {
            case .createActivityEvent:
                return "createActivityEvent"
            case .viewActivities:
                return "viewActivities"
            case .createActivity:
                return "createActivity"
            case .selectActivities:
                return "selectActivities"
                
            }
        }
    }
    
    @Query var activities: [Activity]
    
    @State var activeSheet: ActiveSheet?
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Grid (alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8, content: {
                        CO2ChartView()
                        
                        GridRow {
                            CompensationView()
                            
                            ConsumptionView()
                        }
                        
                        GridRow {
                            MostUsedView()
                            
                            TipsView()
                        }
                        
                        if hasAnyTrendsData(activities: activities) {
                            TrendsView()
                        }
                    })
                    
                    VStack {
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
                    .disabled(activities.isEmpty)
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            activeSheet = .createActivity
                        } label: {
                            Label("Add activity", systemImage: "plus.circle.fill")
                        }
                        
                        Button {
                            activeSheet = .selectActivities
                        } label: {
                            Label("Add default activities", systemImage: "square.and.arrow.down.on.square.fill")
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
                case .selectActivities:
                    SelectActivitiesToPersistView()
                }
            }
        }
    }
}

#Preview {
    SummaryView()
}
