//
//  WeatherManager.swift
//  trackCO2
//

import CoreLocation
import WeatherKit
import SwiftUI

@Observable
final class WeatherManager {
    static let shared = WeatherManager()

    private let service = WeatherService.shared

    private(set) var suggestion: WalkingSuggestion = .unknown
    private(set) var conditionDescription: String = ""
    private(set) var isLoading = false
    private(set) var dailyForecast: [DayForecast] = []
    private(set) var isTodayHighTemperature = false
    private(set) var isTodayLowTemperature = false

    enum WalkingSuggestion {
        case walk
        case caution
        case avoid
        case unknown
    }

    struct DayForecast: Identifiable {
        let id: Date
        let date: Date
        let condition: WeatherCondition
        let symbolName: String
        let lowTemperature: Measurement<UnitTemperature>
        let highTemperature: Measurement<UnitTemperature>
        let suggestion: WalkingSuggestion
        let isHighTemperature: Bool
        let isLowTemperature: Bool
    }

    private static let highTemperatureThresholdCelsius = 28.0
    private static let lowTemperatureThresholdCelsius = 5.0

    private static let badConditions: Set<WeatherCondition> = [
        .haze, .smoky, .blowingDust, .foggy,
        .heavyRain, .heavySnow,
        .hurricane, .tropicalStorm,
        .isolatedThunderstorms, .scatteredThunderstorms,
        .strongStorms, .thunderstorms,
        .blizzard, .blowingSnow,
        .freezingDrizzle, .freezingRain, .wintryMix, .sleet,
        .frigid, .hot, .hail
    ]

    private static let marginalConditions: Set<WeatherCondition> = [
        .drizzle, .mostlyCloudy, .cloudy,
        .sunFlurries, .flurries, .snow, .breezy, .windy
    ]

    private init() {}

    func refresh(using locationManager: LocationManager) async {
        guard locationManager.isAuthorized else { return }

        guard let location = locationManager.lastLocation else {
            locationManager.startUpdatingIfAuthorized()
            return
        }
        await fetchWeather(for: location)
    }

    @MainActor
    private func fetchWeather(for location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let (current, daily) = try await service.weather(for: location, including: .current, .daily)

            let condition = current.condition
            conditionDescription = condition.description
            suggestion = Self.suggestion(for: condition)

            dailyForecast = daily.forecast.prefix(7).map { day in
                DayForecast(
                    id: day.date,
                    date: day.date,
                    condition: day.condition,
                    symbolName: day.symbolName,
                    lowTemperature: day.lowTemperature,
                    highTemperature: day.highTemperature,
                    suggestion: Self.suggestion(for: day.condition),
                    isHighTemperature: Self.isHighTemperature(day.highTemperature),
                    isLowTemperature: Self.isLowTemperature(day.lowTemperature)
                )
            }
            isTodayHighTemperature = daily.forecast.first.map { Self.isHighTemperature($0.highTemperature) } ?? false
            isTodayLowTemperature = daily.forecast.first.map { Self.isLowTemperature($0.lowTemperature) } ?? false
        } catch {
            print("[WeatherManager] fetch failed: \(error)")
            suggestion = .unknown
            dailyForecast = []
            isTodayHighTemperature = false
            isTodayLowTemperature = false
        }
    }

    static func isHighTemperature(_ temperature: Measurement<UnitTemperature>) -> Bool {
        temperature.converted(to: .celsius).value >= highTemperatureThresholdCelsius
    }

    static func isLowTemperature(_ temperature: Measurement<UnitTemperature>) -> Bool {
        temperature.converted(to: .celsius).value <= lowTemperatureThresholdCelsius
    }

    static func showsSunProtectionTip(for suggestion: WalkingSuggestion, isHighTemperature: Bool) -> Bool {
        isHighTemperature && (suggestion == .walk || suggestion == .caution)
    }

    static func showsColdWeatherTip(for suggestion: WalkingSuggestion, isLowTemperature: Bool) -> Bool {
        isLowTemperature && (suggestion == .walk || suggestion == .caution)
    }

    private static func suggestion(for condition: WeatherCondition) -> WalkingSuggestion {
        if badConditions.contains(condition) {
            return .avoid
        } else if marginalConditions.contains(condition) {
            return .caution
        } else {
            return .walk
        }
    }
}
