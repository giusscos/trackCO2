//
//  WalkingRunningDistanceView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 15/07/25.
//

import SwiftUI
import Charts

struct WalkingRunningDistanceView: View {
    @State private var healthKitManager = HealthKitManager.shared
    
    private var walkingCompensationPerKm: Double {
        defaultActivities.first(where: { $0.type == .walking })?.co2Emission ?? 0.0
    }
    
    private func compensatedCO2(distanceMeters: Double) -> Double {
        let km = distanceMeters / 1000.0
        return km * walkingCompensationPerKm // kg CO2
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Step Distance")
                .font(.headline)
            
            Text(String(format: "%.2f km", healthKitManager.todayDistance / 1000.0))
                .font(.title2)
                .bold()
            
            Text(String(format: "%.2f kgCO2e", compensatedCO2(distanceMeters: healthKitManager.todayDistance)))
                .font(.caption2)
                .foregroundColor(.secondary)
            
            DistanceMiniGraph(data: healthKitManager.distancePerHour)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct DistanceMiniGraph: View {
    let data: [Double] // meters per hour
    
    var body: some View {
        Chart {
            ForEach(0..<24, id: \ .self) { hour in
                BarMark(
                    x: .value("Hour", hour),
                    y: .value("Distance", data[hour] / 1000.0), // km
                    width: 4
                )
                .clipShape(Capsule())
                .foregroundStyle(Color.blue)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: Array(0...23)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            AxisMarks(values: [0, 6, 12, 18, 23]) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisTick()
                    .foregroundStyle(Color.gray.opacity(0.5))
                AxisValueLabel() {
                    if let intVal = value.as(Int.self) {
                        switch intVal {
                        case 0: Text("00")
                        case 6: Text("06")
                        case 12: Text("12")
                        case 18: Text("18")
                        case 23: Text("23")
                        default: EmptyView()
                        }
                    }
                }
            }
        }
        .frame(height: 60)
    }
}

#Preview {
    WalkingRunningDistanceView()
}
