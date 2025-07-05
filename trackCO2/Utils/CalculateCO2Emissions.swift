//
//  CalculateCO2Emissions.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import Foundation

func calculateCO2Totals(activities: [Activity]) -> (consumption: Double, compensation: Double) {
    var totalConsumption: Double = 0.0
    var totalCompensation: Double = 0.0
    
    for activity in activities {
        guard let events = activity.events else { continue }
        for event in events {
            let emission = event.quantity * activity.co2Emission
            
            if emission > .zero {
                totalConsumption += emission
            } else if emission < .zero {
                totalCompensation += abs(emission)
            }
        }
    }
    
    return (consumption: totalConsumption, compensation: totalCompensation)
}

func findMostUsedActivity(activities: [Activity]) -> Activity? {
    guard !activities.isEmpty else { return nil }
    return activities.max(by: { ($0.events?.count ?? 0) < ($1.events?.count ?? 0) })
}

func calculateWeeklyUsage(activity: Activity) -> Double {
    guard let events = activity.events else { return 0.0 }
    
    let calendar = Calendar.current
    let now = Date()
    let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now
    
    let weeklyEvents = events.filter { event in
        event.createdAt >= oneWeekAgo && event.createdAt <= now
    }
    
    return weeklyEvents.reduce(0.0) { total, event in
        total + event.quantity
    }
}

func hasEnoughDataForTrends(activity: Activity) -> Bool {
    guard let events = activity.events, !events.isEmpty else { return false }
    
    let calendar = Calendar.current
    let now = Date()
    let fiveDaysAgo = calendar.date(byAdding: .day, value: -5, to: now) ?? now
    
    let recentEvents = events.filter { event in
        event.createdAt >= fiveDaysAgo && event.createdAt <= now
    }
    
    // Check if we have events spanning at least 5 different days
    let uniqueDays = Set(recentEvents.map { event in
        calendar.startOfDay(for: event.createdAt)
    })
    
    return uniqueDays.count >= 5
}

func getTopActivitiesByWeeklyUsage(activities: [Activity], limit: Int = 2) -> [Activity] {
    let activitiesWithUsage = activities.map { activity in
        (activity: activity, weeklyUsage: calculateWeeklyUsage(activity: activity))
    }
    
    return activitiesWithUsage
        .filter { $0.weeklyUsage > 0 && hasEnoughDataForTrends(activity: $0.activity) }
        .sorted { $0.weeklyUsage > $1.weeklyUsage }
        .prefix(limit)
        .map { $0.activity }
}

func hasAnyTrendsData(activities: [Activity]) -> Bool {
    return activities.contains { activity in
        calculateWeeklyUsage(activity: activity) > 0 && hasEnoughDataForTrends(activity: activity)
    }
}
