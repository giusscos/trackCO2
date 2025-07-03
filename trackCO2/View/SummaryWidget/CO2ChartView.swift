//
//  CO2ChartView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 02/07/25.
//

import Charts
import SwiftData
import SwiftUI

struct CO2Data: Identifiable {
    var type: String
    var count: Double
    var id = UUID()
}

struct CO2ChartView: View {
    @Query var activities: [Activity]
    @State private var weekOffset: Int = 0
    
    // Helper to get the start of the week for a given date
    func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    // Helper to get the end of the week for a given date
    func endOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let start = startOfWeek(for: date)
        return calendar.date(byAdding: .day, value: 7, to: start) ?? date
    }
    
    var weekRange: (start: Date, end: Date) {
        let calendar = Calendar.current
        let now = Date()
        let thisWeekStart = startOfWeek(for: now)
        let weekStart = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: thisWeekStart) ?? thisWeekStart
        let weekEnd = endOfWeek(for: weekStart)
        return (weekStart, weekEnd)
    }
    
    var data: [CO2Data] {
        activities.compactMap { activity in
            let total = (activity.events ?? []).filter { event in
                let date = event.createdAt
                return date >= weekRange.start && date < weekRange.end
            }.reduce(0.0) { $0 + ($1.quantity * activity.co2Emission) }
            return (activity.events?.contains { event in
                let date = event.createdAt
                return date >= weekRange.start && date < weekRange.end
            } == true) ? CO2Data(type: activity.name, count: total) : nil
        }
    }
    
    var weekLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let start = weekRange.start
        let end = Calendar.current.date(byAdding: .day, value: 6, to: start) ?? weekRange.end
        return "Week: \(formatter.string(from: start)) - \(formatter.string(from: end))"
    }
    
    var body: some View {
        VStack(alignment: .leading)  {
            HStack {
                Text("This week CO2")
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                NavigationLink {
                    ListAllActivityEventView()
                } label: {
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .font(.headline)
                }
            }
            .font(.title2)
            
            Text(weekLabel)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.bottom, 4)
            
            if data.isEmpty {
                Text("No data for this week.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart {
                    ForEach(data) { data in
                        BarMark(
                            x: .value("Shape Type", data.type),
                            y: .value("Total Count", data.count),
                            width: 24
                        )
                        .clipShape(Capsule())
                    }
                }
                .frame(minHeight: 120)
                .gesture(
                    DragGesture(minimumDistance: 20)
                        .onEnded { value in
                            if value.translation.width < -20 {
                                // Next week
                                weekOffset += 1
                            } else if value.translation.width > 20 {
                                // Previous week
                                weekOffset -= 1
                            }
                        }
                )
            }
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    CO2ChartView()
}
