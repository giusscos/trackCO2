//
//  StreakView.swift
//  trackCO2
//

import SwiftData
import SwiftUI

struct StreakView: View {
    @Query var activities: [Activity]

    var streak: Int { calculateCurrentStreak(activities: activities) }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Streak")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(streakEmoji)
                    .font(.title2)
                Text("\(streak)")
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundStyle(streakValueColor)
                Text("days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Text(streakMessage)
                .font(.caption)
                .foregroundStyle(streak >= 1 ? streakValueColor.opacity(0.85) : .secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding()
        .frame(minWidth: 0, maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var streakEmoji: String {
        switch streak {
        case 0: return "💤"
        case 1...2: return "🌱"
        case 3...6: return "🔥"
        case 7...13: return "🌍"
        default: return "🏆"
        }
    }

    private var streakValueColor: Color {
        switch streak {
        case 0: return .secondary
        case 1...6: return .green
        case 7...13: return .mint
        default: return .orange
        }
    }

    private var streakMessage: String {
        switch streak {
        case 0: return "Log today to start a streak!"
        case 1: return "Good start — keep it going!"
        case 2...6: return "Building momentum!"
        case 7...13: return "One full week — amazing!"
        default: return "Incredible consistency!"
        }
    }
}

#Preview {
    StreakView()
}
