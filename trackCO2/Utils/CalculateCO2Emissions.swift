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
    let activitiesWithEvents = activities.filter { ($0.events?.count ?? 0) > 0 }
    guard !activitiesWithEvents.isEmpty else { return nil }
    return activitiesWithEvents.max(by: { ($0.events?.count ?? 0) < ($1.events?.count ?? 0) })
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

func calculateWeeklyCO2Health(activities: [Activity]) -> Double {
    let calendar = Calendar.current
    let now = Date()
    let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

    var consumption: Double = 0
    var compensation: Double = 0

    for activity in activities {
        guard let events = activity.events else { continue }
        for event in events where event.createdAt >= sevenDaysAgo {
            let emission = event.quantity * activity.co2Emission
            if emission > 0 { consumption += emission }
            else if emission < 0 { compensation += abs(emission) }
        }
    }

    let total = consumption + compensation
    guard total > 0 else { return 0.5 }
    return min(compensation / total, 1.0)
}

func hasAnyTrendsData(activities: [Activity]) -> Bool {
    return activities.contains { activity in
        calculateWeeklyUsage(activity: activity) > 0 && hasEnoughDataForTrends(activity: activity)
    }
}

/// Returns the number of consecutive days (ending today) on which at least one activity event was logged.
func calculateCurrentStreak(activities: [Activity]) -> Int {
    let calendar = Calendar.current
    let allEvents = activities.flatMap { $0.events ?? [] }
    guard !allEvents.isEmpty else { return 0 }

    var streak = 0
    var checkDate = calendar.startOfDay(for: Date())

    while true {
        guard let nextDay = calendar.date(byAdding: .day, value: 1, to: checkDate) else { break }
        let hasEvent = allEvents.contains { $0.createdAt >= checkDate && $0.createdAt < nextDay }
        guard hasEvent else { break }
        streak += 1
        guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
        checkDate = prevDay
    }

    return streak
}

/// Returns the net CO₂ (kg) for a given calendar day, or nil if no events were logged that day.
func calculateDailyNetCO2(activities: [Activity], for date: Date) -> Double? {
    let calendar = Calendar.current
    let startOfDay = calendar.startOfDay(for: date)
    guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else { return nil }

    var hasData = false
    var net = 0.0

    for activity in activities {
        for event in activity.events ?? [] where event.createdAt >= startOfDay && event.createdAt < endOfDay {
            net += event.quantity * activity.co2Emission
            hasData = true
        }
    }

    return hasData ? net : nil
}
