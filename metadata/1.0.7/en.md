# Claud CO2 — App Store Connect Metadata

**Version:** 1.0.7  
**Locale:** English (U.S.)  
**Locale code:** `en`

---

## App Information

| Field | Value | Limit | Count |
|---|---|---|---|
| **Name** | Claud CO2 | 30 | 9 |
| **Subtitle** | Track Your Carbon Footprint | 30 | 28 |
| **Promotional Text** | Meet Claud — your cloud mascot that reacts to your CO₂ score. Log activities, plan greener trips, and get weather-smart walking tips. | 170 | 119 |

> Promotional Text can be updated anytime without a new app version.

---

## Keywords

```
carbon,footprint,CO2,climate,sustainability,eco,green,transport,health,weather,tips
```

**Limit:** 100 characters · **Count:** 78

---

## Description

Claud CO2 helps you understand and reduce your personal carbon footprint — one day at a time.

Log the activities that matter: driving, flying, public transport, food choices, home energy, walking, biking, tree planting, and recycling. See your real CO₂ consumption and compensation build up over the week with clear charts and summaries.

**Meet Claud, your carbon mascot**  
Claud is a friendly cloud that reflects your weekly CO₂ health. Make greener choices and watch Claud thrive. Skip too many eco-friendly habits and Claud will let you know.

**Plan greener trips**  
Use the built-in map to compare transport options side by side. Routes are ranked by CO₂ impact — the greenest option is always shown first. Save trips directly to your activity log.

**Sync with Apple Health**  
Automatically import step count and walking/running distance from HealthKit. Turn everyday movement into logged compensation without extra effort.

**Weather-smart suggestions**  
Claud checks local weather and air conditions to nudge you toward walking or cycling when conditions are good — and warns you when outdoor activity isn't advisable.

**Smart, data-driven tips**  
Get personalized insights based on your logged activities: usage trends, high-impact emitters, offset gaps, food swaps, and greener alternatives with real kg CO₂ numbers.

**Track trends over time**  
Weekly trends, consumption vs. compensation breakdowns, and your most-used activities help you spot patterns and improve.

Subscriptions and lifetime plans unlock the full Claud CO2 experience. Start your journey to a greener lifestyle today.

---

## What's New in This Version

**Version 1.0.7**

- Meet your new mascot — Claud now reacts to your CO₂ score in real time
- Weather-aware tips — Claud checks local conditions to suggest the best time to walk, cycle, or take transit
- Smarter activity tips — data-driven insights with real CO₂ numbers, usage trends, and actionable suggestions
- A cleaner, faster experience — redesigned cards, smoother navigation, and a more intuitive layout
- New Maps experience — plan greener trips with live transport comparison and CO₂ estimates on the map

---

## URLs

| Field | URL |
|---|---|
| **Support URL** | `https://giusscos.com/trackco2/support` |
| **Marketing URL** | `https://giusscos.com/trackco2` |
| **Privacy Policy URL** | `https://giusscos.com/trackco2/privacy` |

> Replace with live URLs before submission.

---

## Categories

| | Category |
|---|---|
| **Primary** | Health & Fitness |
| **Secondary** | Lifestyle |

---

## In-App Purchases & Subscriptions

Copy into App Store Connect → Subscriptions / In-App Purchases → [product] → [locale].

### Subscription group: Claud+

| Field | Value |
|---|---|
| **Reference name** | Claud+ |
| **Display name** | Claud+ |
| **Description** | Premium access to Claud CO2 |

### Subscriptions

| Product ID | Reference | Display name | Description |
|---|---|---|---|
| `fp_499_1w` | Claud+ Weekly | Claud+ | Get unlimited access for this week |
| `fp_1999_1y_1w` | Claud+ Yearly | Claud+ | Get unlimited access for this year |

### Lifetime purchases (non-consumable)

| Product ID | Reference | Display name | Description |
|---|---|---|---|
| `com.giusscos.footprintLifetime` | Claud CO2 Lifetime | Claud CO2 Lifetime | Lifetime unlimited access |
| `com.giusscos.footprintFamilyLifetime` | Claud CO2 Family Lifetime | Claud CO2 Family Lifetime | Lifetime unlimited access for your family |

---

## App Review Information — Notes (paste into ASC)

```
WeatherKit: Yes — used for local walking/cycling suggestions on Home and the Weather Forecast screen.

Attribution (Guideline 5.2.5): The  Weather trademark mark and “Other data sources” legal link (WeatherService.attribution) are shown:
1) Directly under the weather suggestion card on Home
2) In the footer of Weather Forecast (tap the weather card)

Screen recording on a physical device is attached / will be attached showing both locations.
```

## Age Rating Notes

- HealthKit: reads step count and walking/running distance (no medical data)
- Location: used when in app for map, trip planning, and local weather
- No unrestricted web access, gambling, or user-generated public content

### Suggested caption overlays (optional marketing text)

| # | Screen | Caption |
|---|---|---|
| 1 | Summary / Dashboard | Know your CO₂ at a glance |
| 2 | Activities | Log every climate **choice** |
| 3 | Trips / Map | Pick the **greenest** route |
| 4 | Smart Tips | **Tips** backed by your data |
| 5 | Weather | **Walk** when it's worth it |

### How each screenshot should look

1. **Hero** — Claud mascot (green/mint, "Good" or "Thriving"), weekly CO₂ bar chart with data, weather card visible below chart.
2. **Activities** — List showing Car Travel, Train Travel, Walking, Beef Consumption, etc. with recent quantities logged.
3. **Trips** — City map with route polyline; bottom card carousel comparing walk vs. bus vs. car with CO₂ labels.
4. **Tips** — Expanded tips view showing a specific tip with kg CO₂ figures (e.g. "Replacing 2 trips would save ~3.2 kg CO₂").
5. **Weather** — Weather suggestion card with positive message ("Great time to walk!") and clear sky icon.

Capture on **iPhone 16 Pro Max** simulator (1290×2796) with **English (U.S.)** system language.
