//
//  ListTrendsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 05/07/25.
//

import SwiftUI
import SwiftData

struct ListTrendsView: View {
    @Query var activities: [Activity] = []
    
    var allActivitiesWithUsage: [(activity: Activity, weeklyUsage: Double, weeklyCO2: Double)] {
        activities.map { activity in
            let weeklyUsage = calculateWeeklyUsage(activity: activity)
            let weeklyCO2 = weeklyUsage * activity.co2Emission
            return (activity: activity, weeklyUsage: weeklyUsage, weeklyCO2: weeklyCO2)
        }
        .filter { $0.weeklyUsage > 0 && hasEnoughDataForTrends(activity: $0.activity) }
        .sorted { $0.weeklyCO2 > $1.weeklyCO2 }
    }
    
    var body: some View {
        List {
            if allActivitiesWithUsage.isEmpty {
                Section {
                    VStack(alignment: .center, spacing: 16) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        
                        Text("No Activity Data")
                            .font(.title2)
                            .fontWeight(.semibold)
                        
                                        Text("You need at least 5 days of activity data to see trends")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 40)
                }
            } else {
                Section {
                    ForEach(allActivitiesWithUsage, id: \.activity.id) { item in
                        HStack(spacing: 16) {
                            // Activity Icon
                            Text(item.activity.type.emoji)
                                .font(.title2)
                                .frame(width: 40, height: 40)
                                .background(.ultraThinMaterial)
                                .clipShape(Circle())
                            
                            // Activity Details
                            VStack(alignment: .leading, spacing: 4) {
                                Text(item.activity.type.rawValue)
                                    .font(.headline)
                                    .lineLimit(1)
                                
                                Text("\(item.weeklyUsage, specifier: "%.1f") \(item.activity.quantityUnit.rawValue) this week")
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            
                            Spacer()
                            
                            // CO2 Impact
                            VStack(alignment: .trailing, spacing: 4) {
                                Text("\(item.weeklyCO2, specifier: "%.1f") kg CO₂")
                                    .font(.headline)
                                    .foregroundStyle(item.activity.type.isCO2Reducing ? .green : .red)
                                
                                Text(item.activity.type.isCO2Reducing ? "Saved" : "Emitted")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Weekly Trends")
                        .font(.headline)
                        .textCase(.none)
                } footer: {
                    Text("Sorted by CO₂ impact (highest to lowest)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                
                // Summary Section
                Section {
                    let totalEmitted = allActivitiesWithUsage
                        .filter { !$0.activity.type.isCO2Reducing }
                        .reduce(0.0) { $0 + $1.weeklyCO2 }
                    
                    let totalSaved = allActivitiesWithUsage
                        .filter { $0.activity.type.isCO2Reducing }
                        .reduce(0.0) { $0 + abs($1.weeklyCO2) }
                    
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Total Emitted")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalEmitted, specifier: "%.1f") kg CO₂")
                                .font(.headline)
                                .foregroundStyle(.red)
                        }
                        
                        Spacer()
                        
                        VStack(alignment: .trailing, spacing: 4) {
                            Text("Total Saved")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text("\(totalSaved, specifier: "%.1f") kg CO₂")
                                .font(.headline)
                                .foregroundStyle(.green)
                        }
                    }
                    .padding(.vertical, 8)
                } header: {
                    Text("Weekly Summary")
                        .font(.headline)
                        .textCase(.none)
                }
            }
        }
        .navigationTitle("Trends")
        .navigationBarTitleDisplayMode(.large)
    }
}

#Preview {
    NavigationView {
        ListTrendsView()
    }
}
