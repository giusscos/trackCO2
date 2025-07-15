//
//  SummaryView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import SwiftData
import SwiftUI
import HealthKit

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
    
    @State private var healthKitManager = HealthKitManager.shared
    
    @State var activeSheet: ActiveSheet?
    
    @State private var manageSubscription: Bool = false
    
    @State var storeKit = Store()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Grid (alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8, content: {
                        CO2ChartView()
                        
                        GridRow {
                            StepCountView()
                            
                            WalkingRunningDistanceView()
                        }
                        // END NEW
                        
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
                        
                        Divider()
                        
                        if storeKit.purchasedSubscriptions.count > 0 {
                            Button {
                                manageSubscription.toggle()
                            } label: {
                                Text("Manage subscription")
                            }
                        }
                        
                        Divider()
                        
                        Link("Terms of Service", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
                        Link("Privacy Policy", destination: URL(string: "https://giusscos.it/privacy")!)
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
            .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: storeKit.groupId)
            .onAppear {
                healthKitManager.requestAuthorization { success in
                    if success {
                        healthKitManager.fetchTodayData()
                        healthKitManager.fetchHistoryData()
                        healthKitManager.fetchStepsPerHourForToday()
                        healthKitManager.fetchDistancePerHourForToday()
                    }
                }
            }
        }
    }
}

#Preview {
    SummaryView()
}
