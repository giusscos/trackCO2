//
//  Activity.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 29/06/25.
//

import Foundation
import SwiftData

var defaultActivities: [Activity] {
    [
        // Vehicles
        Activity(type: .car, name: ActivityEmissionType.car.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.15),
        Activity(type: .airplane, name: ActivityEmissionType.airplane.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.2),
        Activity(type: .boat, name: ActivityEmissionType.boat.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
        Activity(type: .motorcycle, name: ActivityEmissionType.motorcycle.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.1),
        Activity(type: .bus, name: ActivityEmissionType.bus.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.08),
        Activity(type: .train, name: ActivityEmissionType.train.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: 0.04),
        
        // Foods
        Activity(type: .beef, name: ActivityEmissionType.beef.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 60.0),
        Activity(type: .chicken, name: ActivityEmissionType.chicken.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 6.0),
        Activity(type: .vegetables, name: ActivityEmissionType.vegetables.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 1.0),
        Activity(type: .rice, name: ActivityEmissionType.rice.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 4.0),
        Activity(type: .dairy, name: ActivityEmissionType.dairy.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: 10.0),
        
        // Energy
        Activity(type: .electricity, name: ActivityEmissionType.electricity.localizedDefaultName, quantityUnit: .kWh, emissionUnit: .kgCO2e, co2Emission: 0.53),
        
        // CO2 Reduction
        Activity(type: .walking, name: ActivityEmissionType.walking.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
        Activity(type: .biking, name: ActivityEmissionType.biking.localizedDefaultName, quantityUnit: .km, emissionUnit: .kgCO2e, co2Emission: -0.15),
        Activity(type: .treePlanting, name: ActivityEmissionType.treePlanting.localizedDefaultName, quantityUnit: .tree, emissionUnit: .kgCO2e, co2Emission: -20.0),
        Activity(type: .recycling, name: ActivityEmissionType.recycling.localizedDefaultName, quantityUnit: .kg, emissionUnit: .kgCO2e, co2Emission: -0.5)
    ]
}

@Model
class Activity {
    var id: UUID = UUID()
    var type: ActivityEmissionType = ActivityEmissionType.car
    var name: String = ""
    var activityDescription: String = ""
    var quantityUnit: QuantityUnit = QuantityUnit.km
    var emissionUnit: EmissionUnit = EmissionUnit.kgCO2e
    var co2Emission: Double = 0.0 // Calculated as quantity * emission factor
    var createdAt: Date = Date()
    
    @Relationship(deleteRule: .cascade) var events: [ActivityEvent]?
    
    init(type: ActivityEmissionType = .car, name: String, activityDescription: String = "", quantityUnit: QuantityUnit = .km, emissionUnit: EmissionUnit = .kgCO2e, co2Emission: Double = 0.0, createdAt: Date = Date()) {
        self.type = type
        self.name = name
        self.activityDescription = activityDescription
        self.quantityUnit = quantityUnit
        self.emissionUnit = emissionUnit
        self.co2Emission = co2Emission
        self.createdAt = createdAt
    }
    
    /// Localized name for display. Default activities are stored by key and resolved at runtime.
    var displayName: String {
        if ActivityEmissionType.isKnownDefaultName(name, for: type) {
            return type.localizedDefaultName
        }
        return name
    }
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

enum ActivityEmissionType: String, CaseIterable, Identifiable, Codable {
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
    
    /// English localization key used as the canonical stored name for default activities.
    var defaultNameKey: String {
        switch self {
        case .car: return "Car Travel"
        case .airplane: return "Airplane Flight"
        case .boat: return "Boat Trip"
        case .motorcycle: return "Motorcycle Ride"
        case .bus: return "Bus Travel"
        case .train: return "Train Travel"
        case .beef: return "Beef Consumption"
        case .chicken: return "Chicken Consumption"
        case .vegetables: return "Vegetable Consumption"
        case .rice: return "Rice Consumption"
        case .dairy: return "Dairy Consumption"
        case .electricity: return "Electricity Usage"
        case .walking: return "Walking"
        case .biking: return "Biking"
        case .treePlanting: return "Tree Planting"
        case .recycling: return "Recycling"
        }
    }
    
    var localizedDefaultName: String {
        String(localized: String.LocalizationValue(defaultNameKey))
    }
    
    private static let supportedLocales = ["en", "en-GB", "en-CA", "de", "es", "fr", "it", "nb", "nl", "pt", "pt-BR", "sv"]
    
    static func isKnownDefaultName(_ name: String, for type: ActivityEmissionType) -> Bool {
        if name == type.defaultNameKey { return true }
        for locale in supportedLocales {
            guard let path = Bundle.main.path(forResource: locale, ofType: "lproj"),
                  let bundle = Bundle(path: path) else { continue }
            let localized = bundle.localizedString(forKey: type.defaultNameKey, value: nil, table: nil)
            if localized == name { return true }
        }
        return false
    }
}
