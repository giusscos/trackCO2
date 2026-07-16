//
//  ListWeatherForecastView.swift
//  trackCO2
//

import SwiftUI

struct ListWeatherForecastView: View {
    @State private var weather = WeatherManager.shared
    @State private var locationManager = LocationManager.shared

    private let temperatureFormatter: MeasurementFormatter = {
        let formatter = MeasurementFormatter()
        formatter.numberFormatter.maximumFractionDigits = 0
        formatter.unitStyle = .short
        return formatter
    }()

    var body: some View {
        List {
            Section {
                ForEach(weather.dailyForecast) { forecast in
                    HStack(spacing: 14) {
                        ZStack {
                            Circle()
                                .fill(accentColor(for: forecast.suggestion).gradient.opacity(0.2))
                                .frame(width: 44, height: 44)

                            Image(systemName: forecast.symbolName)
                                .font(.body.weight(.semibold))
                                .foregroundStyle(accentColor(for: forecast.suggestion).gradient)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(forecast.date.formatted(.dateTime.weekday(.wide).day().month(.abbreviated)))
                                .font(.subheadline.weight(.semibold))

                            Text(suggestionLabel(for: forecast.suggestion))
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            if forecast.suggestion == .avoid {
                                Text("If driving is unavoidable, this is a better day for it.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if WeatherManager.showsSunProtectionTip(for: forecast.suggestion, isHighTemperature: forecast.isHighTemperature) {
                                Text("It's hot — wear a hat, use sun protection, and avoid walking at midday.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }

                            if WeatherManager.showsColdWeatherTip(for: forecast.suggestion, isLowTemperature: forecast.isLowTemperature) {
                                Text("It's cold — dress in layers, cover your hands and head, and warm up before longer walks.")
                                    .font(.caption2)
                                    .foregroundStyle(.tertiary)
                                    .fixedSize(horizontal: false, vertical: true)
                            }
                        }

                        Spacer()

                        Text(temperatureRange(for: forecast))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.trailing)
                    }
                    .padding(.vertical, 4)
                }
            } footer: {
                WeatherAttributionView(attribution: weather.attribution)
                    .padding(.top, 8)
            }
        }
        .navigationTitle("Weather Forecast")
        .overlay {
            if weather.isLoading {
                ProgressView()
            }
        }
        .task {
            if locationManager.authorizationStatus == .notDetermined {
                locationManager.requestAuthorizationIfNeeded()
            }
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

    private func accentColor(for suggestion: WeatherManager.WalkingSuggestion) -> Color {
        switch suggestion {
        case .walk:
            return .green
        case .caution:
            return .yellow
        case .avoid:
            return .red
        case .unknown:
            return .gray
        }
    }

    private func suggestionLabel(for suggestion: WeatherManager.WalkingSuggestion) -> LocalizedStringKey {
        switch suggestion {
        case .walk:
            return "Great day to walk or cycle"
        case .caution:
            return "Walking possible"
        case .avoid:
            return "Stay indoors"
        case .unknown:
            return "Checking conditions…"
        }
    }

    private func temperatureRange(for forecast: WeatherManager.DayForecast) -> String {
        let low = temperatureFormatter.string(from: forecast.lowTemperature)
        let high = temperatureFormatter.string(from: forecast.highTemperature)
        return "\(low) / \(high)"
    }
}

#Preview {
    NavigationStack {
        ListWeatherForecastView()
    }
}
