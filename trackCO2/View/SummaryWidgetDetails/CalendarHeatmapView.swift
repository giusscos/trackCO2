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
                    ForEach(CO2DayStyle.legendSamples, id: \.self) { v in
                        let style = CO2DayStyle.style(for: v)
                        ZStack {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(style.color)
                            if let glyph = style.glyph {
                                Text(glyph)
                                    .font(.system(size: 8))
                            }
                        }
                        .frame(width: 18, height: 18)
                        .accessibilityLabel(style.accessibilityLabel)
                    }
                    Text("Worse")
                        .font(.caption2).foregroundStyle(.secondary)
                    Spacer()
                    RoundedRectangle(cornerRadius: 3)
                        .fill(CO2DayStyle.style(for: nil).color)
                        .frame(width: 18, height: 18)
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
            Label("Monthly Summary", systemImage: totalNet <= 0 ? "leaf.fill" : "cloud.fill")
                .font(.headline)
                .foregroundStyle(totalNet <= 0 ? .green : .orange)

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
        let style = CO2DayStyle.style(for: isFuture ? nil : net)

        ZStack {
            RoundedRectangle(cornerRadius: 6)
                .fill(isFuture ? Color.secondary.opacity(0.05) : style.color)

            VStack(spacing: 1) {
                Text("\(calendar.component(.day, from: date))")
                    .font(.caption2)
                    .fontWeight(isToday ? .bold : .regular)
                    .foregroundStyle(isFuture ? Color.secondary.opacity(0.4) : .primary)

                if !isFuture, let glyph = style.glyph, net != nil {
                    Text(glyph)
                        .font(.system(size: 9))
                }
            }
        }
        .aspectRatio(1, contentMode: .fill)
        .overlay {
            if isToday {
                RoundedRectangle(cornerRadius: 6)
                    .stroke(Color.green.opacity(0.85), lineWidth: 2)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(dayAccessibilityLabel(isToday: isToday, isFuture: isFuture, style: style))
    }

    private func dayAccessibilityLabel(isToday: Bool, isFuture: Bool, style: CO2DayStyle) -> String {
        let day = calendar.component(.day, from: date)
        if isFuture { return "\(day), future" }
        var parts = ["\(day)", style.accessibilityLabel]
        if isToday { parts.append(String(localized: "Today")) }
        return parts.joined(separator: ", ")
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

#Preview {
    NavigationStack { CalendarHeatmapView() }
}
