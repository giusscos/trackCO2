//
//  WeatherAttributionView.swift
//  trackCO2
//
//  WeatherKit Guideline 5.2.5 — display  Weather mark + legal source link.
//

import SwiftUI
import WeatherKit

struct WeatherAttributionView: View {
    @Environment(\.colorScheme) private var colorScheme

    let attribution: WeatherAttribution?
    var compact: Bool = false

    var body: some View {
        if let attribution {
            VStack(alignment: compact ? .leading : .center, spacing: compact ? 4 : 6) {
                AsyncImage(
                    url: colorScheme == .dark
                        ? attribution.combinedMarkDarkURL
                        : attribution.combinedMarkLightURL
                ) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFit()
                    case .failure:
                        Text(attribution.serviceName)
                            .font(.caption2.weight(.semibold))
                            .foregroundStyle(.secondary)
                    default:
                        Color.clear
                    }
                }
                .frame(height: compact ? 12 : 16)
                .accessibilityLabel(Text(attribution.serviceName))

                Link(destination: attribution.legalPageURL) {
                    Text("Other data sources")
                        .font(.caption2)
                        .underline()
                }
                .foregroundStyle(.secondary)
                .accessibilityHint(Text("Opens Apple Weather legal attribution"))
            }
            .frame(maxWidth: .infinity, alignment: compact ? .leading : .center)
        }
    }
}

#Preview {
    WeatherAttributionView(attribution: nil)
        .padding()
}
