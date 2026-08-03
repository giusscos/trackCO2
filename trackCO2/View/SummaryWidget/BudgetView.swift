//
//  BudgetView.swift
//  trackCO2
//

import SwiftData
import SwiftUI

struct BudgetView: View {
    @AppStorage("weeklyBudgetKg") private var weeklyBudgetKg: Double = 115.0
    @Query var activities: [Activity]

    var weeklyConsumption: Double {
        let calendar = Calendar.current
        let now = Date()
        let weekStart = calendar.date(byAdding: .day, value: -7, to: now) ?? now
        var total = 0.0
        for activity in activities {
            for event in activity.events ?? [] where event.createdAt >= weekStart {
                let e = event.quantity * activity.co2Emission
                if e > 0 { total += e }
            }
        }
        return total
    }

    var progress: Double {
        weeklyBudgetKg > 0 ? min(weeklyConsumption / weeklyBudgetKg, 1.0) : 0
    }

    var isOverBudget: Bool { weeklyConsumption > weeklyBudgetKg }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink {
                BudgetSettingsView()
            } label: {
                HStack {
                    Text("Budget")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                }
            }
            .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(weeklyConsumption, specifier: "%.0f")")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(isOverBudget ? .red : .primary)
                Text("/\(weeklyBudgetKg, specifier: "%.0f") kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.secondary.opacity(0.2))
                    RoundedRectangle(cornerRadius: 4)
                        .fill(isOverBudget ? Color.red : Color.green)
                        .frame(width: max(4, geo.size.width * progress))
                        .animation(.spring(duration: 0.6), value: progress)
                }
            }
            .frame(height: 8)

            Text(isOverBudget
                 ? "Over budget this week"
                 : "\(weeklyBudgetKg - weeklyConsumption, specifier: "%.0f") kg remaining")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Settings

private struct BudgetPreset: Identifiable {
    let id = UUID()
    let label: String
    let value: Double
}

struct BudgetSettingsView: View {
    @AppStorage("weeklyBudgetKg") private var weeklyBudgetKg: Double = 115.0
    @State private var draft: Double = 115.0

    private let presets: [BudgetPreset] = [
        BudgetPreset(label: "Strict — 50 kg", value: 50),
        BudgetPreset(label: "1.5°C target — 115 kg", value: 115),
        BudgetPreset(label: "Global average — 180 kg", value: 180),
        BudgetPreset(label: "No limit — 500 kg", value: 500),
    ]

    var body: some View {
        Form {
            Section {
                HStack {
                    Text("Weekly limit")
                    Spacer()
                    TextField("kg", value: $draft, format: .number)
                        .keyboardType(.decimalPad)
                        .multilineTextAlignment(.trailing)
                        .frame(width: 80)
                    Text("kg CO₂")
                        .foregroundStyle(.secondary)
                }
            } header: {
                Text("CO₂ Budget")
            } footer: {
                Text("The 1.5°C climate target implies roughly 115 kg CO₂ per person per week.")
            }

            Section("Presets") {
                ForEach(presets) { preset in
                    Button {
                        withAnimation { draft = preset.value }
                    } label: {
                        HStack {
                            Text(preset.label)
                            Spacer()
                            if draft == preset.value {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(Color.accentColor)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                }
            }
        }
        .navigationTitle("CO₂ Budget")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear { draft = weeklyBudgetKg }
        .onChange(of: draft) { _, v in weeklyBudgetKg = v }
    }
}

#Preview {
    NavigationStack { BudgetView() }
}
