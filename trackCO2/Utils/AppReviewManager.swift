//
//  AppReviewManager.swift
//  trackCO2
//

import Foundation

enum AppReviewManager {
    private static let visitDatesKey = "reviewVisitDates"
    private static let lastRequestedAtKey = "reviewLastRequestedAt"
    private static let requestCountKey = "reviewRequestCount"

    static let promptDelay: TimeInterval = 2.5
    private static let minimumVisitDays = 3
    private static let minimumTotalEvents = 5
    private static let minimumLoggingDays = 2
    private static let minimumHealthScore = 0.5
    private static let cooldownDays = 120
    private static let maxRequestAttempts = 3

    static func recordVisit(on date: Date = .now) {
        let day = dayString(for: date)
        var dates = visitDates
        guard !dates.contains(day) else { return }
        dates.append(day)
        if dates.count > 30 {
            dates = Array(dates.suffix(30))
        }
        visitDates = dates
    }

    static func shouldRequestReview(activities: [Activity]) -> Bool {
        guard requestCount < maxRequestAttempts else { return false }
        guard visitDates.count >= minimumVisitDays else { return false }
        guard totalEventCount(in: activities) >= minimumTotalEvents else { return false }
        guard distinctLoggingDays(in: activities) >= minimumLoggingDays else { return false }
        guard calculateWeeklyCO2Health(activities: activities) >= minimumHealthScore else { return false }

        if let lastRequestedAt {
            let cooldownEnd = Calendar.current.date(byAdding: .day, value: cooldownDays, to: lastRequestedAt) ?? lastRequestedAt
            guard Date.now >= cooldownEnd else { return false }
        }

        return true
    }

    static func markReviewRequested(on date: Date = .now) {
        lastRequestedAt = date
        requestCount += 1
    }

    private static var visitDates: [String] {
        get { UserDefaults.standard.stringArray(forKey: visitDatesKey) ?? [] }
        set { UserDefaults.standard.set(newValue, forKey: visitDatesKey) }
    }

    private static var lastRequestedAt: Date? {
        get {
            let timestamp = UserDefaults.standard.double(forKey: lastRequestedAtKey)
            return timestamp > 0 ? Date(timeIntervalSince1970: timestamp) : nil
        }
        set {
            UserDefaults.standard.set(newValue?.timeIntervalSince1970 ?? 0, forKey: lastRequestedAtKey)
        }
    }

    private static var requestCount: Int {
        get { UserDefaults.standard.integer(forKey: requestCountKey) }
        set { UserDefaults.standard.set(newValue, forKey: requestCountKey) }
    }

    private static func dayString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.calendar = Calendar.current
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: date)
    }

    private static func totalEventCount(in activities: [Activity]) -> Int {
        activities.reduce(0) { $0 + ($1.events?.count ?? 0) }
    }

    private static func distinctLoggingDays(in activities: [Activity]) -> Int {
        let calendar = Calendar.current
        var days = Set<Date>()
        for activity in activities {
            guard let events = activity.events else { continue }
            for event in events {
                days.insert(calendar.startOfDay(for: event.createdAt))
            }
        }
        return days.count
    }
}
