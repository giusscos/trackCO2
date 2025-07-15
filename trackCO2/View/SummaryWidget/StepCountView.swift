//
//  StepCountView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 15/07/25.
//

import SwiftUI
import Charts

struct StepCountView: View {
    @State private var healthKitManager = HealthKitManager.shared
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Step Count")
                .font(.headline)
            
            Text("\(Int(healthKitManager.todaySteps))")
                .font(.title)
                .bold()
                
            StepsMiniGraph(data: healthKitManager.stepsPerHour)
                .frame(maxHeight: .infinity, alignment: .bottom)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StepsMiniGraph: View {
    let data: [Double]
        
    var body: some View {
        Chart {
            ForEach(0..<24, id: \ .self) { hour in
                BarMark(
                    x: .value("Hour", hour),
                    y: .value("Steps", data[hour]),
                    width: 4
                )
                .clipShape(Capsule())
                .foregroundStyle(Color.green)
            }
        }
        .chartYAxis(.hidden)
        .chartXAxis {
            AxisMarks(values: Array(0...23)) { value in
                AxisGridLine()
                    .foregroundStyle(Color.gray.opacity(0.5))
            }
            // Major grid lines and labels (darker)
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
    StepCountView()
}
