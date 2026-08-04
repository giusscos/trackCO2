//
//  LogActivityIntent.swift
//  trackCO2
//

import AppIntents
import SwiftData

// MARK: - Activity Type Enum for Siri

enum ActivityTypeAppEnum: String, AppEnum {
    case walking, biking, car, train, bus, treePlanting, recycling, solarEnergy

    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Activity Type"
    static var caseDisplayRepresentations: [ActivityTypeAppEnum: DisplayRepresentation] = [
        .walking:     "🚶 Walking",
        .biking:      "🚲 Biking",
        .car:         "🚗 Car",
        .train:       "🚆 Train",
        .bus:         "🚌 Bus",
        .treePlanting: "🌳 Tree Planting",
        .recycling:   "♻️ Recycling",
        .solarEnergy: "☀️ Solar Energy",
    ]

    var activityType: ActivityEmissionType {
        switch self {
        case .walking:      return .walking
        case .biking:       return .biking
        case .car:          return .car
        case .train:        return .train
        case .bus:          return .bus
        case .treePlanting: return .treePlanting
        case .recycling:    return .recycling
        case .solarEnergy:  return .solarEnergy
        }
    }
}

// MARK: - Model Actor for thread-safe SwiftData access

@ModelActor
actor ActivityLogger {
    enum LogError: Error { case activityNotFound }

    func log(type: ActivityEmissionType, quantity: Double) throws -> (emission: Double, unit: String, name: String) {
        let all = try modelContext.fetch(FetchDescriptor<Activity>())
        guard let activity = all.first(where: { $0.type == type }) else {
            throw LogError.activityNotFound
        }
        let event = ActivityEvent(quantity: quantity, activity: activity)
        modelContext.insert(event)
        try modelContext.save()
        return (quantity * activity.co2Emission, activity.quantityUnit.rawValue, activity.displayName)
    }
}

// MARK: - Log Activity Intent

struct LogActivityIntent: AppIntent {
    static var title: LocalizedStringResource = "Log CO₂ Activity"
    static var description = IntentDescription("Log a CO₂ activity directly from Shortcuts.")
    static var openAppWhenRun: Bool = false

    @Parameter(title: "Activity Type")
    var activityType: ActivityTypeAppEnum

    @Parameter(title: "Quantity")
    var quantity: Double

    func perform() async throws -> some ProvidesDialog {
        let schema = Schema([Activity.self, FavoritePlace.self])
        let container = try ModelContainer(for: schema)
        let logger = ActivityLogger(modelContainer: container)

        do {
            let result = try await logger.log(type: activityType.activityType, quantity: quantity)
            let sign = result.emission < 0 ? "saving" : "emitting"
            let abs = String(format: "%.2f", Swift.abs(result.emission))
            let qty = String(format: "%.1f", quantity)
            return .result(dialog: "Logged \(qty) \(result.unit) of \(result.name), \(sign) \(abs) kg CO₂.")
        } catch ActivityLogger.LogError.activityNotFound {
            return .result(dialog: "Activity not found. Please add it in the app first.")
        }
    }
}

// MARK: - Shortcuts App

struct trackCO2Shortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: LogActivityIntent(),
            phrases: [
                "Log \(\.$activityType) in \(.applicationName)",
                "Record \(\.$activityType) in \(.applicationName)",
            ],
            shortTitle: "Log Activity",
            systemImageName: "leaf.fill"
        )
    }
}
