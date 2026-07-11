# Task: Create Onboarding Flow

## Objective

Build a first-launch onboarding experience using `NavigationStack` + `NavigationLink` with forward-only page progression. The flow teaches the user how to use the app, requests HealthKit permission (steps + walking distance), and ends with the existing `PaywallView`. After completion, mark onboarding as done so it never shows again.

---

## Files to Create

```
trackCO2/trackCO2/View/Onboarding/OnboardingView.swift   ← new
```

## Files to Modify

```
trackCO2/trackCO2/ContentView.swift                      ← add onboarding gate
trackCO2/trackCO2/Localizable.strings/en                 ← add new keys (then mirror to all 11 other languages)
```

---

## Onboarding Pages (5 total)

| # | Title key | Content |
|---|---|---|
| 1 | `"Welcome to trackCO2!"` | Intro to the app — reuse existing localized string |
| 2 | `"Track Your Activities"` | Explains CO₂ logging |
| 3 | `"Plan Greener Trips"` | Explains the map + transport comparison |
| 4 | `"Sync Your Steps"` | HealthKit permission request (steps + walking distance) |
| 5 | *(Paywall)* | Embeds `SubscriptionStoreView` directly (no inner NavigationStack) |

---

## New Localization Keys

Add these to `en` and mirror to all 11 other languages (`en-GB`, `en-CA`, `it`, `de`, `es`, `fr`, `pt`, `pt-BR`, `nl`, `sv`, `nb`):

```
// MARK: - Onboarding
"Get Started" = "Get Started";
"Next" = "Next";
"Track Your Activities" = "Track Your Activities";
"Log your daily activities — driving, flying, food, energy — and see your real CO₂ footprint build up over time." = "Log your daily activities — driving, flying, food, energy — and see your real CO₂ footprint build up over time.";
"Plan Greener Trips" = "Plan Greener Trips";
"Use the map to compare transport options side by side. The greenest route is always shown first." = "Use the map to compare transport options side by side. The greenest route is always shown first.";
"Sync Your Steps" = "Sync Your Steps";
"trackCO2 can read your step count and walking distance from Apple Health to automatically log eco-friendly movement." = "trackCO2 can read your step count and walking distance from Apple Health to automatically log eco-friendly movement.";
"Allow Health Access" = "Allow Health Access";
"Skip" = "Skip";
"Maybe Later" = "Maybe Later";
```

---

## Persistence Key

Use `@AppStorage` with key `"hasCompletedOnboarding"` (a `Bool`, default `false`). Set it to `true` when the user reaches the final paywall page.

---

## ContentView Changes

**Current file** (`trackCO2/trackCO2/ContentView.swift`):

```swift
struct ContentView: View {
    @State var store = Store()
    @State var showPaywall: Bool = false

    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            TabView {
                SummaryView().tabItem { Label("Home", systemImage: "house.fill") }
                TripsView().tabItem { Label("Trips", systemImage: "map.fill") }
                ListActivityView().tabItem { Label("Activities", systemImage: "list.bullet") }
            }
            .onAppear {
                if hasPaid {
                    UITextField.appearance().clearButtonMode = .whileEditing
                    return
                }
                showPaywall = true
            }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: hasPaid) { _, _ in if !hasPaid { return }; showPaywall = false }
        }
    }
}
```

**Required change:** add an `@AppStorage("hasCompletedOnboarding")` flag and a second `fullScreenCover` for onboarding. The two covers are mutually exclusive — onboarding takes priority.

```swift
struct ContentView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State var store = Store()
    @State var showPaywall: Bool = false

    var hasPaid: Bool {
        !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
    }

    var body: some View {
        if store.isLoading {
            ProgressView()
        } else {
            TabView {
                SummaryView().tabItem { Label("Home", systemImage: "house.fill") }
                TripsView().tabItem { Label("Trips", systemImage: "map.fill") }
                ListActivityView().tabItem { Label("Activities", systemImage: "list.bullet") }
            }
            .onAppear {
                guard hasCompletedOnboarding else { return }   // onboarding gate takes priority
                UITextField.appearance().clearButtonMode = .whileEditing
                if !hasPaid { showPaywall = true }
            }
            .fullScreenCover(isPresented: Binding(
                get: { !hasCompletedOnboarding },
                set: { if !$0 { hasCompletedOnboarding = true } }
            )) {
                OnboardingView()
            }
            .fullScreenCover(isPresented: $showPaywall) { PaywallView() }
            .onChange(of: hasPaid) { _, _ in if !hasPaid { return }; showPaywall = false }
        }
    }
}
```

Key points:
- When `hasCompletedOnboarding` is `false` the onboarding cover opens automatically.
- The `showPaywall` logic only runs after onboarding is done (the `guard` in `.onAppear`).
- The onboarding cover's binding writes `hasCompletedOnboarding = true` when dismissed.

---

## OnboardingView — Full Implementation Spec

### File path
`trackCO2/trackCO2/View/Onboarding/OnboardingView.swift`

### Architecture
- Single `NavigationStack` with a `.navigationDestination(for:)` pattern or manual `NavigationLink` push.
- Each page is a `struct` conforming to `View`.
- Pages are **forward-only** — no back button after page 1.
- The 5th page embeds `SubscriptionStoreView` **without** wrapping it in a `NavigationStack` (it would be nested inside the onboarding stack).

### Shared page layout

Each of pages 1–4 follows this visual structure:

```
VStack {
    Spacer()
    Image(systemName: ...)          // SF Symbol illustration, ~120pt, accent tinted
        .font(.system(size: 90))
        .foregroundStyle(.tint)
    Text(title)                     // .largeTitle, bold
    Text(description)               // .body, .secondary, multiline centered
    Spacer()
    primaryButton                   // NavigationLink or action button
    secondaryButton (optional)      // "Skip" for page 4 only
}
.padding(.horizontal, 32)
.multilineTextAlignment(.center)
.navigationBarBackButtonHidden(true)
```

### SF Symbols per page

| Page | SF Symbol |
|---|---|
| 1 – Welcome | `"leaf.circle.fill"` |
| 2 – Activities | `"plus.circle.fill"` |
| 3 – Trips | `"map.fill"` |
| 4 – HealthKit | `"heart.fill"` |

### Page 4 — HealthKit Permission

This page must:
1. Call `HealthKitManager.shared.requestAuthorization { _ in }` when the primary button is tapped.
2. Navigate to page 5 regardless of the outcome (authorization denial is fine — user can grant it later from Settings).
3. Provide a "Skip" button that navigates to page 5 without requesting.

```swift
// Relevant HealthKit manager API (already exists in HealthKitManager.swift):
// func requestAuthorization(completion: @escaping (Bool) -> Void)
// Reads: HKQuantityType.stepCount + HKQuantityType.distanceWalkingRunning
// No write access is requested.
```

### Page 5 — Embedded Paywall

The last destination wraps `SubscriptionStoreView` directly and sets `hasCompletedOnboarding = true` on appearance so the onboarding is always dismissed after this point.

```swift
struct OnboardingPaywallPage: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var storeKit = Store()
    @State private var showLifetime = false

    var body: some View {
        SubscriptionStoreView(groupID: storeKit.groupId) {
            VStack {
                Button {
                    showLifetime = true
                } label: {
                    Label("Save with Lifetime plans", systemImage: "sparkle")
                        .font(.headline)
                }
                .tint(.purple)
                .buttonStyle(.borderedProminent)
                .buttonBorderShape(.capsule)

                Button(String(localized: "Maybe Later")) {
                    hasCompletedOnboarding = true
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .padding(.top, 8)
            }
            .frame(minHeight: 300)
        }
        .subscriptionStoreControlStyle(.pagedProminentPicker, placement: .bottomBar)
        .subscriptionStoreButtonLabel(.multiline)
        .storeButton(.visible, for: .restorePurchases)
        .storeButton(.hidden, for: .cancellation)
        .tint(.primary)
        .sheet(isPresented: $showLifetime) {
            PaywallLifetimeView()
                .presentationDetents([.medium])
        }
        .onAppear {
            hasCompletedOnboarding = true   // mark done whether or not user pays
        }
        .navigationBarBackButtonHidden(true)
    }
}
```

### NavigationLink wiring

Wire pages together with `NavigationLink(destination:)`. Each page's primary button is a `NavigationLink`:

```swift
NavigationLink(destination: OnboardingActivitiesPage()) {
    Text("Get Started")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding()
        .background(.tint)
        .foregroundStyle(.white)
        .clipShape(RoundedRectangle(cornerRadius: 14))
}
```

For page 4 (HealthKit), use an `@State var navigateToPaywall = false` boolean and a `NavigationLink(isActive:destination:)` pattern triggered by the button action, since the navigation must happen inside the async `requestAuthorization` completion:

```swift
@State private var navigateToPaywall = false

NavigationLink(destination: OnboardingPaywallPage(), isActive: $navigateToPaywall) {
    EmptyView()
}

Button(String(localized: "Allow Health Access")) {
    HealthKitManager.shared.requestAuthorization { _ in
        navigateToPaywall = true
    }
}
```

> **Note on `NavigationLink(isActive:)` deprecation:** In iOS 16+ the `isActive:` form is deprecated in favour of `navigationDestination(isPresented:)`. Use the newer pattern if you prefer:
> ```swift
> .navigationDestination(isPresented: $navigateToPaywall) { OnboardingPaywallPage() }
> ```

---

## Existing Code Context

### HealthKitManager (already exists — do not modify)

```swift
// trackCO2/trackCO2/Utils/HealthKitManager.swift
@Observable class HealthKitManager {
    static let shared = HealthKitManager()

    func requestAuthorization(completion: @escaping (Bool) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else { completion(false); return }
        // Requests read access for stepCount + distanceWalkingRunning
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, _ in
            DispatchQueue.main.async { completion(success) }
        }
    }
}
```

### Store (already exists — do not modify)

```swift
// Key properties used in OnboardingPaywallPage:
// storeKit.groupId  → String, the subscription group ID ("21727569")
```

### PaywallView (already exists — reference only)

`PaywallView` wraps `SubscriptionStoreView` in its own `NavigationStack`. **Do NOT push `PaywallView` as a NavigationLink destination** — that would nest NavigationStacks. Instead, replicate only the `SubscriptionStoreView` content in `OnboardingPaywallPage` (as shown above).

### PaywallLifetimeView (already exists — reuse as-is)

Present it as `.sheet(isPresented:)` from `OnboardingPaywallPage`, identical to how `PaywallView` does it.

---

## Constraints

1. **No nested NavigationStacks** — `OnboardingView` owns the only `NavigationStack` in the flow.
2. **No back button on any page** — add `.navigationBarBackButtonHidden(true)` to every page.
3. **Onboarding shows only once** — `@AppStorage("hasCompletedOnboarding")` persists across launches.
4. **HealthKit denial is fine** — always navigate forward regardless of the authorization outcome.
5. **No Combine** — use async/await or completion callbacks.
6. **Localize every string** — add new keys to all 12 localization files (not just `en`).
7. **Do not modify** `HealthKitManager.swift`, `PaywallView.swift`, `PaywallLifetimeView.swift`, or `Store.swift`.
8. After editing, run `XcodeRefreshCodeIssuesInFile` on both `OnboardingView.swift` and `ContentView.swift`.

---

## Project Context

- **Project root:** `/Users/m1pro/Developer/trackCO2/`
- **Deployment target:** iOS 18.5
- **Build tool:** `BuildProject` MCP command
- **Quick diagnostics:** `XcodeRefreshCodeIssuesInFile` MCP command
- **Docs lookup:** `DocumentationSearch` MCP command
- **Code style:** 4-space indent, no comments unless why is non-obvious, no Combine, PascalCase types, camelCase properties.
- **Localization pattern:** `String(localized: "key")` in Swift, `Text("key")` in SwiftUI.
- **Localization files location:** `trackCO2/trackCO2/Localizable.strings/<lang-code>` — one file per language, 12 total.
