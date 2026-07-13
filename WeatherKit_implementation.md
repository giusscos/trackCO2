# WeatherKit Walking Suggestions — Implementation Prompt

## Context

This is a Swift/SwiftUI iOS app called **trackCO2** that helps users track their carbon footprint. It uses SwiftData, HealthKit, StoreKit, and follows an `@Observable` architecture (no Combine).

The goal is to integrate **Apple WeatherKit** to detect poor weather or air conditions and suggest the user walk or cycle instead of using CO₂-emitting transport when conditions are good. Show a card in the main `SummaryView` dashboard and optionally update the mascot speech bubble.

---

## Existing relevant files

### `Utils/LocationManager.swift` (already exists — reuse this)
```swift
import Foundation
import SwiftUI
import MapKit

@Observable
class LocationManager: NSObject, CLLocationManagerDelegate {
    private let manager = CLLocationManager()
    var lastLocation: CLLocation? = nil
    var authorizationStatus: CLAuthorizationStatus = .notDetermined

    override init() {
        super.init()
        manager.delegate = self
        manager.desiredAccuracy = kCLLocationAccuracyBest
    }

    func requestLocation() {
        manager.requestWhenInUseAuthorization()
        manager.startUpdatingLocation()
    }

    func stopUpdating() {
        manager.stopUpdatingLocation()
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        lastLocation = location
        manager.stopUpdatingLocation()
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        authorizationStatus = manager.authorizationStatus
        if authorizationStatus == .authorizedWhenInUse || authorizationStatus == .authorizedAlways {
            manager.requestLocation()
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("Location error: \(error.localizedDescription)")
    }
}
```

### `View/SummaryView.swift` (relevant portion — where to insert the new widget)
```swift
Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8) {
    ClaudMascotView(healthScore: calculateWeeklyCO2Health(activities: activities))
    CO2ChartView()

    if healthKitAuthorized {
        GridRow {
            StepCountView()
            WalkingRunningDistanceView()
        }
    }

    // <-- INSERT WeatherSuggestionView() here, spanning full width

    GridRow {
        CompensationView()
        ConsumptionView()
    }

    GridRow {
        MostUsedView()
        TipsView()
    }

    if hasAnyTrendsData(activities: activities) {
        TrendsView()
    }
}
```

### `View/Mascot/ClaudMascotView.swift` (relevant portion — the speech bubble)
```swift
// ClaudHealth.message is used in the SpeechBubble shown by the mascot.
// The mascot widget is ClaudMascotView(healthScore: Double).
// The speech bubble shows: isHungry ? health.hungryMessage : health.message
// We want to optionally show a weather message instead when conditions are notable.
```

---

## What to build

### Step 1 — Manual setup (tell the developer to do this before running)

1. In the **Apple Developer portal → Identifiers**, select the app bundle ID and enable **WeatherKit**.
2. Wait ~30 minutes for propagation.
3. In Xcode → target → **Signing & Capabilities**, add the **WeatherKit** capability. This edits `trackCO2.entitlements` automatically.
4. The app already has location permission usage strings in `Info.plist` (used by HealthKit flows), so no new plist keys should be needed — but verify `NSLocationWhenInUseUsageDescription` exists.

---

### Step 2 — Create `Utils/WeatherManager.swift`

Create a new file. Use the existing `LocationManager` to get the user's location, then call WeatherKit. This must be `@Observable` to match the app's architecture.

```swift
import CoreLocation
import WeatherKit
import SwiftUI

@Observable
final class WeatherManager {
    static let shared = WeatherManager()

    private let service = WeatherService.shared

    private(set) var suggestion: WalkingSuggestion = .unknown
    private(set) var conditionDescription: String = ""
    private(set) var isLoading = false

    enum WalkingSuggestion {
        case walk       // clear/sunny — prompt the user to walk
        case caution    // overcast/breezy — mention it but don't push hard
        case avoid      // smoke, haze, storm, extreme cold/heat — recommend avoiding outdoor exertion
        case unknown    // not fetched yet or location unavailable
    }

    private init() {}

    func refresh(using locationManager: LocationManager) async {
        guard let location = locationManager.lastLocation else {
            // trigger a location fetch and wait for it
            locationManager.requestLocation()
            return
        }
        await fetchWeather(for: location)
    }

    @MainActor
    private func fetchWeather(for location: CLLocation) async {
        isLoading = true
        defer { isLoading = false }

        do {
            let weather = try await service.weather(for: location, including: .current)

            let badConditions: Set<WeatherCondition> = [
                .haze, .smoky, .blowingDust, .foggy,
                .heavyRain, .heavySleet, .heavySnow,
                .hurricane, .tropicalStorm,
                .isolatedThunderstorms, .scatteredThunderstorms,
                .strongStorms, .thunderstorms,
                .blizzard, .blowingSnow,
                .freezingDrizzle, .freezingRain, .wintryMix, .sleet
            ]

            let marginalConditions: Set<WeatherCondition> = [
                .drizzle, .mostlyCloudy, .cloudy,
                .sunFlurries, .flurries, .snow, .breezy, .windy
            ]

            let condition = weather.condition
            conditionDescription = condition.description

            if badConditions.contains(condition) {
                suggestion = .avoid
            } else if marginalConditions.contains(condition) {
                suggestion = .caution
            } else {
                suggestion = .walk
            }
        } catch {
            suggestion = .unknown
        }
    }
}
```

---

### Step 3 — Create `View/SummaryWidget/WeatherSuggestionView.swift`

This is a dashboard card shown in `SummaryView`. It should be hidden when `suggestion == .unknown` or while loading. Matches the visual style of other cards in the app (`.ultraThinMaterial` background, `RoundedRectangle(cornerRadius: 16)`).

```swift
import SwiftUI

struct WeatherSuggestionView: View {
    @State private var weather = WeatherManager.shared
    @State private var locationManager = LocationManager()

    private var config: (icon: String, accent: Color, title: LocalizedStringKey, body: LocalizedStringKey)? {
        switch weather.suggestion {
        case .walk:
            return ("figure.walk",
                    .green,
                    "Great time to walk!",
                    "Skies are clear. Skip the car and log some green steps.")
        case .caution:
            return ("cloud.fill",
                    .yellow,
                    "Walking is possible",
                    "Conditions are okay but not ideal. A short walk still counts.")
        case .avoid:
            return ("aqi.high",
                    .red,
                    "Poor conditions outside",
                    "Air quality or weather makes outdoor activity inadvisable. Consider public transport.")
        case .unknown:
            return nil
        }
    }

    var body: some View {
        if let config {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .fill(config.accent.gradient.opacity(0.2))
                        .frame(width: 44, height: 44)
                    Image(systemName: config.icon)
                        .font(.body.weight(.semibold))
                        .foregroundStyle(config.accent.gradient)
                }

                VStack(alignment: .leading, spacing: 3) {
                    Text(config.title)
                        .font(.subheadline.weight(.semibold))
                    Text(config.body)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }

                Spacer()
            }
            .padding(14)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
            .task {
                await weather.refresh(using: locationManager)
            }
        }
    }
}
```

---

### Step 4 — Insert the card into `SummaryView.swift`

Inside the `Grid`, after the HealthKit row and before the `CompensationView` row, add:

```swift
WeatherSuggestionView()
    .gridCellColumns(2)
```

The full Grid block should look like:

```swift
Grid(alignment: .topLeading, horizontalSpacing: 8, verticalSpacing: 8) {
    ClaudMascotView(healthScore: calculateWeeklyCO2Health(activities: activities))
    CO2ChartView()

    if healthKitAuthorized {
        GridRow {
            StepCountView()
            WalkingRunningDistanceView()
        }
    }

    WeatherSuggestionView()
        .gridCellColumns(2)

    GridRow {
        CompensationView()
        ConsumptionView()
    }

    GridRow {
        MostUsedView()
        TipsView()
    }

    if hasAnyTrendsData(activities: activities) {
        TrendsView()
    }
}
```

---

### Step 5 (optional) — Weather-aware mascot message

In `ClaudHealth` inside `View/Mascot/ClaudMascotView.swift`, add:

```swift
func weatherMessage(for suggestion: WeatherManager.WalkingSuggestion) -> String {
    switch suggestion {
    case .walk:    return String(localized: "Sky is clear!\nPerfect day to walk. 🌤️")
    case .caution: return String(localized: "A bit cloudy…\nA short walk still counts! 🚶")
    case .avoid:   return String(localized: "Stay safe!\nPoor air today. 🏠")
    case .unknown: return message
    }
}
```

Then in `ClaudMascotView`, hold a `@State private var weather = WeatherManager.shared` and replace the `SpeechBubble` text with:

```swift
SpeechBubble(
    text: isHungry ? health.hungryMessage : health.weatherMessage(for: weather.suggestion),
    tailDirection: .up
)
```

---

## Already done (don't redo)

- `OnboardingView.swift` — A new page `OnboardingWeatherPage` has already been added between the Trips page and the HealthKit page. It uses `cloud.sun.fill` icon, title "Walk When It's Worth It", and explains the weather suggestion feature.
- `PaywallView.swift` — A new benefit row has already been added: `cloud.sun.fill` / `.cyan` / "Weather-smart nudges: get prompted to walk or cycle when air is clean and skies are clear."

---

## Architecture notes

- The app uses `@Observable` (Swift Observation framework) — no `@StateObject` or `ObservableObject`.
- All async work uses `async/await` — no Combine.
- `WeatherManager.shared` is a singleton so its state survives view lifecycle.
- WeatherKit is **free up to 500,000 API calls/month**. A single fetch on dashboard load is negligible.
- The feature degrades silently: if location is denied or WeatherKit fails, `suggestion` stays `.unknown` and the card is simply hidden — no error is shown to the user.
- Adding the WeatherKit capability will require a **new provisioning profile** before TestFlight/App Store submission.
