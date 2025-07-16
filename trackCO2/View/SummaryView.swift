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
        case addTrip
        
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
            case .addTrip:
                return "addTrip"
            }
        }
    }
    
    @Environment(\.modelContext) var modelContext
    
    @Query var activities: [Activity]
    
    @State private var healthKitManager = HealthKitManager.shared
    
    @State var activeSheet: ActiveSheet?
    
    @State private var manageSubscription: Bool = false
    
    @State var storeKit = Store()
    
    @State private var showAddYesterdayWalkingAlert = false
    @State private var yesterdayDistance: Double = 0.0
    @State private var healthKitAuthorized: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Grid (alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8, content: {
                        CO2ChartView()
                        
                        if healthKitAuthorized {
                            GridRow {
                                StepCountView()
                                WalkingRunningDistanceView()
                            }
                        }
                        
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
                            Label("Add activity", systemImage: "plus")
                        }
                        
                        Button {
                            activeSheet = .selectActivities
                        } label: {
                            Label("Add default activities", systemImage: "square.and.arrow.down.on.square")
                        }
                        
                        Button {
                            activeSheet = .addTrip
                        } label: {
                            Label("Add map trip", systemImage: "map")
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
                case .addTrip:
                    SelectTypeView()
                }
            }
            .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: storeKit.groupId)
            .onAppear {
                healthKitManager.requestAuthorization { success in
                    healthKitAuthorized = success
                    if success {
                        healthKitManager.fetchTodayData()
                        healthKitManager.fetchHistoryData()
                        healthKitManager.fetchStepsPerHourForToday()
                        healthKitManager.fetchDistancePerHourForToday()
                        // Check for yesterday's walking event
                        healthKitManager.fetchYesterdayDistance { distance in
                            guard distance > 0 else { return }
                            let walkingActivity = activities.first { $0.type == .walking }
                            let calendar = Calendar.current
                            let today = calendar.startOfDay(for: Date())
                            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today) else { return }
                            let hasEvent = walkingActivity?.events?.contains(where: { event in
                                calendar.isDate(event.createdAt, inSameDayAs: yesterday)
                            }) ?? false
                            if !hasEvent {
                                yesterdayDistance = distance
                                showAddYesterdayWalkingAlert = true
                            }
                        }
                    }
                }
            }
            .alert("Add yesterday's walking distance?", isPresented: $showAddYesterdayWalkingAlert, actions: {
                Button("Add", role: .none) {
                    let walkingActivity = activities.first { $0.type == .walking }
                    let calendar = Calendar.current
                    let today = calendar.startOfDay(for: Date())
                    guard let yesterday = calendar.date(byAdding: .day, value: -1, to: today), let walkingActivity else { return }
                    let event = ActivityEvent(quantity: yesterdayDistance / 1000.0, activity: walkingActivity)
                    event.createdAt = yesterday
                    modelContext.insert(event)
                }
                Button("Cancel", role: .cancel) {}
            }, message: {
                Text("You walked \(String(format: "%.2f", yesterdayDistance / 1000.0)) km yesterday. Would you like to record this as an activity event?")
            })
        }
    }
}

#Preview {
    SummaryView()
}
