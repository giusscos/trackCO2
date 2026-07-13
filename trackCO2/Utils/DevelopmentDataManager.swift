//
//  DevelopmentDataManager.swift
//  trackCO2
//

import Foundation
import SwiftData

#if DEBUG

enum DevelopmentDataManager {
    static func eraseAllData(in context: ModelContext) throws {
        try context.delete(model: Activity.self)
        try context.delete(model: FavoritePlace.self)
        try context.save()
    }

    static func generateMockData(in context: ModelContext) throws {
        let activities = try ensureDefaultActivities(in: context)
        try insertMockEvents(for: activities, in: context)
        try insertMockFavoritePlaces(in: context)
        try context.save()
    }

    private static func ensureDefaultActivities(in context: ModelContext) throws -> [ActivityEmissionType: Activity] {
        let existing = try context.fetch(FetchDescriptor<Activity>())
        var byType = Dictionary(uniqueKeysWithValues: existing.map { ($0.type, $0) })

        for template in defaultActivities where byType[template.type] == nil {
            let activity = Activity(
                type: template.type,
                name: template.type.defaultNameKey,
                activityDescription: template.activityDescription,
                quantityUnit: template.quantityUnit,
                emissionUnit: template.emissionUnit,
                co2Emission: template.co2Emission
            )
            context.insert(activity)
            byType[template.type] = activity
        }

        return byType
    }

    private static func insertMockEvents(for activities: [ActivityEmissionType: Activity], in context: ModelContext) throws {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        let eventPlans: [(ActivityEmissionType, Int, ClosedRange<Double>)] = [
            (.car, 1, 8...35),
            (.walking, 1, 1...6),
            (.biking, 2, 2...12),
            (.train, 3, 10...45),
            (.bus, 3, 3...15),
            (.beef, 5, 0.2...0.6),
            (.vegetables, 2, 0.3...1.2),
            (.electricity, 7, 5...18),
            (.treePlanting, 14, 1...3),
            (.recycling, 4, 1...5),
        ]

        for dayOffset in 0..<56 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            for (type, interval, quantityRange) in eventPlans {
                guard dayOffset % interval == 0 else { continue }
                guard let activity = activities[type] else { continue }

                let event = ActivityEvent(
                    quantity: Double.random(in: quantityRange),
                    activity: activity
                )
                event.createdAt = calendar.date(
                    bySettingHour: Int.random(in: 8...20),
                    minute: Int.random(in: 0...59),
                    second: 0,
                    of: date
                ) ?? date
                context.insert(event)
            }
        }
    }

    private static func insertMockFavoritePlaces(in context: ModelContext) throws {
        let existing = try context.fetch(FetchDescriptor<FavoritePlace>())
        guard existing.isEmpty else { return }

        let places: [(String, String, Double, Double)] = [
            ("Home", "123 Green Street", 37.7749, -122.4194),
            ("Office", "Market Street", 37.7896, -122.4010),
            ("Grocery Store", "Mission District", 37.7599, -122.4148),
            ("Gym", "Fitness Center", 37.7849, -122.4094),
        ]

        for (name, subtitle, latitude, longitude) in places {
            context.insert(FavoritePlace(
                name: name,
                subtitle: subtitle,
                latitude: latitude,
                longitude: longitude
            ))
        }
    }
}

#endif
