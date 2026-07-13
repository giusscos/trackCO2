//
//  GeneratedTip.swift
//  trackCO2
//

import Foundation

struct GeneratedTip: Identifiable {
    let id = UUID()
    var priority: Int
    var title: String
    var message: String
    var activity: Activity?
    var isPositive: Bool
}

enum ActivityCategory {
    case transport
    case food
    case energy
    case reduction
}

extension ActivityEmissionType {
    var category: ActivityCategory {
        switch self {
        case .car, .airplane, .boat, .motorcycle, .bus, .train, .walking, .biking:
            return .transport
        case .beef, .chicken, .vegetables, .rice, .dairy:
            return .food
        case .electricity:
            return .energy
        case .treePlanting, .recycling:
            return .reduction
        }
    }

    var isEmittingTransport: Bool {
        category == .transport && !isCO2Reducing
    }
}
