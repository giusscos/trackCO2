//
//  Activity.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import Foundation
import SwiftData

@Model
class Activity {
    var id: UUID = UUID()
    var type: ActivityType = ActivityType.car
    var name: String
    var activityDescription: String = ""
    var quantityUnit: QuantityUnit = QuantityUnit.km
    var emissionUnit: EmissionUnit = EmissionUnit.kgCO2e
    var co2Emission: Double = 0.0 // Calculated as quantity * emission factor
    var createdAt: Date = Date()
    
    @Relationship var events: [ActivityEvent] = []
    
    init(type: ActivityType = .car, name: String, activityDescription: String = "", quantityUnit: QuantityUnit = .km, emissionUnit: EmissionUnit = .kgCO2e, co2Emission: Double = 0.0, createdAt: Date = Date()) {
        self.type = type
        self.name = name
        self.activityDescription = activityDescription
        self.quantityUnit = quantityUnit
        self.emissionUnit = emissionUnit
        self.co2Emission = co2Emission
        self.createdAt = createdAt
    }
}

struct PredefinedActivity {
    let type: ActivityType
    let defaultName: String
    let emissionFactor: Double // kg CO2eq per unit (positive for emissions, negative for reductions)
    let quantityUnit: QuantityUnit
    let emissionUnit: EmissionUnit
}

let predefinedActivities: [ActivityType: PredefinedActivity] = [
    // Vehicles
    .car: PredefinedActivity(type: .car, defaultName: "Car Travel", emissionFactor: 0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
    .airplane: PredefinedActivity(type: .airplane, defaultName: "Airplane Flight", emissionFactor: 0.2, quantityUnit: .km, emissionUnit: .kgCO2e),
    .boat: PredefinedActivity(type: .boat, defaultName: "Boat Trip", emissionFactor: 0.1, quantityUnit: .km, emissionUnit: .kgCO2e),
    .motorcycle: PredefinedActivity(type: .motorcycle, defaultName: "Motorcycle Ride", emissionFactor: 0.1, quantityUnit: .km, emissionUnit: .kgCO2e),
    .bus: PredefinedActivity(type: .bus, defaultName: "Bus Travel", emissionFactor: 0.08, quantityUnit: .km, emissionUnit: .kgCO2e),
    .train: PredefinedActivity(type: .train, defaultName: "Train Travel", emissionFactor: 0.04, quantityUnit: .km, emissionUnit: .kgCO2e),
    
    // Foods
    .beef: PredefinedActivity(type: .beef, defaultName: "Beef Consumption", emissionFactor: 60.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
    .chicken: PredefinedActivity(type: .chicken, defaultName: "Chicken Consumption", emissionFactor: 6.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
    .vegetables: PredefinedActivity(type: .vegetables, defaultName: "Vegetable Consumption", emissionFactor: 1.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
    .rice: PredefinedActivity(type: .rice, defaultName: "Rice Consumption", emissionFactor: 4.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
    .dairy: PredefinedActivity(type: .dairy, defaultName: "Dairy Consumption", emissionFactor: 10.0, quantityUnit: .kg, emissionUnit: .kgCO2e),
    
    // Energy
    .electricity: PredefinedActivity(type: .electricity, defaultName: "Electricity Usage", emissionFactor: 0.53, quantityUnit: .kWh, emissionUnit: .kgCO2e),
    
    // CO2 Reduction
    .walking: PredefinedActivity(type: .walking, defaultName: "Walking", emissionFactor: -0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
    .biking: PredefinedActivity(type: .biking, defaultName: "Biking", emissionFactor: -0.15, quantityUnit: .km, emissionUnit: .kgCO2e),
    .treePlanting: PredefinedActivity(type: .treePlanting, defaultName: "Tree Planting", emissionFactor: -20.0, quantityUnit: .tree, emissionUnit: .kgCO2e),
    .recycling: PredefinedActivity(type: .recycling, defaultName: "Recycling", emissionFactor: -0.5, quantityUnit: .kg, emissionUnit: .kgCO2e)
]

enum EmissionUnit: String, CaseIterable, Codable {
    case kgCO2e = "kgCO2e"
    case gCO2e = "gCO2e"
    
    var id: String {
        self.rawValue
    }
}

enum QuantityUnit: String, CaseIterable, Codable {
    case km = "km"
    case kg = "kg"
    case kWh = "kWh"
    case tree = "tree"
    case steps = "steps"
    
    var id: String {
        self.rawValue
    }
}

enum ActivityType: String, CaseIterable, Identifiable, Codable {
    // CO2 In
    case car = "Car"
    case airplane = "Airplane"
    case boat = "Boat"
    case motorcycle = "Motorcycle"
    case bus = "Bus"
    case train = "Train"
    
    case beef = "Beef"
    case chicken = "Chicken"
    case vegetables = "Vegetables"
    case rice = "Rice"
    case dairy = "Dairy"
    
    case electricity = "Electricity"
    
    // CO2 Out
    case walking = "Walking"
    case biking = "Biking"
    case treePlanting = "Tree Planting"
    case recycling = "Recycling"
    
    var id: String { rawValue }
    
    var emoji: String {
        switch self {
        case .car: return "🚗"
        case .airplane: return "✈️"
        case .boat: return "⛵"
        case .motorcycle: return "🏍️"
        case .bus: return "🚌"
        case .train: return "🚆"
            
        case .beef: return "🥩"
        case .chicken: return "🍗"
        case .vegetables: return "🥕"
        case .rice: return "🍚"
        case .dairy: return "🧀"
            
        case .electricity: return "⚡️"
            
        case .walking: return "🚶"
        case .biking: return "🚲"
        case .treePlanting: return "🌳"
        case .recycling: return "♻️"
        }
    }
    
    var isCO2Reducing: Bool {
        switch self {
        case .walking, .biking, .treePlanting, .recycling:
            return true
        default:
            return false
        }
    }
    
    var quantityUnit: QuantityUnit {
        switch self {
        case .car, .airplane, .boat, .motorcycle, .bus, .train, .walking, .biking:
            return .km
        case .beef, .chicken, .vegetables, .rice, .dairy, .recycling:
            return .kg
        case .electricity:
            return .kWh
        case .treePlanting:
            return .tree
        }
    }
}
