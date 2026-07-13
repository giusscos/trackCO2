//
//  WhatsNewView.swift
//  trackCO2
//

import SwiftUI

struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let health = ClaudHealth(score: 0.95)

    private struct Feature: Identifiable {
        var id: String { icon }
        let icon: String
        let accent: Color
        let text: LocalizedStringKey
    }

    private let features: [Feature] = [
        Feature(icon: "theatermasks.fill", accent: .purple, text: "whats_new.feature.mascot"),
        Feature(icon: "cloud.sun.bolt.fill", accent: .cyan, text: "whats_new.feature.weather"),
        Feature(icon: "lightbulb.fill", accent: .green, text: "whats_new.feature.tips"),
        Feature(icon: "sparkles", accent: .orange, text: "whats_new.feature.ui"),
        Feature(icon: "map.fill", accent: .blue, text: "whats_new.feature.maps")
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    VStack(spacing: 6) {
                        ClaudCloudView(
                            color: health.cloudBodyColor,
                            baseEyeOpenness: health.baseEyeOpenness,
                            isHungry: false
                        )
                        .scaleEffect(1.2)
                        .padding(.vertical, 8)

                        Text("whats_new.title")
                            .font(.title2)
                            .fontWeight(.bold)
                            .multilineTextAlignment(.center)

                        Text("whats_new.subtitle")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(Array(features.enumerated()), id: \.element.id) { index, feature in
                            PaywallBenefitRow(
                                icon: feature.icon,
                                accent: feature.accent,
                                text: feature.text,
                                index: index
                            )
                        }
                    }

                    Spacer(minLength: 8)
                }
                .padding(.vertical)
                .padding(.horizontal, 20)
            }
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
                    Button {
                        dismiss()
                    } label: {
                        Text("whats_new.cta")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 14)
                    }
                }
            }
        }
    }
}

#Preview {
    WhatsNewView()
}
