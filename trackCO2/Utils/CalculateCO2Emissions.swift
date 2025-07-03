//
//  CalculateCO2Emissions.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import Foundation

func calculateCO2Totals(activities: [Activity]) -> (consumption: Double, compensation: Double) {
    var totalConsumption: Double = 0.0
    var totalCompensation: Double = 0.0
    
    for activity in activities {
        guard let events = activity.events else { continue }
        for event in events {
            let emission = event.quantity * activity.co2Emission
            
            if emission > .zero {
                totalConsumption += emission
            } else if emission < .zero {
                totalCompensation += abs(emission)
            }
        }
    }
    
    return (consumption: totalConsumption, compensation: totalCompensation)
}

func findMostUsedActivity(activities: [Activity]) -> Activity? {
    guard !activities.isEmpty else { return nil }
    return activities.max(by: { ($0.events?.count ?? 0) < ($1.events?.count ?? 0) })
}
