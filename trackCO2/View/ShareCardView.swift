//
//  ShareCardView.swift
//  trackCO2
//

import SwiftUI

/// Rendered off-screen by ImageRenderer to produce the share image.
struct ShareCardView: View {
    let activities: [Activity]

    private var totals: (consumption: Double, compensation: Double) {
        calculateCO2Totals(activities: activities)
    }
    private var net: Double { totals.consumption - totals.compensation }
    private var streak: Int { calculateCurrentStreak(activities: activities) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("My CO₂ Footprint")
                        .font(.title2).fontWeight(.bold)
                    Text(Date().formatted(.dateTime.month(.wide).year()))
                        .font(.subheadline).foregroundStyle(.secondary)
                }
                Spacer()
                Text("🌍")
                    .font(.system(size: 44))
            }

            // Stats row
            HStack(spacing: 12) {
                ShareStatCard(title: "Emitted", value: totals.consumption, suffix: "kg", color: .red)
                ShareStatCard(title: "Offset", value: totals.compensation, suffix: "kg", color: .green)
                ShareStatCard(title: "Net", value: abs(net), suffix: "kg", color: net <= 0 ? .green : .red,
                              prefix: net <= 0 ? "−" : "+")
            }

            // Streak
            if streak > 0 {
                HStack(spacing: 8) {
                    Text("🔥")
                    Text("\(streak)-day logging streak")
                        .font(.subheadline).fontWeight(.medium)
                }
                .padding(.vertical, 8)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            }

            // Footer
            Text("Tracked with Claud · trackCO2")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .padding(24)
        .frame(width: 360)
        .background(Color(UIColor.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.08), radius: 16, y: 4)
    }
}

private struct ShareStatCard: View {
    let title: String
    let value: Double
    let suffix: String
    let color: Color
    var prefix: String = ""

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption).foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(prefix + String(format: "%.1f", value))
                    .font(.title3).fontWeight(.bold).foregroundStyle(color)
                Text(suffix)
                    .font(.caption2).foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

/// UIViewControllerRepresentable wrapper so we can present UIActivityViewController from SwiftUI.
struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
