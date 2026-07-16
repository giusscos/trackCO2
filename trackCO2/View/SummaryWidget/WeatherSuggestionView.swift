//
//  WeatherSuggestionView.swift
//  trackCO2
//

import SwiftUI

struct WeatherSuggestionView: View {
    @State private var weather = WeatherManager.shared
    @State private var locationManager = LocationManager.shared

    private var config: (icon: String, accent: Color, title: LocalizedStringKey, body: LocalizedStringKey) {
        switch weather.suggestion {
        case .walk:
            return ("figure.walk", .green,
                    "Great time to walk!",
                    "Skies are clear. Skip the car and log some green steps.")
        case .caution:
            return ("cloud.fill", .yellow,
                    "Walking is possible",
                    "Conditions are okay but not ideal. A short walk still counts.")
        case .avoid:
            return ("aqi.high", .red,
                    "Poor conditions outside",
                    "Air quality or weather makes outdoor activity inadvisable. Consider public transport.")
        case .unknown:
            return ("cloud.sun.fill", .gray,
                    "Checking weather…",
                    "Fetching local conditions.")
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            NavigationLink {
                ListWeatherForecastView()
            } label: {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(config.accent.gradient.opacity(0.2))
                            .frame(width: 44, height: 44)

                        if weather.isLoading || weather.suggestion == .unknown {
                            ProgressView()
                                .tint(config.accent)
                        } else {
                            Image(systemName: config.icon)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(config.accent.gradient)
                        }
                    }

                    VStack(alignment: .leading, spacing: 3) {
                        Text(config.title)
                            .font(.subheadline.weight(.semibold))
                            .foregroundStyle(weather.suggestion == .unknown ? .secondary : .primary)
                        if !weather.isLoading && weather.suggestion != .unknown {
                            Text(config.body)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .fixedSize(horizontal: false, vertical: true)

                            if WeatherManager.showsSunProtectionTip(for: weather.suggestion, isHighTemperature: weather.isTodayHighTemperature) {
                                Text("It's hot — wear a hat, use sun protection, and avoid walking at midday.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if WeatherManager.showsColdWeatherTip(for: weather.suggestion, isLowTemperature: weather.isTodayLowTemperature) {
                                Text("It's cold — dress in layers, cover your hands and head, and warm up before longer walks.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }
                    }

                    Spacer()

                    Label("Navigate to", systemImage: "chevron.right")
                        .labelStyle(.iconOnly)
                        .foregroundStyle(.secondary)
                }
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)

            // Outside NavigationLink so the legal URL remains tappable (WeatherKit 5.2.5).
            WeatherAttributionView(attribution: weather.attribution, compact: true)
                .padding(.horizontal, 4)
        }
        .task {
            guard locationManager.isAuthorized else { return }
            await weather.refresh(using: locationManager)
        }
        .onChange(of: locationManager.authorizationStatus) { _, _ in
            guard locationManager.isAuthorized else { return }
            Task {
                await weather.refresh(using: locationManager)
            }
        }
        .onChange(of: locationManager.lastLocation) { _, location in
            guard location != nil else { return }
            Task {
                await weather.refresh(using: locationManager)
            }
        }
    }
}

#Preview {
    WeatherSuggestionView()
        .padding()
}
