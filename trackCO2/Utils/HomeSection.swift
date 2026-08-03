//
//  HomeSection.swift
//  trackCO2
//

import Foundation
import SwiftUI

/// Reorderable blocks on the Summary (Home) screen.
enum HomeSection: String, CaseIterable, Identifiable, Codable, Hashable {
    case mascot
    case co2Chart
    case weather
    case healthKit
    case balance
    case budgetStreak
    case insights
    case trends
    case calendar

    var id: String { rawValue }

    var title: LocalizedStringKey {
        switch self {
        case .mascot: return "Claud"
        case .co2Chart: return "This week CO2"
        case .weather: return "Weather"
        case .healthKit: return "Steps & Distance"
        case .balance: return "Compensation & Consumption"
        case .budgetStreak: return "Budget & Streak"
        case .insights: return "Most used & Tips"
        case .trends: return "Trends"
        case .calendar: return "Activity Calendar"
        }
    }

    var systemImage: String {
        switch self {
        case .mascot: return "cloud.fill"
        case .co2Chart: return "chart.bar.fill"
        case .weather: return "cloud.sun.fill"
        case .healthKit: return "figure.walk"
        case .balance: return "arrow.left.arrow.right"
        case .budgetStreak: return "target"
        case .insights: return "lightbulb.fill"
        case .trends: return "chart.line.uptrend.xyaxis"
        case .calendar: return "calendar"
        }
    }

    static let defaultOrder: [HomeSection] = Array(HomeSection.allCases)

    static var defaultOrderRaw: String {
        defaultOrder.map(\.rawValue).joined(separator: ",")
    }

    static func resolvedOrder(from raw: String) -> [HomeSection] {
        resolvedOrder(from: raw.split(separator: ",").map(String.init))
    }

    static func resolvedOrder(from raw: [String]) -> [HomeSection] {
        var seen = Set<HomeSection>()
        var order: [HomeSection] = []
        for id in raw {
            guard let section = HomeSection(rawValue: id), !seen.contains(section) else { continue }
            order.append(section)
            seen.insert(section)
        }
        for section in defaultOrder where !seen.contains(section) {
            order.append(section)
        }
        return order
    }

    static func encode(_ order: [HomeSection]) -> String {
        order.map(\.rawValue).joined(separator: ",")
    }
}
