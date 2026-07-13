# Prompt: Add "What's New" Full-Screen Cover

## Goal

Create a `WhatsNewView.swift` in `trackCO2/View/` that presents as a `.fullScreenCover` the first time users open the app after an update. It must share the visual DNA of `PaywallView` — the `PaywallBenefitRow` card style, mascot, staggered entrance animations — but carry no purchase logic.

---

## Trigger Logic

- Add a `@AppStorage("lastSeenVersion") private var lastSeenVersion: String = ""` to `ContentView` (or `trackCO2App`).
- Compare it against `Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""`.
- If they differ, present `WhatsNewView` as a `.fullScreenCover`. On dismiss, write the current version to `lastSeenVersion`.

---

## Visual Structure

### 1 — Header: Mascot + Title

- Display `ClaudCloudView` (the same component used in `PaywallView`) with `ClaudHealth(score: 0.95)` so Claud looks thriving and happy.
- Scale it to `1.2` with `.scaleEffect(1.2)` and add `.padding(.vertical, 8)`.
- Below the mascot:
  - Title: **"What's New in trackCO2"** — `.font(.title2).fontWeight(.bold).multilineTextAlignment(.center)`
  - Subtitle: **"Here's what we've been working on for you."** — `.font(.subheadline).foregroundStyle(.secondary).multilineTextAlignment(.center)`

### 2 — Feature Cards (reuse `PaywallBenefitRow` or extract a shared component)

Use the exact same `PaywallBenefitRow` struct (icon · tinted circle background · left-to-right staggered slide-in animation). Define these four features:

| index | icon | accent | text |
|-------|------|--------|------|
| 0 | `"theatermasks.fill"` | `.purple` | `"Meet your new mascot — Claud now reacts to your CO₂ score in real time."` |
| 1 | `"cloud.sun.bolt.fill"` | `.cyan` | `"Weather-aware tips — Claud checks local conditions to suggest the best time to walk, cycle, or take transit."` |
| 2 | `"sparkles"` | `.orange` | `"A cleaner, faster experience — redesigned cards, smoother navigation, and a more intuitive layout throughout the app."` |
| 3 | `"map.fill"` | `.blue` | `"New Maps experience — plan greener trips with live transport comparison and CO₂ estimates on the map."` |

### 3 — CTA Button

A single prominent "Continue" button at the bottom that dismisses the cover:

```swift
Button {
    dismiss()
} label: {
    Text("Continue")
        .font(.headline)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
}
.buttonStyle(.borderedProminent)
.buttonBorderShape(.capsule)
.padding(.horizontal, 24)
.padding(.bottom, 12)
```

On iOS 26+ wrap it in the same `GlassLifetimeButtonStyle` modifier pattern already used in `PaywallView` so it gets `.buttonStyle(.glass)` automatically.

---

## Full Layout Skeleton

```swift
struct WhatsNewView: View {
    @Environment(\.dismiss) private var dismiss

    private let health = ClaudHealth(score: 0.95)

    private struct Feature: Identifiable {
        var id: String { icon }
        let icon: String
        let accent: Color
        let text: LocalizedStringKey
    }

    private let features: [Feature] = [ /* four rows above */ ]

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                // Header
                VStack(spacing: 6) {
                    ClaudCloudView(
                        color: health.cloudBodyColor,
                        baseEyeOpenness: health.baseEyeOpenness,
                        isHungry: false
                    )
                    .scaleEffect(1.2)
                    .padding(.vertical, 8)

                    Text("What's New in trackCO2")
                        .font(.title2)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)

                    Text("Here's what we've been working on for you.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }

                // Feature cards
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
        .safeAreaInset(edge: .bottom) {
            // CTA
            Button { dismiss() } label: {
                Text("Continue")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
            }
            .modifier(GlassLifetimeButtonStyle())   // or .borderedProminent on older OS
            .padding(.horizontal, 24)
            .padding(.bottom, 12)
            .background(.ultraThinMaterial)
        }
    }
}
```

---

## Sharing `PaywallBenefitRow`

`PaywallBenefitRow` is currently `private` inside `PaywallView.swift`. Before building `WhatsNewView`, move it (and `GlassLifetimeButtonStyle`) to a new file:

```
trackCO2/View/Components/PaywallBenefitRow.swift
```

Change their access level from `private struct` to `struct` (internal). Update `PaywallView.swift` to remove its local definitions and rely on the shared file. No other behaviour changes.

---

## Localisation

Add these keys to **all** `.lproj/Localizable.strings` files (translate appropriately):

```
"whats_new.title" = "What's New in trackCO2";
"whats_new.subtitle" = "Here's what we've been working on for you.";
"whats_new.feature.mascot" = "Meet your new mascot — Claud now reacts to your CO₂ score in real time.";
"whats_new.feature.weather" = "Weather-aware tips — Claud checks local conditions to suggest the best time to walk, cycle, or take transit.";
"whats_new.feature.ui" = "A cleaner, faster experience — redesigned cards, smoother navigation, and a more intuitive layout throughout the app.";
"whats_new.feature.maps" = "New Maps experience — plan greener trips with live transport comparison and CO₂ estimates on the map.";
"whats_new.cta" = "Continue";
```

Use `LocalizedStringKey` throughout `WhatsNewView` so all strings resolve from the strings file.

---

## Checklist

- [ ] Move `PaywallBenefitRow` and `GlassLifetimeButtonStyle` to `View/Components/`
- [ ] Create `WhatsNewView.swift` matching the layout above
- [ ] Wire `.fullScreenCover` in `ContentView` / `trackCO2App` with version-based trigger
- [ ] Add localisation keys to all 12 `.lproj` files
- [ ] Add `#Preview` for `WhatsNewView`
- [ ] Build and verify staggered animations and dismiss flow work correctly
