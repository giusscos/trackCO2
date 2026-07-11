# trackCO2 — Project Context for New Chat

## Overview

**trackCO2** is an iOS app for tracking personal carbon footprints. Users log daily activities (transport, food, energy, recycling), visualize CO₂ emissions and compensations, and receive gamified feedback via an animated mascot. The app uses a dual monetization model (subscriptions + lifetime purchase) via StoreKit 2.

- **Bundle ID:** `giusscos.trackCO2`
- **Minimum Deployment Target:** iOS 18.5
- **Xcode project root:** `/Users/m1pro/Developer/trackCO2/trackCO2/`
- **Primary language:** Swift / SwiftUI
- **Supported localizations:** en, en-GB, en-CA, it, de, es, fr, pt, pt-BR, nl, sv, nb

---

## Architecture

**Pattern:** MVVM-lite — SwiftUI views, SwiftData models, `@Observable` store, top-level utility functions.

```
trackCO2/
├── trackCO2App.swift          # App entry; SwiftData ModelContainer + TipKit init
├── ContentView.swift          # Root TabView (Summary, Trips, Activities); paywall gate
├── Model/
│   ├── Activity.swift         # @Model — activity types, emission factors, defaults
│   ├── ActivityEvent.swift    # @Model — individual log entries (quantity + date)
│   ├── FavoritePlace.swift    # @Model — saved map destinations
│   ├── Store.swift            # @Observable StoreKit 2 manager
│   ├── TipKitStructs.swift    # TipKit tip definitions
│   └── TipsModel.swift        # Tip display logic
├── Utils/
│   ├── CalculateCO2Emissions.swift  # Pure functions: totals, trends, health score
│   ├── HealthKitManager.swift       # Steps + distance queries (singleton)
│   ├── LocationManager.swift        # CLLocationManager wrapper
│   └── LocationService.swift        # MapKit search helper
└── View/
    ├── SummaryView.swift            # Home dashboard (main view)
    ├── ContentView.swift            # Tab container
    ├── Activity/                    # CRUD views for Activity
    ├── Event/                       # ActivityEvent list/tab views
    ├── Map/                         # MapKit trip planner
    │   └── TripMapView.swift        # UIViewRepresentable MKMapView
    ├── Mascot/
    │   └── ClaudMascotView.swift    # Animated mascot (cloud/tree/earth)
    ├── SummaryWidget/               # Dashboard card views
    ├── SummaryWidgetDetails/        # Drill-down list views
    ├── PaywallView.swift            # Subscription onboarding (SubscriptionStoreView)
    ├── PaywallLifetimeView.swift    # Lifetime purchase modal (StoreView)
    └── SelectAppIconView.swift      # Alternate icon picker
```

---

## Key Data Models

### `Activity` (SwiftData `@Model`)
Represents a type of activity with a fixed CO₂ emission factor.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | Auto-generated |
| `type` | `ActivityEmissionType` | 16 types (see below) |
| `name` | `String` | Display name |
| `activityDescription` | `String` | User notes |
| `quantityUnit` | `QuantityUnit` | km, kg, kWh, tree, steps |
| `emissionUnit` | `EmissionUnit` | kgCO2e or gCO2e |
| `co2Emission` | `Double` | Factor multiplied by quantity |
| `createdAt` | `Date` | |
| `events` | `[ActivityEvent]?` | Cascade-delete relationship |

**`ActivityEmissionType` (16 cases):**
- Emitting: `car`, `airplane`, `boat`, `motorcycle`, `bus`, `train`, `beef`, `chicken`, `vegetables`, `rice`, `dairy`, `electricity`
- Reducing: `walking`, `biking`, `treePlanting`, `recycling`

**`isCO2Reducing`** — returns `true` for the reducing types above.

### `ActivityEvent` (SwiftData `@Model`)
One log entry for an activity.

| Property | Type | Notes |
|---|---|---|
| `id` | `UUID` | |
| `quantity` | `Double` | Amount in `quantityUnit` |
| `createdAt` | `Date` | |
| `activity` | `Activity?` | Back-reference |

### `FavoritePlace` (SwiftData `@Model`)
Saved map destination. Managed in `Store` container alongside `Activity`.

---

## Frameworks & Integrations

| Framework | Usage |
|---|---|
| **SwiftData** | Persistence for `Activity`, `ActivityEvent`, `FavoritePlace`; `@Query` in views |
| **SwiftUI** | All UI; `@Observable`, `@Environment`, `@AppStorage`, `@State` |
| **StoreKit 2** | `Product`, `Transaction`, `SubscriptionStoreView`, `StoreView` |
| **HealthKit** | Steps + walking/running distance (today, history, hourly breakdown) |
| **TipKit** | In-app hints; initialized with `.applicationDefault` datastore |
| **MapKit** | `MKMapView` via `UIViewRepresentable`; routes, annotations, polylines |
| **CoreLocation** | User location for trip planning |

---

## StoreKit 2 — Product IDs & Group

**Subscription products (auto-renewable):**
- `fp_199_1m_d` — monthly
- `fp_1999_1y_1w` — yearly
- `fp_399_1m_3d_f` — family monthly
- `fp_3999_1y_1w_f` — family yearly

**Lifetime products (non-consumable):**
- `com.giusscos.footprintLifetime`
- `com.giusscos.footprintFamilyLifetime`

**Subscription Group ID:** `21727569`

**`Store` class key API:**
```swift
store.subscriptions           // [Product] — available subscriptions
store.purchasedSubscriptions  // [Product] — active subscriptions
store.storeProducts           // [Product] — lifetime products
store.purchasedProducts       // [Product] — purchased lifetime
store.isLoading               // Bool
await store.purchase(product) // throws StoreError.failedVerification
```

**Paywall gate in ContentView:**
```swift
var hasPaid: Bool {
    !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
}
```

---

## Mascot System (`ClaudMascotView`)

Three mascot variants selected via `@AppStorage("appIcon")`:
- `"claud"` — animated cloud (default)
- `"AppIconTree"` — tree (`TriTreeView`)
- `"AppIconWorld"` — earth globe (`ErtEarthView`)

**Health score:** `calculateWeeklyCO2Health(activities:) -> Double` returns 0–1.
- 0.0–0.2 → Sick (red)
- 0.2–0.4 → Tired (orange)
- 0.4–0.6 → Neutral (yellow)
- 0.6–0.8 → Good (mint)
- 0.8–1.0 → Thriving (green)

**Animations:** breathing, blinking, pupil tracking, speech bubbles — all driven by async `Task` loops inside `.onAppear`. 5-tap easter egg triggers a "hungry" shake animation.

---

## Calculation Utilities (`CalculateCO2Emissions.swift`)

All top-level functions, no class/struct wrapper:

```swift
// Returns (consumption: Double, compensation: Double) in kgCO2e
calculateCO2Totals(activities: [Activity]) -> (consumption: Double, compensation: Double)

// Returns health ratio for past 7 days (0.5 if no data)
calculateWeeklyCO2Health(activities: [Activity]) -> Double

// Returns activity with most events
findMostUsedActivity(activities: [Activity]) -> Activity?

// Checks if activity has events on ≥5 distinct days in last 5 days
hasEnoughDataForTrends(activity: Activity) -> Bool

// Returns top N activities by weekly quantity with enough trend data
getTopActivitiesByWeeklyUsage(activities: [Activity], limit: Int = 2) -> [Activity]

// Checks if any activity has trends data (used to show TrendsView)
hasAnyTrendsData(activities: [Activity]) -> Bool
```

---

## Localization

**Pattern used throughout:** `String(localized: "key")` or `Text("key")` with the key matching entries in `Localizable.strings`.

**Localization file location:** `trackCO2/Localizable.strings/<lang-code>/` (one per language).

**Key string categories:**
- Tab bar: `"Home"`, `"Trips"`, `"Activities"`
- Mascot health states: `"Thriving"`, `"Good"`, `"Neutral"`, `"Tired"`, `"Sick"`
- Activity CRUD, map/trip UI, summary widgets, paywall copy, TipKit hints

When adding new user-facing strings, add the key+value to **all 12** localization files.

---

## Code Style Guidelines

- **Naming:** PascalCase for types, camelCase for properties/methods.
- **State:** `@State private var` for local SwiftUI state; `let` for constants.
- **Async:** Use `async`/`await` — avoid Combine.
- **Comments:** Only when the *why* is non-obvious. No docstrings on obvious functions.
- **Force unwrapping:** Avoid; leverage `guard`, `if let`, optional chaining.
- **SwiftData:** Mutations must happen on the `@Environment(\.modelContext)` from a SwiftUI view or a background actor — never on a stale context.
- **New UI strings:** Always add to all 12 localization files.
- **Indentation:** 4 spaces.
- **New files:** Prefer editing existing files. Only create new files when a concept is genuinely isolated.

---

## Apple Platform Specifics

- **App icons:** Three alternate icons (`AppIconWorld`, `AppIconTree`) plus default. Changed at runtime via `UIApplication.shared.setAlternateIconName()`.
- **Background modes:** `remote-notification` declared in `Info.plist`.
- **Entitlements file:** `trackCO2.entitlements` — confirm HealthKit and StoreKit entitlements are present before adding related features.
- **StoreKit testing:** `offlineStoreProducts.storekit` and `onlineStoreProducts.storekit` available for Xcode StoreKit sandbox testing.
- **SwiftData schema:** Adding new `@Model` types requires updating the `ModelContainer` schema in `trackCO2App.swift`.
- **TipKit:** Tips are defined in `TipKitStructs.swift`; configured at app launch with `.applicationDefault` datastore.
- **HealthKit:** Authorization requested in `SummaryView.onAppear`. All queries go through `HealthKitManager.shared` (singleton).
- **MapKit:** `TripMapView` is a `UIViewRepresentable` wrapping `MKMapView`; its coordinator is `TripMapCoordinator` implementing `MKMapViewDelegate`.

---

## Development Environment

- **IDE:** Xcode (project at `/Users/m1pro/Developer/trackCO2/`)
- **Language:** Swift 5.9+, SwiftUI, iOS 18.5+
- **Build:** Use `BuildProject` MCP command to compile and check for errors.
- **Diagnostics:** Use `XcodeRefreshCodeIssuesInFile` for fast in-file type/API checks.
- **Testing:** Swift Testing framework for unit tests; XCUIAutomation for UI tests.
- **Documentation:** Use `DocumentationSearch` MCP to look up current Apple framework APIs — especially for Liquid Glass, FoundationModels, and new SwiftUI APIs which may post-date training data.
