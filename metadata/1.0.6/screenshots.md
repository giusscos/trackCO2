# Screenshot Guide — trackCO2 v1.0.6

Technical requirements and visual direction for App Store marketing screenshots.

---

## Required device sizes (iPhone)

Upload at least one set. Apple displays the 6.7" set on most product pages; provide both for best coverage.

| Display | Device examples | Portrait size (px) | Required |
|---|---|---|---|
| 6.7" | iPhone 16 Pro Max, 15 Pro Max, 14 Pro Max | **1290 × 2796** | Yes (primary) |
| 6.5" | iPhone 11 Pro Max, XS Max | **1242 × 2688** | Yes (fallback) |
| 6.1" | iPhone 16, 15, 14, 13 | 1179 × 2556 | Optional |
| 5.5" | iPhone 8 Plus | 1242 × 2208 | Optional (legacy) |

### iPad (if distributing for iPad)

| Display | Size (px) | Orientation |
|---|---|---|
| 12.9" / 13" | 2048 × 2732 | Portrait |
| 11" | 1668 × 2388 | Portrait |

---

## How to capture

### Option A — SwiftUI Previews (recommended)

The project includes dedicated screenshot scenes in `trackCO2/Preview/`:

| File | Purpose |
|---|---|
| `AppStoreScreenshotPreviews.swift` | 5 `#Preview` scenes sized for iPhone 6.7" |
| `PreviewSampleData.swift` | In-memory SwiftData demo activities/events |
| `ScreenshotSupport.swift` | Tab shell, mock weather/steps, map placeholder |
| `ScreenshotExporter.swift` | `ImageRenderer` export to PNG |

**In Xcode:**

1. Open `AppStoreScreenshotPreviews.swift`
2. Enable the preview canvas (Editor → Canvas)
3. Use the **Marketing 01–05** previews for App Store–ready compositions (headline + device frame + white background — same style as professional App Store listings)
4. Use the raw **01–05** previews if you only need the app UI without marketing copy
5. Set the simulator language to match your App Store locale before refreshing previews
6. Export either:
   - **Automated (recommended):** Open `ScreenshotExporter.swift` → run **Screenshot Export** → tap **Export Marketing Screenshots**
   - **Manual:** Right-click a preview → **Save Image** (when available)

Marketing layouts (see `AppStoreMarketingScreenshot.swift`):

| Slide | Layout | Copy |
|---|---|---|
| 01 Summary | Bottom caption + fade | "Everything in one **score**." |
| 02 Activities | Top caption + dual phones | "**16+** activity types." |
| 03 Trips | Top caption + single phone | "**Pick** the greenest route." |
| 04 Tips | Bottom caption + fade | "Tips backed by **your data**." |
| 05 Weather | Bottom caption + fade | "Walk when it's **worth it**." |

Edit headlines in `AppStoreMarketingCopy` inside `AppStoreMarketingScreenshot.swift`. For localized App Store listings, duplicate the copy values per locale or wire them to your metadata `.md` files.

Exported PNGs are written to **Documents/AppStoreScreenshots/** in the Simulator (1290×2796 px). Retrieve them via Simulator → **File → Open Simulator Data Folder** → your app container → Documents.

### Option B — Simulator device screenshots

1. Run the app on a **physical device** or Simulator matching the target size (e.g. iPhone 16 Pro Max).
2. Use **light mode** as the default; optionally add one dark-mode screenshot if it looks strong.
3. Populate **realistic sample data** before capture (see Data setup below).
4. Capture with **Simulator → File → Save Screen** or **Device screenshot** (Side button + Volume up).
5. Do **not** add device frames in the raw export — App Store Connect applies frames automatically if enabled.
6. Export as **PNG**, sRGB, no alpha channel issues, no status-bar glitches (hide debug banners).

### Data setup (recommended demo state)

| Screen | Data to show |
|---|---|
| Home / Summary | Claud mascot at **Good** or **Thriving** health (~70–90%); weekly CO₂ chart with visible bars; compensation + consumption cards with non-zero values; weather widget showing a positive walking suggestion |
| Trips / Map | Route drawn on map (city context); transport comparison cards with train/bus/walk options; greenest option highlighted first |
| Activities | Mix of transport, food, and eco activities; several logged events this week |
| Tips / Trends | At least one smart tip with real CO₂ numbers; weekly trend visible |
| What's New | Shown only if capturing for release notes marketing — optional as screenshot |

---

## Visual style rules

| Rule | Detail |
|---|---|
| **Background** | Use the app's native SwiftUI background (system grouped background). Avoid custom gradients behind the phone mockup. |
| **Clutter** | Hide keyboard, sheets, and alerts unless the screenshot topic is that interaction. |
| **Mascot** | Claud (cloud mascot) should appear healthy (mint/green tones) in hero shots — not Sick/Tired unless illustrating a feature. |
| **Localization** | Capture screenshots on a device/simulator set to the **same language** as the App Store locale you're uploading to. |
| **Text overlays** | Optional marketing captions *outside* the screenshot canvas (see per-locale `.md` files). If burned into the image, use SF Pro, large title weight, max 5–7 words, high contrast. |
| **Consistency** | Use the same 5-scene story arc across all locales (only the UI language changes). |

---

## Recommended 5-screenshot story arc

Upload screenshots in this order (1 = first image users see):

### Screenshot 1 — Hero / Dashboard
**Screen:** Summary (Home tab)  
**Shows:** Claud mascot with health score, weekly CO₂ chart, weather suggestion card  
**Goal:** Immediate understanding — "track your carbon footprint at a glance"  
**Look:** Top of scroll view, mascot fully visible, chart showing both emitted (red/orange) and saved (green) data

### Screenshot 2 — Log activities
**Screen:** Activities tab or Add Activity flow  
**Shows:** Activity list with icons (car, train, walking, food) and recent events  
**Goal:** "Log anything that affects your footprint"  
**Look:** Clean list, 5–8 activities, varied categories

### Screenshot 3 — Greener trips
**Screen:** Trips / Map with route comparison  
**Shows:** Map with polyline route; swipeable transport cards below; CO₂ saved/emitted labels  
**Goal:** "Compare transport and pick the greenest route"  
**Look:** Urban map, walking or transit highlighted as best option

### Screenshot 4 — Smart insights
**Screen:** Tips widget expanded or ListTipsView  
**Shows:** Data-driven tip with kg CO₂ figures (e.g. substitution or offset gap)  
**Goal:** "Actionable tips from your real data"  
**Look:** One clear tip card, readable numbers

### Screenshot 5 — Weather-aware nudges
**Screen:** WeatherSuggestionView or weather forecast detail  
**Shows:** "Great time to walk!" (or localized equivalent) with weather context  
**Goal:** "Walk when the weather is right"  
**Look:** Sunny/clear condition, positive mascot speech bubble if visible

---

## File naming convention

Store exported files under `metadata/1.0.6/screenshots/<locale>/`:

```
01-hero-summary.png
02-activities.png
03-trips-map.png
04-smart-tips.png
05-weather-nudges.png
```

For multiple device sizes, append the size:

```
01-hero-summary-6.7.png
01-hero-summary-6.5.png
```

---

## App Preview video (optional)

| Spec | Value |
|---|---|
| Length | 15–30 seconds |
| Format | M4V, MP4, or MOV |
| Resolution | Match screenshot size for target device |
| Content | Quick montage: open app → see Claud → log activity → compare trip → view tip |
| Audio | None or subtle background music (no required narration) |

---

## Common rejections to avoid

- Placeholder text ("Lorem ipsum") or empty states with "No data"
- Debug builds showing "Environment: Sandbox" or StoreKit test banners
- Misleading CO₂ claims not supported by in-app calculations
- Screenshots that don't reflect actual app UI (mockups only)
- Wrong language UI for the uploaded locale
