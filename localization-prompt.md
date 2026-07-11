# trackCO2 — Localization Task

Add full localization to the iOS app **trackCO2** located at `/Users/m1pro/Developer/trackCO2`.

---

## Languages to add

| Code | Language |
|------|----------|
| `en` | English (US — base) |
| `en-GB` | English (UK) |
| `en-CA` | English (Canada) |
| `it` | Italian |
| `de` | German |
| `es` | Spanish |
| `fr` | French |
| `pt` | Portuguese |
| `pt-BR` | Portuguese (Brazil) |
| `nl` | Dutch |
| `sv` | Swedish |
| `nb` | Norwegian Bokmål |

---

## File structure

Create one `Localizable.strings` inside each `.lproj` folder:

```
trackCO2/trackCO2/en.lproj/Localizable.strings
trackCO2/trackCO2/en-GB.lproj/Localizable.strings
trackCO2/trackCO2/en-CA.lproj/Localizable.strings
trackCO2/trackCO2/it.lproj/Localizable.strings
trackCO2/trackCO2/de.lproj/Localizable.strings
trackCO2/trackCO2/es.lproj/Localizable.strings
trackCO2/trackCO2/fr.lproj/Localizable.strings
trackCO2/trackCO2/pt.lproj/Localizable.strings
trackCO2/trackCO2/pt-BR.lproj/Localizable.strings
trackCO2/trackCO2/nl.lproj/Localizable.strings
trackCO2/trackCO2/sv.lproj/Localizable.strings
trackCO2/trackCO2/nb.lproj/Localizable.strings
```

---

## Xcode project & Info.plist changes

1. Add every language code as a `knownRegions` entry in `trackCO2.xcodeproj/project.pbxproj`.
2. Add a `PBXFileReference` + `PBXVariantGroup` entry for each `Localizable.strings` variant.
3. Add `CFBundleLocalizations` array to `trackCO2/trackCO2/Info.plist` listing all codes above.

---

## Swift files that need updating

SwiftUI `Text("literal")` auto-localizes — **do not change those**.  
The following computed `String` properties will NOT auto-localize and must be updated to use `String(localized: "key")`:

### 1. `trackCO2/trackCO2/View/Mascot/ClaudMascotView.swift`

`ClaudHealth.label`, `ClaudHealth.message`, `ClaudHealth.hungryMessage` — wrap each string literal with `String(localized: "...")`.

### 2. `trackCO2/trackCO2/View/SummaryWidget/TipsView.swift`

`tipMessage` computed var — wrap each string literal with `String(localized: "...")`.

### 3. `trackCO2/trackCO2/View/SummaryWidgetDetails/ListTipsView.swift`

`generateTip(for:)` function — wrap each string literal with `String(localized: "...")`.

### 4. `trackCO2/trackCO2/View/SummaryWidgetDetails/ListMostUsedView.swift`

`"Used \(activity.events?.count ?? 0) \(activity.events?.count != 1 ? "times" : "time")"` — split into two localized keys:
- `"Used %lld times"` (plural)
- `"Used %lld time"` (singular)

---

## Complete string table

The **key** is the English string (used in both `en.lproj` and in the Swift source). Translate each value for every language.

```
// MARK: - Tab Bar
"Home" = "Home";
"Trips" = "Trips";
"Activities" = "Activities";

// MARK: - SummaryView
"Summary" = "Summary";
"Add" = "Add";
"Add activity" = "Add activity";
"Add default activities" = "Add default activities";
"App Icon" = "App Icon";
"Manage subscription" = "Manage subscription";
"Terms of Service" = "Terms of Service";
"Privacy Policy" = "Privacy Policy";
"Add yesterday's walking distance?" = "Add yesterday's walking distance?";
"Cancel" = "Cancel";
"More" = "More";

// MARK: - Activity CRUD
"Create Activity" = "Create Activity";
"Edit Activity" = "Edit Activity";
"Activity type" = "Activity type";
"Type" = "Type";
"Name" = "Name";
"Description" = "Description";
"Info" = "Info";
"CO2 unit" = "CO2 unit";
"CO2e that is equivalent to CO2eq" = "CO2e that is equivalent to CO2eq";
"CO2 amount" = "CO2 amount";
"Minus" = "Minus";
"Plus" = "Plus";
"Amount" = "Amount";
"Save" = "Save";
"Delete activity" = "Delete activity";
"Are you sure you want to delete this activity?" = "Are you sure you want to delete this activity?";
"Delete" = "Delete";
"Edit" = "Edit";
"Persist" = "Persist";
"Select Activities" = "Select Activities";

// MARK: - Events
"Reference" = "Reference";
"Actual" = "Actual";
"Add event" = "Add event";

// MARK: - Map & Trips
"Select type" = "Select type";
"Close" = "Close";
"Search for a destination" = "Search for a destination";
"Search destination" = "Search destination";
"Selected" = "Selected";
"Save Trip" = "Save Trip";
"Calculating routes…" = "Calculating routes…";
"CO₂ saved" = "CO₂ saved";
"CO₂ emitted" = "CO₂ emitted";
"Pinned" = "Pinned";
"Frequent" = "Frequent";
"Nearby" = "Nearby";
"No nearby places found" = "No nearby places found";
"Unpin" = "Unpin";
"Pin" = "Pin";
"Place" = "Place";

// MARK: - Summary Widgets
"This week CO2" = "This week CO2";
"Navigate to" = "Navigate to";
"No data for this week." = "No data for this week.";
"Compensation" = "Compensation";
"Consumption" = "Consumption";
"Most used" = "Most used";
"Step Count" = "Step Count";
"Step Distance" = "Step Distance";
"Tips" = "Tips";
"Trends" = "Trends";
"No activity data yet" = "No activity data yet";
"Start logging activities to see your weekly trends" = "Start logging activities to see your weekly trends";
"Start tracking your activities to get personalized tips!" = "Start tracking your activities to get personalized tips!";

// MARK: - Detail Views
"All Events" = "All Events";
"Compensation Events" = "Compensation Events";
"Consumption Events" = "Consumption Events";
"Most Used Activities" = "Most Used Activities";
"Activity Tips" = "Activity Tips";
"Range" = "Range";
"All" = "All";
"Day" = "Day";
"Week" = "Week";
"Month" = "Month";
"Year" = "Year";
"No data for this range." = "No data for this range.";
"Unknown Activity" = "Unknown Activity";
"No Activity Data" = "No Activity Data";
"You need at least 5 days of activity data to see trends" = "You need at least 5 days of activity data to see trends";
"Weekly Trends" = "Weekly Trends";
"Weekly Summary" = "Weekly Summary";
"Saved" = "Saved";
"Emitted" = "Emitted";
"Total Emitted" = "Total Emitted";
"Total Saved" = "Total Saved";
"Sorted by CO₂ impact (highest to lowest)" = "Sorted by CO₂ impact (highest to lowest)";
"No activities found. Start tracking your activities to get personalized tips!" = "No activities found. Start tracking your activities to get personalized tips!";
"Used %lld times" = "Used %lld times";
"Used %lld time" = "Used %lld time";
"this week" = "this week";

// MARK: - Mascot (via String(localized:))
"Thriving" = "Thriving";
"Good" = "Good";
"Neutral" = "Neutral";
"Tired" = "Tired";
"Sick" = "Sick";
"I feel amazing!\nKeep saving the planet! 🌱" = "I feel amazing!\nKeep saving the planet! 🌱";
"I'm doing well!\nNice CO₂ tracking this week!" = "I'm doing well!\nNice CO₂ tracking this week!";
"I'm okay…\nTry to offset a bit more?" = "I'm okay…\nTry to offset a bit more?";
"Feeling tired…\nMore green choices, please!" = "Feeling tired…\nMore green choices, please!";
"I'm not well…\nToo much CO₂ this week!" = "I'm not well…\nToo much CO₂ this week!";
"Hey, I'm peckish!\nGive me a green snack! 🌿" = "Hey, I'm peckish!\nGive me a green snack! 🌿";
"My tummy's rumbling!\nMore compensation, please! 🍃" = "My tummy's rumbling!\nMore compensation, please! 🍃";
"I'M STARVING!\nWay too much CO₂! 😰" = "I'M STARVING!\nWay too much CO₂! 😰";
"% health" = "% health";

// MARK: - TipKit
"Change the Multiplier" = "Change the Multiplier";
"Long-press + or - to select a different step size." = "Long-press + or - to select a different step size.";
"Pick a Destination" = "Pick a Destination";
"Tap anywhere on the map or use the search button to choose where you're headed." = "Tap anywhere on the map or use the search button to choose where you're headed.";
"Compare Transport Modes" = "Compare Transport Modes";
"Swipe through the cards to compare CO₂ impact. The greenest route is always shown first." = "Swipe through the cards to compare CO₂ impact. The greenest route is always shown first.";
"Log Your Trip" = "Log Your Trip";
"Tap the checkmark to save this trip and record its CO₂ emissions to your activity log." = "Tap the checkmark to save this trip and record its CO₂ emissions to your activity log.";

// MARK: - Paywall
"Save with Lifetime plans" = "Save with Lifetime plans";
"Welcome to trackCO2!" = "Welcome to trackCO2!";
"Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!" = "Track your carbon footprint by logging your daily activities. Discover how your choices impact the environment and make a difference!";
"Track your carbon footprint." = "Track your carbon footprint.";
"Add your personal activities and see how much CO2 you're saving every day." = "Add your personal activities and see how much CO2 you're saving every day.";
"See Your Impact." = "See Your Impact.";
"Visualize your progress, set goals, and get tips to reduce your emissions. Start your journey to a greener lifestyle today!" = "Visualize your progress, set goals, and get tips to reduce your emissions. Start your journey to a greener lifestyle today!";
"Terms of use" = "Terms of use";
"and" = "and";

// MARK: - App Icon
"Select Icon" = "Select Icon";
```

---

## Execution order

1. Create all `.lproj` folders and write every `Localizable.strings` file (all 12 languages).
2. Update `Info.plist` with `CFBundleLocalizations`.
3. Update `trackCO2.xcodeproj/project.pbxproj` — add `knownRegions`, `PBXFileReference`, and `PBXVariantGroup` entries.
4. Patch the four Swift files listed above to use `String(localized:)`.
5. Build the project to verify no errors.
