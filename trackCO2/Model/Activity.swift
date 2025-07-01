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
//    var quantity: Double = 0.0 // e.g., km, kg, kWh, trees
    var quantityUnit: QuantityUnit = QuantityUnit.km
    var emissionUnit: EmissionUnit = EmissionUnit.kgCO2e
    var co2Emission: Double = 0.0 // Calculated as quantity * emission factor
    var createdAt: Date = Date()
    
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
