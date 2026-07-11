# Onboarding & Paywall Improvements

## Context

This is the **trackCO2** SwiftUI app. It tracks personal carbon footprint and has an onboarding flow (5 screens) followed by a paywall. The relevant files are:

- `trackCO2/View/Onboarding/OnboardingView.swift` — 5-page linear onboarding flow
- `trackCO2/View/PaywallView.swift` — StoreKit 2 subscription paywall
- `trackCO2/ContentView.swift` — shows onboarding via `.fullScreenCover`

---

## OnboardingView — Issues to Fix

### 1. No back-button suppression
Every page from page 2 onward shows a "Back" chevron in the navigation bar because the flow uses `NavigationStack` + `NavigationLink`. Onboarding should be forward-only.

**Fix:** Add `.navigationBarBackButtonHidden(true)` to each page's body (pages 2–5), or apply it inside `OnboardingPageLayout.body`.

---

### 2. `OnboardingHealthKitPage` duplicates layout boilerplate
Pages 1–3 correctly use the shared `OnboardingPageLayout` component (which handles VStack, Spacer, padding, multilineTextAlignment, and the button style). `OnboardingHealthKitPage` ignores it and manually duplicates all that boilerplate.

The reason is the primary button needs conditional label and conditional action. Fix by extending `OnboardingPageLayout` to accept a custom primary button, or by making `OnboardingPageLayout` accept a `primaryButton` closure instead of a `buttonTitle`/`destination` pair. Then rewrite `OnboardingHealthKitPage` to use it like the other pages.

---

### 3. Silent failure when HealthKit is permanently denied
In `requestHealthAccess()`:
```swift
guard !isHealthDataDenied() else { return }
```
When HealthKit is denied in Settings, the user taps "Allow Health Access" and **nothing happens** — no feedback, no redirect. This is confusing UX.

**Fix:** When `isHealthDataDenied()` is true, show an alert with a "Open Settings" button that deep-links to `UIApplication.openSettingsURLString`.

---

### 4. HealthKit logic at file scope
`healthTypesToRead`, `isHealthDataDenied()`, and `checkHealthAccessGranted()` are free-standing private functions at file scope. They should be moved into `HealthKitManager` (which already exists) so the logic lives in one place and `OnboardingHealthKitPage` just calls into the manager.

---

### 5. No onboarding progress indicator
Users have no sense of where they are in the 5-step flow. Add a simple page-dot indicator (e.g., `HStack` of filled/unfilled circles) to `OnboardingPageLayout`, driven by a `currentPage: Int` and `totalPages: Int` parameter.

---

## PaywallView — Issues to Fix

### 6. `@State var` properties are not private
```swift
@State var storeKit = Store()
@State var activeSheet: ActiveSheet?
```
Both should be `@State private var`. This is a correctness issue — `var` without `private` exposes them to external mutation.

---

### 7. `ActiveSheet` enum with a single case — unnecessary abstraction
The enum exists only for `.lifetimePlan`. Since there's one sheet, simplify to:
```swift
@State private var showingLifetimePlan = false
```
Remove the `ActiveSheet` enum entirely and replace `activeSheet = .lifetimePlan` with `showingLifetimePlan = true`, and `.sheet(item: $activeSheet)` with `.sheet(isPresented: $showingLifetimePlan)`.

---

### 8. Benefits array uses position-based ID
```swift
ForEach(Array(benefits.enumerated()), id: \.offset) { _, benefit in
```
ID-by-position is fragile and disables SwiftUI's identity-based diffing. Define a small struct:
```swift
private struct Benefit: Identifiable {
    let id = UUID()
    let icon: String
    let text: LocalizedStringKey
}
```
Then use `ForEach(benefits)` directly.

---

### 9. Hardcoded purple tint for lifetime button
```swift
.tint(.purple)
```
This overrides the app's tint and may clash with dark mode or custom accent colors. Use a named color from the asset catalog or remove the override and let the system tint apply.

---

### 10. Missing spacing between ScrollView content sections
The `ScrollView { VStack { ... } }` inside `SubscriptionStoreView` has no padding or spacing between the header block, the benefits list, and the lifetime button. Add `.padding(.vertical)` to the outer VStack or explicit `.padding(.top, 16)` between sections.

---

### 11. Duplicated `hasPaid` logic
`ContentView` and `PaywallView` both define:
```swift
var hasPaid: Bool {
    !store.purchasedSubscriptions.isEmpty || !store.purchasedProducts.isEmpty
}
```
This duplication means if `Store`'s data model changes, two places must be updated. Move `hasPaid` as a computed property onto `Store` itself.

---

## Summary of all changes

| # | File | Change |
|---|------|--------|
| 1 | OnboardingView | Add `.navigationBarBackButtonHidden(true)` to pages 2–5 |
| 2 | OnboardingView | Refactor `OnboardingHealthKitPage` to use `OnboardingPageLayout` |
| 3 | OnboardingView | Show Settings alert when HealthKit is permanently denied |
| 4 | OnboardingView / HealthKitManager | Move `isHealthDataDenied` / `checkHealthAccessGranted` into `HealthKitManager` |
| 5 | OnboardingView | Add page-dot progress indicator to `OnboardingPageLayout` |
| 6 | PaywallView | Make `storeKit` and `activeSheet` private |
| 7 | PaywallView | Replace `ActiveSheet` enum with `showingLifetimePlan: Bool` |
| 8 | PaywallView | Replace `.enumerated()` with an `Identifiable` `Benefit` struct |
| 9 | PaywallView | Remove hardcoded `.tint(.purple)` |
| 10 | PaywallView | Fix missing spacing between ScrollView sections |
| 11 | Store / PaywallView / ContentView | Move `hasPaid` onto `Store` |

Apply all changes. Do not refactor anything else beyond this list.
