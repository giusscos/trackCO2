# Activity Tips Improvement Prompt

## Context

The app currently has two tips surfaces:

- **TipsView** (widget on SummaryView): shows a single generic tip based on the most-used activity — either "Great job, keep it up!" (CO2-reducing) or "Try to reduce X" (emitting). Completely binary, no numbers, no nuance.
- **ListTipsView**: shows one flat tip per activity using the same binary logic. No quantities, no trends, no cross-activity reasoning.

Available data that is currently **not used** in tip generation:

| Field | Source | Value for tips |
|---|---|---|
| `ActivityEvent.quantity` | Per event | Actual amount (km, kg, kWh) used each time |
| `ActivityEvent.createdAt` | Per event | Frequency, recency, trends over time |
| `Activity.co2Emission` | Per activity | Emission factor → calculate real kg CO₂ per event |
| `Activity.type` | Per activity | Category grouping (transport, food, energy, reduction) |
| Cross-activity totals | Derived | Net CO₂ balance, offset ratio, highest-impact emitter |

---

## Goal

Replace the current binary good/bad tips with **smart, data-driven, actionable tips** that:

1. Are **specific** — include real numbers (kg CO₂, km, %, counts).
2. Are **contextual** — reflect actual usage patterns, not just "you use X".
3. Are **actionable** — suggest a concrete next step, not just an observation.
4. Have **priority** — surface the highest-impact change first, not the most frequent activity.
5. Cover **multiple insight types** — trend, substitution, net balance, streak, milestone.

---

## Tip Categories to Implement

### 1. High-Impact Emitter Alert
Show for the activity with the **highest total CO₂** this month (not most frequent).

> "✈️ Airplane flights are your biggest source — **42 kg CO₂** this month. That's 80% of your total emissions."

Logic: `sum(event.quantity * activity.co2Emission)` per activity → find max → express as % of total.

---

### 2. Substitution Tip
When a high-emitting transport activity exists AND a lower-emitting alternative exists in the user's activity list.

> "🚗 You drove 120 km this week. Replacing 2 trips with 🚆 train would save ~**6.6 kg CO₂** (47% less per km)."

Logic: compare `co2Emission` between same-category activities → compute savings for average trip distance.

---

### 3. Offset Gap
Show the gap between total emissions and total offsets.

> "This month you emitted **28 kg CO₂** but only offset **4 kg**. Planting 2 more trees would close the gap by 40 kg/year."

Logic: `sum emitting events` vs `sum CO2-reducing events` → compute gap and suggest a specific offset activity.

---

### 4. Trend Tip (Week-over-Week)
Compare this week vs. last week for the top emitter.

> "📈 Your car usage is up 30% vs. last week (+2.1 kg CO₂). Small changes add up — try one car-free day."

Logic: group events by ISO week → compare current vs. previous → flag increases > 20%.

---

### 5. Streak / Positive Momentum
When the user has logged a CO₂-reducing activity on N consecutive days.

> "🚲 You've biked 5 days in a row! That's **3.75 kg CO₂** avoided — the equivalent of skipping 25 km by car."

Logic: check consecutive days with events for a CO2-reducing activity → compute total avoided.

---

### 6. Food Swap Tip
When beef or dairy are in the top 3 by total CO₂.

> "🥩 Beef has a very high footprint (**60 kg CO₂/kg**). Swapping one meal per week to 🥕 vegetables saves ~**4.7 kg CO₂/month**."

Logic: compare beef/dairy `co2Emission` to vegetables → compute monthly savings at 1 swap/week.

---

### 7. Milestone / Celebration
When the user's cumulative offset reaches a meaningful milestone.

> "🌳 You've offset **100 kg CO₂** total! That's like taking a car off the road for 2 weeks."

Logic: track cumulative total of all CO2-reducing events → fire at 10 / 50 / 100 / 500 kg thresholds.

---

### 8. Inactivity Nudge
When no events have been logged in the past 7 days (for an activity the user was using regularly).

> "You haven't logged 🚶 walking in 5 days. Even a 2 km walk offsets 300 g CO₂."

Logic: find activities with ≥ 3 events historically but no event in the last 7 days.

---

## Tip Priority Order

When multiple tips are applicable, show in this order in the widget (pick the top 1) and show all in ListTipsView:

1. High-impact emitter alert (most actionable)
2. Trend alert (urgent, time-sensitive)
3. Offset gap (motivating)
4. Substitution tip (practical)
5. Food swap tip
6. Streak / milestone (positive reinforcement)
7. Inactivity nudge
8. Generic fallback (current behavior) — only if no events at all

---

## Implementation Notes

- **No external model required** — all logic is computable from SwiftData queries on `Activity` + `ActivityEvent`.
- **`TipsModel`** already exists as a SwiftData entity with `message: String` and a relationship to `Activity`. Tips could be pre-generated on app launch and persisted, or computed on the fly using `var` computed properties.
- **Tip generation function** should accept `[Activity]` (with their events loaded) and return a `[GeneratedTip]` array sorted by priority.
- **Localization**: tip strings must go into `Localizable.strings` for all 12 supported locales (en, en-GB, en-CA, de, es, fr, it, nb, nl, pt, pt-BR, sv). Use format strings with `%@` / `%.1f` placeholders for the numeric values.
- **`ListTipsView`**: replace the current per-activity flat list with the prioritized tip list. Keep the activity emoji + name as context, but lead with the insight.
- **`TipsView` widget**: show the single highest-priority tip. Truncate to 2 lines max.

---

## Files to Modify

| File | Change |
|---|---|
| `View/SummaryWidget/TipsView.swift` | Replace `tipMessage` computed var with call to tip generator |
| `View/SummaryWidgetDetails/ListTipsView.swift` | Replace flat per-activity list with prioritized `[GeneratedTip]` list |
| New: `Utils/TipGenerator.swift` | Pure Swift struct/function — takes `[Activity]`, returns `[GeneratedTip]` sorted by priority |
| New: `Model/GeneratedTip.swift` | Value type: `struct GeneratedTip { var priority: Int; var title: String; var message: String; var activity: Activity? }` |
| `Localizable.strings` (all 12 locales) | Add localization keys for each tip template |

---

## Example `TipGenerator` Signature

```swift
struct TipGenerator {
    static func generate(from activities: [Activity]) -> [GeneratedTip]
}

struct GeneratedTip: Identifiable {
    let id = UUID()
    var priority: Int        // lower = higher priority
    var title: String        // e.g. "High Impact Emitter"
    var message: String      // the human-readable tip
    var activity: Activity?  // the related activity, for emoji/name display
    var isPositive: Bool     // true for streaks/milestones, false for warnings
}
```
