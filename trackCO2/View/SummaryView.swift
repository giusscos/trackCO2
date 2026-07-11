//
//  SummaryView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 06/07/25.
//

import SwiftData
import SwiftUI
import HealthKit
import StoreKit

struct SummaryView: View {
    enum ActiveSheet: Identifiable {
        case createActivityEvent
        case createActivity
        case selectActivities
        case selectAppIcon

        var id: String {
            switch self {
            case .createActivityEvent:
                return "createActivityEvent"
            case .createActivity:
                return "createActivity"
            case .selectActivities:
                return "selectActivities"
            case .selectAppIcon:
                return "selectAppIcon"
            }
        }
    }
    
    @AppStorage("appIcon") var appIcon: String = defaultAppIcon
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    @Environment(\.modelContext) var modelContext
    @Environment(\.requestReview) var requestReview

    @Query var activities: [Activity]
    
    @State private var healthKitManager = HealthKitManager.shared
    
    @State var activeSheet: ActiveSheet?
    
    @State private var manageSubscription: Bool = false
    
    @State var storeKit = Store()
    
    @State private var showAddYesterdayWalkingAlert = false
    @State private var yesterdayDistance: Double = 0.0
    @State private var healthKitAuthorized: Bool = false
    @State private var requestReviewShown: Bool = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack {
                    Grid (alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8, content: {
                        ClaudMascotView(healthScore: calculateWeeklyCO2Health(activities: activities))

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
                }
                .padding()
            }
            .navigationTitle("Summary")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        activeSheet = .createActivityEvent
                    } label: {
                        if #available(iOS 26, *) {
                            Label("Add", systemImage: "plus")
                        } else {
                            Label("Add", systemImage: "plus.circle.fill")
                        }
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

                        Divider()
                        
                        Button {
                            activeSheet = .selectAppIcon
                        } label: {
                            Label("App Icon", systemImage: "inset.filled.square.dashed")
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
                        if #available(iOS 26, *) {
                            Label("More", systemImage: "ellipsis")
                        } else {
                            Label("More", systemImage: "ellipsis.circle.fill")
                        }
                    }
                }
            }
            .sheet(item: $activeSheet) { sheet in
                switch sheet {
                case .createActivityEvent:
                    ListActivityEventView()
                case .createActivity:
                    CreateActivityView()
                case .selectActivities:
                    SelectActivitiesToPersistView()
                case .selectAppIcon:
                    SelectAppIconView(selectedIcon: $appIcon)
                }
            }
            .manageSubscriptionsSheet(isPresented: $manageSubscription, subscriptionGroupID: storeKit.groupId)
            .onAppear {
                guard hasCompletedOnboarding else { return }
                loadHealthKitData()
            }
            .onChange(of: hasCompletedOnboarding) { _, completed in
                guard completed else { return }
                loadHealthKitData()
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
    
    private func loadHealthKitData() {
        healthKitManager.requestAuthorization { success in
            healthKitAuthorized = success
            if success {
                healthKitManager.fetchTodayData()
                healthKitManager.fetchHistoryData()
                healthKitManager.fetchStepsPerHourForToday()
                healthKitManager.fetchDistancePerHourForToday()
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

            if requestReviewShown { return }

            checkAndRequestReview()
            requestReviewShown = true
        }
    }

    private func checkAndRequestReview() {
        let compensation = calculateCO2Totals(activities: activities).compensation
        let consumption = calculateCO2Totals(activities: activities).consumption
        
        let threshold: Double = 100.0 // Set your desired threshold here
        
        if compensation >= threshold || consumption >= (threshold * 3) {
            requestReview()
        }
    }
}

#Preview {
    SummaryView()
}
