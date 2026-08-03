//
//  CalendarHeatmapView.swift
//  trackCO2
//

import SwiftData
import SwiftUI

struct CalendarHeatmapView: View {
    @Query var activities: [Activity]
    @State private var monthOffset: Int = 0

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    private var displayMonth: Date {
        calendar.date(byAdding: .month, value: monthOffset, to: Date()) ?? Date()
    }

    private var monthTitle: String {
        displayMonth.formatted(.dateTime.month(.wide).year())
    }

    private var daysInMonth: [Date?] {
        guard let interval = calendar.dateInterval(of: .month, for: displayMonth),
              let range = calendar.range(of: .day, in: .month, for: displayMonth) else { return [] }
        let start = interval.start
        let weekday = (calendar.component(.weekday, from: start) - calendar.firstWeekday + 7) % 7
        var days: [Date?] = Array(repeating: nil, count: weekday)
        for i in 0..<range.count {
            days.append(calendar.date(byAdding: .day, value: i, to: start))
        }
        return days
    }

    private var weekdayHeaders: [String] {
        let symbols = calendar.shortWeekdaySymbols
        let firstIndex = calendar.firstWeekday - 1
        return (symbols[firstIndex...] + symbols[..<firstIndex]).map { String($0.prefix(2)) }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Month navigation
                HStack {
                    Button {
                        withAnimation(.spring(duration: 0.3)) { monthOffset -= 1 }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.title3)
                    }

                    Text(monthTitle)
                        .font(.title3).fontWeight(.semibold)
                        .frame(maxWidth: .infinity)

                    Button {
                        withAnimation(.spring(duration: 0.3)) { monthOffset = min(monthOffset + 1, 0) }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.title3)
                    }
                    .disabled(monthOffset == 0)
                }

                // Weekday headers
                HStack(spacing: 4) {
                    ForEach(weekdayHeaders, id: \.self) { symbol in
                        Text(symbol)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }

                // Day grid
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(Array(daysInMonth.enumerated()), id: \.offset) { _, date in
                        if let date {
                            DayCell(
                                date: date,
                                net: calculateDailyNetCO2(activities: activities, for: date)
                            )
                        } else {
                            Color.clear.aspectRatio(1, contentMode: .fill)
                        }
                    }
                }

                // Legend
                HStack(spacing: 6) {
                    Text("Better")
                        .font(.caption2).foregroundStyle(.secondary)
                    ForEach([-2.0, -0.5, 0.0, 5.0, 15.0], id: \.self) { v in
                        RoundedRectangle(cornerRadius: 3)
                            .fill(dayColor(net: v))
                            .frame(width: 16, height: 16)
                    }
                    Text("Worse")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    Circle()
                        .fill(Color.secondary.opacity(0.15))
                        .frame(width: 16, height: 16)
                    Text("No data")
                        .font(.caption2).foregroundStyle(.secondary)
                }

                // Monthly summary
                monthSummary
            }
            .padding()
        }
        .navigationTitle("Activity Calendar")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var monthSummary: some View {
        let allDays = daysInMonth.compactMap { $0 }
        let netValues = allDays.compactMap { calculateDailyNetCO2(activities: activities, for: $0) }
        let totalNet = netValues.reduce(0, +)
        let loggedDays = netValues.count

        return VStack(alignment: .leading, spacing: 12) {
            Text("Monthly Summary")
                .font(.headline)

            HStack(spacing: 12) {
                SummaryTile(title: "Days logged", value: "\(loggedDays)", color: .blue)
                SummaryTile(
                    title: "Net CO₂",
                    value: "\(String(format: "%+.1f", totalNet)) kg",
                    color: totalNet <= 0 ? .green : .red
                )
                SummaryTile(
                    title: "Avg/day",
                    value: loggedDays > 0 ? "\(String(format: "%.1f", totalNet / Double(loggedDays))) kg" : "—",
                    color: .secondary
                )
            }
        }
        .padding()
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct DayCell: View {
    let date: Date
    let net: Double?

    private let calendar = Calendar.current

    var body: some View {
        let isToday = calendar.isDateInToday(date)
        let isFuture = date > Date()

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isFuture ? Color.secondary.opacity(0.05) : dayColor(net: net))

            Text("\(calendar.component(.day, from: date))")
                .font(.caption2)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isFuture ? Color.secondary.opacity(0.4) : .primary)
        }
        .aspectRatio(1, contentMode: .fill)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.accentColor, lineWidth: 2)
            }
        }
    }
}

private struct SummaryTile: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption2).foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline).fontWeight(.semibold)
                .foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private func dayColor(net: Double?) -> Color {
    guard let net else { return Color.secondary.opacity(0.15) }
    if net < -5  { return Color.green.opacity(0.85) }
    if net < 0   { return Color.green.opacity(0.40) }
    if net < 5   { return Color.secondary.opacity(0.15) }
    if net < 15  { return Color.orange.opacity(0.45) }
    return Color.red.opacity(0.70)
}

#Preview {
    NavigationStack { CalendarHeatmapView() }
}
