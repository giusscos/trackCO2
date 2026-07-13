# Prompt: Add a Future Weather Forecast List View to trackCO2 (SwiftUI / iOS)

## Project context

**trackCO2** is a SwiftUI app targeting iOS 17+. It tracks CO₂-emitting and CO₂-reducing activities and gives users eco-friendly suggestions, including a weather-based walking suggestion card (`WeatherSuggestionView`). The project uses:

- **WeatherKit** (`WeatherService.shared`) for live weather data
- **`@Observable`** macro (no `ObservableObject`/Combine)
- **`LocationManager`** (a custom `@Observable` class) that exposes `lastLocation: CLLocation?`
- **`.ultraThinMaterial`** backgrounds and system SF Symbols for visual style
- **`LocalizedStringKey`** for all user-facing strings

---

## What already exists

### `WeatherManager.swift` (`trackCO2/Utils/WeatherManager.swift`)

```swift
@Observable
final class WeatherManager {
    static let shared = WeatherManager()
    private let service = WeatherService.shared

    private(set) var suggestion: WalkingSuggestion = .unknown
    private(set) var conditionDescription: String = ""
    private(set) var isLoading = false

    enum WalkingSuggestion { case walk, caution, avoid, unknown }

    func refresh(using locationManager: LocationManager) async { ... }

    // Fetches only `.current` weather — no daily forecast yet
    private func fetchWeather(for location: CLLocation) async { ... }
}
```

### `WeatherSuggestionView.swift` (`trackCO2/View/SummaryWidget/WeatherSuggestionView.swift`)

A summary card (used inside a `ScrollView`) that shows today's single walking suggestion (`walk` / `caution` / `avoid`). It has a `.task` and `.onChange(of: locationManager.lastLocation)` that call `weather.refresh(using:)`.

---

## What you need to build

### 1. Extend `WeatherManager` — add a daily forecast

Add a new struct and property to `WeatherManager`:

```swift
struct DayForecast: Identifiable {
    let id: Date          // use the forecast date as the id
    let date: Date
    let condition: WeatherCondition
    let symbolName: String          // use WeatherKit's symbolName
    let lowTemperature: Measurement<UnitTemperature>
    let highTemperature: Measurement<UnitTemperature>
    let suggestion: WalkingSuggestion
}

private(set) var dailyForecast: [DayForecast] = []
```

Inside `fetchWeather(for:)`, also request `.daily` from WeatherKit alongside `.current`:

```swift
let (current, daily) = try await service.weather(for: location, including: .current, .daily)
```

Map the next **7 days** (skip today — index 0 if you want to show only future days, or include today at index 0) into `DayForecast` values using the same `badConditions` / `marginalConditions` sets that already exist for `.current`. Store the result in `dailyForecast`.

### 2. Create `ListWeatherForecastView.swift`

File path: `trackCO2/View/SummaryWidgetDetails/ListWeatherForecastView.swift`

The view must:

- Be a `NavigationStack`-compatible detail screen (it will be pushed via a `NavigationLink` from `WeatherSuggestionView`).
- Use `@State private var weather = WeatherManager.shared` and `@State private var locationManager = LocationManager()`.
- Show a `List` of rows, one per `DayForecast` in `weather.dailyForecast`.
- Each row displays:
  - **Left**: a `Label`-style SF Symbol circle (the `DayForecast.symbolName`) tinted with the suggestion accent color (green / yellow / red / gray — same palette as `WeatherSuggestionView`).
  - **Center**: the weekday + date (e.g. "Monday, 14 Jul"), a short suggestion label (see table below), and — only when `suggestion == .avoid` — a tertiary caption: *"If driving is unavoidable, this is a better day for it."*
  - **Right**: low/high temperature formatted with `MeasurementFormatter` in the user's locale.
- Show a `ProgressView` overlay while `weather.isLoading` is true.
- Call `await weather.refresh(using: locationManager)` in `.task`, and re-fetch on `.onChange(of: locationManager.lastLocation)`.
- Use `.navigationTitle("Weather Forecast")` (localized).
- Use `.ultraThinMaterial` or the standard `List` background — match the app's existing material style.

#### Row suggestion labels and driving hint

| `WalkingSuggestion` | Center label | Tertiary driving caption |
|---|---|---|
| `.walk` | "Great day to walk or cycle" | *(none)* |
| `.caution` | "Walking possible" | *(none)* |
| `.avoid` | "Stay indoors" | "If driving is unavoidable, this is a better day for it." |
| `.unknown` | "Checking conditions…" | *(none)* |

**Design rationale:** the app never promotes car use as a reward. The driving caption appears **only** on `.avoid` days, framing the car as the least-bad fallback when outdoor activity is genuinely impractical (heavy rain, extreme cold/heat, poor air quality). This keeps the eco-friendly tone intact while giving actionable guidance.

### 3. Wire up navigation from `WeatherSuggestionView`

Wrap the existing `WeatherSuggestionView` body in a `NavigationLink(destination: ListWeatherForecastView())` so tapping the card navigates to the forecast list. If the card is already inside a `NavigationStack` in `SummaryView`, just add the link; otherwise wrap appropriately.

---

## Code-style rules (must follow)

- **No Combine** — use `async/await` only.
- **`@Observable`** macro, not `ObservableObject`.
- **No force-unwraps** (`!`).
- **4-space indentation**.
- **No comments** unless the logic is genuinely non-obvious.
- All user-facing strings must be `LocalizedStringKey` or `String(localized:)`.
- Do **not** add features beyond what is described above.

---

## Existing files to read before coding

1. `trackCO2/Utils/WeatherManager.swift` — extend this, do not rewrite from scratch.
2. `trackCO2/View/SummaryWidget/WeatherSuggestionView.swift` — add the `NavigationLink` here.
3. `trackCO2/View/SummaryWidgetDetails/ListTipsView.swift` — reference for the `List` style used elsewhere in the same folder.
4. `trackCO2/Utils/LocationManager.swift` — understand the `LocationManager` API.

---

## Deliverables

1. **Modified** `WeatherManager.swift` — with `DayForecast` struct, `dailyForecast` property, and updated `fetchWeather` that fetches both `.current` and `.daily`.
2. **New** `trackCO2/View/SummaryWidgetDetails/ListWeatherForecastView.swift`.
3. **Modified** `WeatherSuggestionView.swift` — add the `NavigationLink` to the new detail view.
