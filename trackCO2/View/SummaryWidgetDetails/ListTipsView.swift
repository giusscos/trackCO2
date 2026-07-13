//
//  ListTipsView.swift
//  trackCO2
//
//  Created by Giuseppe Cosenza on 05/07/25.
//

import SwiftData
import SwiftUI

struct ListTipsView: View {
    @Query var activities: [Activity]

    private var tips: [GeneratedTip] {
        TipGenerator.generate(from: activities)
    }

    var body: some View {
        List {
            if tips.isEmpty {
                Text("No activities found. Start tracking your activities to get personalized tips!")
                    .font(.headline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            } else {
                ForEach(tips) { tip in
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            if let activity = tip.activity {
                                Text(activity.type.emoji)
                                    .font(.title2)

                                VStack(alignment: .leading) {
                                    Text(activity.displayName)
                                        .font(.headline)
                                    Text(tip.title)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                            } else {
                                VStack(alignment: .leading) {
                                    Text(tip.title)
                                        .font(.headline)
                                }
                            }

                            Spacer()

                            if tip.isPositive {
                                Image(systemName: "leaf.fill")
                                    .foregroundStyle(.green)
                            } else {
                                Image(systemName: "exclamationmark.triangle.fill")
                                    .foregroundStyle(.orange)
                            }
                        }

                        Text(tip.message)
                            .font(.subheadline)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Activity Tips")
    }
}

#Preview {
    ListTipsView()
}
