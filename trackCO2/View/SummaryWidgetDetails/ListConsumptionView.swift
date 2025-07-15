//
//  ListConsumptionView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 03/07/25.
//

import SwiftData
import SwiftUI
import Charts

struct ListConsumptionView: View {
    @Environment(\.modelContext) var modelContext
    
    enum TimeRange: String, CaseIterable, Identifiable {
        case all = "All"
        case day = "D"
        case week = "W"
        case month = "M"
        case year = "Y"
        var id: String { rawValue }
        var label: String {
            switch self {
            case .all: return "All"
            case .day: return "Day"
            case .week: return "Week"
            case .month: return "Month"
            case .year: return "Year"
            }
        }
    }
    
    @State private var selectedRange: TimeRange = .week
    @State private var rangeOffset: Int = 0
    
    @Query(sort: [SortDescriptor(\ActivityEvent.createdAt, order: .reverse)]) var allEvents: [ActivityEvent]
    
    var filteredEvents: [ActivityEvent] {
        if selectedRange == .all {
            return allEvents.filter { $0.activity?.type.isCO2Reducing == false }
        }
        let (start, end) = dateRange
        return allEvents.filter { ($0.activity?.type.isCO2Reducing == false) && $0.createdAt >= start && $0.createdAt < end }
    }
    
    var dateRange: (Date, Date) {
        let calendar = Calendar.current
        let now = Date()
        switch selectedRange {
        case .all:
            return (Date.distantPast, Date.distantFuture)
        case .day:
            let day = calendar.date(byAdding: .day, value: rangeOffset, to: calendar.startOfDay(for: now)) ?? now
            let nextDay = calendar.date(byAdding: .day, value: 1, to: day) ?? now
            return (day, nextDay)
        case .week:
            let weekStart = calendar.date(byAdding: .weekOfYear, value: rangeOffset, to: calendar.startOfWeek(for: now)) ?? now
            let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart) ?? now
            return (weekStart, weekEnd)
        case .month:
            let comps = calendar.dateComponents([.year, .month], from: now)
            let thisMonth = calendar.date(from: comps) ?? now
            let monthStart = calendar.date(byAdding: .month, value: rangeOffset, to: thisMonth) ?? now
            let monthEnd = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? now
            return (monthStart, monthEnd)
        case .year:
            let comps = calendar.dateComponents([.year], from: now)
            let thisYear = calendar.date(from: comps) ?? now
            let yearStart = calendar.date(byAdding: .year, value: rangeOffset, to: thisYear) ?? now
            let yearEnd = calendar.date(byAdding: .year, value: 1, to: yearStart) ?? now
            return (yearStart, yearEnd)
        }
    }
    
    var chartData: [CO2Data] {
        var dict: [String: Double] = [:]
        for event in filteredEvents {
            if let activity = event.activity {
                dict[activity.name, default: 0] += event.quantity * activity.co2Emission
            }
        }
        return dict.map { CO2Data(type: $0.key, count: $0.value) }
    }
    
    var rangeLabel: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        let (start, end) = dateRange
        let endAdj = Calendar.current.date(byAdding: .day, value: -1, to: end) ?? end
        return "\(formatter.string(from: start)) - \(formatter.string(from: endAdj))"
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Range", selection: $selectedRange.animation()) {
                ForEach(TimeRange.allCases) { range in
                    Text(range.label).tag(range)
                }
            }
            .pickerStyle(.segmented)
            .padding(.bottom, 4)
            
            HStack {
                if selectedRange != .all {
                    Button(action: { withAnimation { rangeOffset -= 1 } }) {
                        Image(systemName: "chevron.left")
                    }
                }
                Text(rangeLabel)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if selectedRange != .all {
                    Button(action: { withAnimation { rangeOffset += 1 } }) {
                        Image(systemName: "chevron.right")
                    }
                }
            }
            .padding(.bottom, 4)
            
            if chartData.isEmpty {
                Text("No data for this range.")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, minHeight: 120)
            } else {
                Chart {
                    ForEach(chartData) { data in
                        BarMark(
                            x: .value("Activity", data.type),
                            y: .value("CO2", data.count),
                            width: 16
                        )
                        .clipShape(Capsule())
                    }
                }
                .frame(minHeight: 120)
            }
            
            List {
                ForEach(filteredEvents) { event in
                    HStack {
                        if let activity = event.activity {
                            Text(activity.type.emoji)
                            VStack(alignment: .leading) {
                                Text(activity.name)
                                    .font(.headline)
                                Text("\(event.quantity, specifier: "%.2f") \(activity.quantityUnit.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                Text("\(event.quantity * activity.co2Emission, specifier: "%.2f") \(activity.emissionUnit.rawValue)")
                                    .font(.subheadline)
                                    .fontWeight(.medium)
                                    .foregroundStyle(.red)
                            }
                        } else {
                            Text("Unknown Activity")
                        }
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteEvent(event)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Consumption Events")
        .padding()
    }
    
    func deleteEvent(_ event: ActivityEvent) {
        modelContext.delete(event)
    }
}

private extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}

#Preview {
    ListConsumptionView()
}
