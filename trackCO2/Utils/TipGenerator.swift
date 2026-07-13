//
//  TipGenerator.swift
//  trackCO2
//

import Foundation

struct TipGenerator {

    // MARK: - Priority constants (lower = higher priority)

    private enum Priority {
        static let highImpactEmitter = 1
        static let trend = 2
        static let offsetGap = 3
        static let substitution = 4
        static let foodSwap = 5
        static let streak = 6
        static let milestone = 6
        static let inactivity = 7
        static let fallback = 8
    }

    // MARK: - Public API

    static func generate(from activities: [Activity]) -> [GeneratedTip] {
        let pairs = allEventPairs(from: activities)
        guard !pairs.isEmpty else {
            return [fallbackTip()]
        }

        let calendar = Calendar.current
        let now = Date()
        let ranges = DateRanges(calendar: calendar, now: now)

        var tips: [GeneratedTip] = []

        if let tip = highImpactEmitterTip(pairs: pairs, ranges: ranges) { tips.append(tip) }
        if let tip = trendTip(pairs: pairs, ranges: ranges) { tips.append(tip) }
        if let tip = offsetGapTip(pairs: pairs, ranges: ranges, activities: activities) { tips.append(tip) }
        if let tip = substitutionTip(pairs: pairs, ranges: ranges, activities: activities) { tips.append(tip) }
        if let tip = foodSwapTip(pairs: pairs, ranges: ranges, activities: activities) { tips.append(tip) }
        if let tip = streakTip(pairs: pairs, calendar: calendar) { tips.append(tip) }
        if let tip = milestoneTip(pairs: pairs) { tips.append(tip) }
        if let tip = inactivityTip(pairs: pairs, calendar: calendar, now: now) { tips.append(tip) }

        return tips.sorted {
            if $0.priority != $1.priority { return $0.priority < $1.priority }
            return $0.title < $1.title
        }
    }

    // MARK: - Tip generators

    private static func highImpactEmitterTip(pairs: [EventPair], ranges: DateRanges) -> GeneratedTip? {
        let monthPairs = pairs.filter { isEmitting($0) && ranges.containsMonth($0.event.createdAt) }
        guard !monthPairs.isEmpty else { return nil }

        var byActivity: [UUID: (activity: Activity, total: Double)] = [:]
        for pair in monthPairs {
            let co2 = emittingCO2(for: pair)
            var entry = byActivity[pair.activity.id, default: (pair.activity, 0)]
            entry.total += co2
            byActivity[pair.activity.id] = entry
        }

        guard let top = byActivity.values.max(by: { $0.total < $1.total }), top.total > 0 else { return nil }
        let monthTotal = byActivity.values.reduce(0.0) { $0 + $1.total }
        let percent = monthTotal > 0 ? (top.total / monthTotal) * 100 : 0

        let message = String(
            format: String(localized: "tip.high_impact_emitter"),
            top.activity.type.emoji,
            top.activity.displayName,
            top.total,
            percent
        )

        return GeneratedTip(
            priority: Priority.highImpactEmitter,
            title: String(localized: "tip.title.high_impact_emitter"),
            message: message,
            activity: top.activity,
            isPositive: false
        )
    }

    private static func trendTip(pairs: [EventPair], ranges: DateRanges) -> GeneratedTip? {
        let monthPairs = pairs.filter { isEmitting($0) && ranges.containsMonth($0.event.createdAt) }
        guard !monthPairs.isEmpty else { return nil }

        var monthByActivity: [UUID: (activity: Activity, total: Double)] = [:]
        for pair in monthPairs {
            let co2 = emittingCO2(for: pair)
            var entry = monthByActivity[pair.activity.id, default: (pair.activity, 0)]
            entry.total += co2
            monthByActivity[pair.activity.id] = entry
        }

        guard let topEmitter = monthByActivity.values.max(by: { $0.total < $1.total })?.activity else { return nil }

        let thisWeekCO2 = pairs
            .filter { $0.activity.id == topEmitter.id && ranges.containsThisWeek($0.event.createdAt) }
            .reduce(0.0) { $0 + emittingCO2(for: $1) }

        let lastWeekCO2 = pairs
            .filter { $0.activity.id == topEmitter.id && ranges.containsLastWeek($0.event.createdAt) }
            .reduce(0.0) { $0 + emittingCO2(for: $1) }

        guard lastWeekCO2 > 0 else { return nil }
        let percentChange = ((thisWeekCO2 - lastWeekCO2) / lastWeekCO2) * 100
        guard percentChange > 20 else { return nil }

        let delta = thisWeekCO2 - lastWeekCO2
        let message = String(
            format: String(localized: "tip.trend_increase"),
            topEmitter.type.emoji,
            topEmitter.displayName.lowercased(),
            percentChange,
            delta
        )

        return GeneratedTip(
            priority: Priority.trend,
            title: String(localized: "tip.title.trend"),
            message: message,
            activity: topEmitter,
            isPositive: false
        )
    }

    private static func offsetGapTip(pairs: [EventPair], ranges: DateRanges, activities: [Activity]) -> GeneratedTip? {
        let monthPairs = pairs.filter { ranges.containsMonth($0.event.createdAt) }
        let emitted = monthPairs.reduce(0.0) { $0 + emittingCO2(for: $1) }
        let offset = monthPairs.reduce(0.0) { $0 + offsetCO2(for: $1) }
        let gap = emitted - offset
        guard gap > 1 else { return nil }

        let treeActivity = activities.first { $0.type == .treePlanting }
            ?? activities.first { $0.type.isCO2Reducing && $0.co2Emission < 0 }
        let perTree = abs(treeActivity?.co2Emission ?? 20.0)
        let treesNeeded = max(1, Int(ceil(gap / perTree)))
        let offsetAmount = Double(treesNeeded) * perTree

        let message = String(
            format: String(localized: "tip.offset_gap"),
            emitted,
            offset,
            treesNeeded,
            offsetAmount
        )

        return GeneratedTip(
            priority: Priority.offsetGap,
            title: String(localized: "tip.title.offset_gap"),
            message: message,
            activity: treeActivity,
            isPositive: false
        )
    }

    private static func substitutionTip(pairs: [EventPair], ranges: DateRanges, activities: [Activity]) -> GeneratedTip? {
        let weekTransport = pairs.filter {
            $0.activity.type.isEmittingTransport && ranges.containsThisWeek($0.event.createdAt)
        }
        guard !weekTransport.isEmpty else { return nil }

        var kmByActivity: [UUID: (activity: Activity, km: Double, trips: Int)] = [:]
        for pair in weekTransport {
            var entry = kmByActivity[pair.activity.id, default: (pair.activity, 0, 0)]
            entry.km += pair.event.quantity
            entry.trips += 1
            kmByActivity[pair.activity.id] = entry
        }

        guard let highEmitter = kmByActivity.values.max(by: { $0.km * $0.activity.co2Emission < $1.km * $1.activity.co2Emission }) else { return nil }

        let alternatives = activities.filter {
            $0.type.category == .transport &&
            !$0.type.isCO2Reducing &&
            $0.co2Emission > 0 &&
            $0.co2Emission < highEmitter.activity.co2Emission &&
            $0.id != highEmitter.activity.id
        }
        guard let alternative = alternatives.min(by: { $0.co2Emission < $1.co2Emission }) else { return nil }

        let avgTripKm = highEmitter.trips > 0 ? highEmitter.km / Double(highEmitter.trips) : highEmitter.km
        let tripsToReplace = min(2, highEmitter.trips)
        guard tripsToReplace > 0, avgTripKm > 0 else { return nil }

        let savingsPerKm = highEmitter.activity.co2Emission - alternative.co2Emission
        let savings = Double(tripsToReplace) * avgTripKm * savingsPerKm
        let percentLess = (1.0 - alternative.co2Emission / highEmitter.activity.co2Emission) * 100

        let message = String(
            format: String(localized: "tip.substitution"),
            highEmitter.activity.type.emoji,
            highEmitter.activity.displayName.lowercased(),
            highEmitter.km,
            tripsToReplace,
            alternative.type.emoji,
            alternative.displayName.lowercased(),
            savings,
            percentLess
        )

        return GeneratedTip(
            priority: Priority.substitution,
            title: String(localized: "tip.title.substitution"),
            message: message,
            activity: highEmitter.activity,
            isPositive: false
        )
    }

    private static func foodSwapTip(pairs: [EventPair], ranges: DateRanges, activities: [Activity]) -> GeneratedTip? {
        let monthPairs = pairs.filter { isEmitting($0) && ranges.containsMonth($0.event.createdAt) }
        guard !monthPairs.isEmpty else { return nil }

        var byActivity: [UUID: (activity: Activity, total: Double)] = [:]
        for pair in monthPairs {
            let co2 = emittingCO2(for: pair)
            var entry = byActivity[pair.activity.id, default: (pair.activity, 0)]
            entry.total += co2
            byActivity[pair.activity.id] = entry
        }

        let top3 = byActivity.values.sorted { $0.total > $1.total }.prefix(3)
        let foodTarget = top3.first { $0.activity.type == .beef || $0.activity.type == .dairy }
        guard let target = foodTarget else { return nil }

        let vegActivity = activities.first { $0.type == .vegetables }
        let vegEmission = vegActivity?.co2Emission ?? 1.0
        let mealKg = averagePortionKg(for: target.activity, pairs: pairs) ?? 0.2
        let monthlySavings = (target.activity.co2Emission - vegEmission) * mealKg * 4

        let message = String(
            format: String(localized: "tip.food_swap"),
            target.activity.type.emoji,
            target.activity.displayName,
            target.activity.co2Emission,
            ActivityEmissionType.vegetables.emoji,
            monthlySavings
        )

        return GeneratedTip(
            priority: Priority.foodSwap,
            title: String(localized: "tip.title.food_swap"),
            message: message,
            activity: target.activity,
            isPositive: false
        )
    }

    private static func streakTip(pairs: [EventPair], calendar: Calendar) -> GeneratedTip? {
        let reducingPairs = pairs.filter { $0.activity.type.isCO2Reducing }
        guard !reducingPairs.isEmpty else { return nil }

        var best: (activity: Activity, streak: Int, totalAvoided: Double)?

        let grouped = Dictionary(grouping: reducingPairs) { $0.activity.id }
        for (_, activityPairs) in grouped {
            guard let activity = activityPairs.first?.activity else { continue }
            let days = Set(activityPairs.map { calendar.startOfDay(for: $0.event.createdAt) })
            let streak = consecutiveDayStreak(endingAt: calendar.startOfDay(for: Date()), from: days, calendar: calendar)
            guard streak >= 3 else { continue }

            let streakStart = calendar.date(byAdding: .day, value: -(streak - 1), to: calendar.startOfDay(for: Date()))!
            let streakPairs = activityPairs.filter { $0.event.createdAt >= streakStart }
            let avoided = streakPairs.reduce(0.0) { $0 + offsetCO2(for: $1) }

            if best == nil || streak > best!.streak || (streak == best!.streak && avoided > best!.totalAvoided) {
                best = (activity, streak, avoided)
            }
        }

        guard let result = best else { return nil }
        let equivalentKm = result.totalAvoided / 0.15

        let message = String(
            format: String(localized: "tip.streak"),
            result.activity.type.emoji,
            result.activity.displayName.lowercased(),
            result.streak,
            result.totalAvoided,
            equivalentKm
        )

        return GeneratedTip(
            priority: Priority.streak,
            title: String(localized: "tip.title.streak"),
            message: message,
            activity: result.activity,
            isPositive: true
        )
    }

    private static func milestoneTip(pairs: [EventPair]) -> GeneratedTip? {
        let cumulative = pairs.reduce(0.0) { $0 + offsetCO2(for: $1) }
        let thresholds: [Double] = [10, 50, 100, 500]

        guard thresholds.reversed().contains(where: { cumulative >= $0 && cumulative < $0 * 1.15 }) else {
            return nil
        }

        // ~1.5 kg CO₂/day for an average car → 10.5 kg/week
        let weeksOffRoad = cumulative / 10.5
        let message = String(
            format: String(localized: "tip.milestone"),
            cumulative,
            weeksOffRoad
        )

        return GeneratedTip(
            priority: Priority.milestone,
            title: String(localized: "tip.title.milestone"),
            message: message,
            activity: nil,
            isPositive: true
        )
    }

    private static func inactivityTip(pairs: [EventPair], calendar: Calendar, now: Date) -> GeneratedTip? {
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now)!
        var candidates: [(activity: Activity, daysSince: Int, eventCount: Int)] = []

        let grouped = Dictionary(grouping: pairs) { $0.activity.id }
        for (_, activityPairs) in grouped {
            guard let activity = activityPairs.first?.activity, activityPairs.count >= 3 else { continue }
            guard let lastEvent = activityPairs.map(\.event.createdAt).max(), lastEvent < sevenDaysAgo else { continue }
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: lastEvent), to: calendar.startOfDay(for: now)).day ?? 7
            candidates.append((activity, days, activityPairs.count))
        }

        guard let inactive = candidates.max(by: { $0.eventCount < $1.eventCount }) else { return nil }

        let walkKm = 2.0
        let walkOffsetGrams = walkKm * 0.15 * 1000
        let message = String(
            format: String(localized: "tip.inactivity"),
            inactive.activity.type.emoji,
            inactive.activity.displayName.lowercased(),
            inactive.daysSince,
            walkKm,
            walkOffsetGrams
        )

        return GeneratedTip(
            priority: Priority.inactivity,
            title: String(localized: "tip.title.inactivity"),
            message: message,
            activity: inactive.activity,
            isPositive: false
        )
    }

    private static func fallbackTip() -> GeneratedTip {
        GeneratedTip(
            priority: Priority.fallback,
            title: String(localized: "tip.title.fallback"),
            message: String(localized: "Start tracking your activities to get personalized tips!"),
            activity: nil,
            isPositive: false
        )
    }

    // MARK: - Helpers

    private struct EventPair {
        let event: ActivityEvent
        let activity: Activity
    }

    private struct DateRanges {
        let calendar: Calendar
        let now: Date
        let monthStart: Date
        let monthEnd: Date
        let thisWeekStart: Date
        let thisWeekEnd: Date
        let lastWeekStart: Date
        let lastWeekEnd: Date

        init(calendar: Calendar, now: Date) {
            self.calendar = calendar
            self.now = now
            let monthComps = calendar.dateComponents([.year, .month], from: now)
            self.monthStart = calendar.date(from: monthComps) ?? now
            self.monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
            self.thisWeekStart = calendar.startOfWeek(for: now)
            self.thisWeekEnd = calendar.date(byAdding: .day, value: 7, to: thisWeekStart) ?? now
            self.lastWeekStart = calendar.date(byAdding: .day, value: -7, to: thisWeekStart) ?? now
            self.lastWeekEnd = thisWeekStart
        }

        func containsMonth(_ date: Date) -> Bool { date >= monthStart && date < monthEnd }
        func containsThisWeek(_ date: Date) -> Bool { date >= thisWeekStart && date < thisWeekEnd }
        func containsLastWeek(_ date: Date) -> Bool { date >= lastWeekStart && date < lastWeekEnd }
    }

    private static func allEventPairs(from activities: [Activity]) -> [EventPair] {
        activities.flatMap { activity in
            (activity.events ?? []).map { EventPair(event: $0, activity: activity) }
        }
    }

    private static func isEmitting(_ pair: EventPair) -> Bool {
        !pair.activity.type.isCO2Reducing && pair.activity.co2Emission > 0
    }

    private static func emittingCO2(for pair: EventPair) -> Double {
        max(0, pair.event.quantity * pair.activity.co2Emission)
    }

    private static func offsetCO2(for pair: EventPair) -> Double {
        let value = pair.event.quantity * pair.activity.co2Emission
        return value < 0 ? abs(value) : 0
    }

    private static func averagePortionKg(for activity: Activity, pairs: [EventPair]) -> Double? {
        let foodPairs = pairs.filter { $0.activity.id == activity.id && $0.event.quantity > 0 }
        guard !foodPairs.isEmpty else { return nil }
        let total = foodPairs.reduce(0.0) { $0 + $1.event.quantity }
        return total / Double(foodPairs.count)
    }

    private static func consecutiveDayStreak(endingAt endDay: Date, from days: Set<Date>, calendar: Calendar) -> Int {
        var streak = 0
        var cursor = endDay
        while days.contains(cursor) {
            streak += 1
            guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
            cursor = previous
        }
        if streak == 0 {
            guard let yesterday = calendar.date(byAdding: .day, value: -1, to: endDay) else { return 0 }
            cursor = yesterday
            while days.contains(cursor) {
                streak += 1
                guard let previous = calendar.date(byAdding: .day, value: -1, to: cursor) else { break }
                cursor = previous
            }
        }
        return streak
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
