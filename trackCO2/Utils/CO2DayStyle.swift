//
//  CO2DayStyle.swift
//  trackCO2
//

import SwiftUI

struct CO2DayStyle {
    let color: Color
    let glyph: String?
    let accessibilityLabel: String

    static func style(for net: Double?) -> CO2DayStyle {
        guard let net else {
            return CO2DayStyle(
                color: Color.secondary.opacity(0.12),
                glyph: nil,
                accessibilityLabel: String(localized: "No data")
            )
        }

        if net < -5 {
            return CO2DayStyle(
                color: Color.green.opacity(0.85),
                glyph: "🌳",
                accessibilityLabel: String(localized: "Strongly reducing")
            )
        }
        if net < 0 {
            return CO2DayStyle(
                color: Color.green.opacity(0.40),
                glyph: "🌿",
                accessibilityLabel: String(localized: "Reducing")
            )
        }
        if net < 5 {
            return CO2DayStyle(
                color: Color.secondary.opacity(0.15),
                glyph: "🌱",
                accessibilityLabel: String(localized: "Near zero")
            )
        }
        if net < 15 {
            return CO2DayStyle(
                color: Color.orange.opacity(0.45),
                glyph: "☁️",
                accessibilityLabel: String(localized: "Elevated emissions")
            )
        }
        return CO2DayStyle(
            color: Color.red.opacity(0.70),
            glyph: "💨",
            accessibilityLabel: String(localized: "High emissions")
        )
    }

    /// Legend sample values from better → worse (for shared color/glyph demos).
    static let legendSamples: [Double] = [-6, -0.5, 2, 8, 16]
}
