# Version 1.0.9 — Growth release

**Goal:** fix the funnel measured in App Store Connect (Jul 9 – Oct 6, 2026):

| Step | Before | Target |
|---|---|---|
| Search impression → product page | 0.8% (5,506 → 44) | > 3% |
| Product page → download | ~10% | > 25% |
| Download → paid | 0 (hard paywall, no free path) | 2–4% by day 7 |

## What changed

### App (code)
- **Freemium instead of a hard paywall.** The paywall at the end of onboarding can be closed. Logging, the CO₂ summary, budget, streaks, reminders, Health sync, Siri and sharing are free.
- **Claud+ gates:** Trips planner, smart tips list, trends detail, weather forecast, full activity calendar, custom activities, app icons, Home customization (`PremiumGate`).
- **Upsells:** Home banner, "Upgrade to Claud+" in the ⋯ menu, locked screens with a CTA.
- **Paywall plans:** yearly (with 1-week trial) + monthly (`fp_299_1m`). Weekly is no longer offered but still grants access to existing subscribers.
- **Activation:** default activities are seeded on first launch, so the "+" button works immediately.
- **No review prompt right after closing the paywall;** What's New no longer appears on fresh installs.

### Store listing
- New name/subtitle/keywords per locale with the main search term ("carbon footprint" / local equivalent) in the name.
- Description rewritten: accurate free vs. Claud+ split, real plans, no "limited free preview" claim.
- New **Spanish (Mexico)** locale — Mexico already sends impressions and es-MX is also indexed in the U.S. store.
- New screenshot sets in Figma (page **Claud**), ByJo-style: one section per locale and device.
  - **Upload set — v2:** `App Store 1.0.9 v2 · <locale>` (iPhone 6.9") and `App Store 1.0.9 v2 · iPad · <locale>` (13"). Slides 1–3 are the new conversion-focused designs (big Claud + speech bubble, zoomed trip comparison, "Keep Claud happy" moods + streak); slides 4–7 are instances of the v1 masters (tips, log, weather, trends).
  - **v1 (kept for A/B testing):** `App Store 1.0.9 v1 · <locale>` — use as the Product Page Optimization control or treatment.
- Three in-app events → [in-app-events.md](./in-app-events.md).

## Locales

| File | App Store Connect locale |
|---|---|
| [en.md](./en.md) | English (U.S.) |
| [en-GB.md](./en-GB.md) | English (U.K.) |
| [en-CA.md](./en-CA.md) | English (Canada) |
| [de.md](./de.md) | German |
| [es.md](./es.md) | Spanish (Spain) |
| [es-MX.md](./es-MX.md) | Spanish (Mexico) — **add this locale** |
| [fr.md](./fr.md) | French |
| [it.md](./it.md) | Italian |
| [nl.md](./nl.md) | Dutch |
| [nb.md](./nb.md) | Norwegian |
| [pt.md](./pt.md) | Portuguese (Portugal) |
| [pt-BR.md](./pt-BR.md) | Portuguese (Brazil) |
| [sv.md](./sv.md) | Swedish |

Raw simulator captures (en_US formatting): [screenshots/raw/iphone](./screenshots/raw/iphone) and [screenshots/raw/ipad](./screenshots/raw/ipad).

## App Store Connect checklist

- [ ] **Create subscription `fp_299_1m`** (Claud+ Monthly, 1 month, suggested $2.99 / €2.99) in group **Claud+**; display name "Claud+", description "Unlimited access, billed monthly". Without it the paywall shows only the yearly plan (still works).
- [ ] Optionally **remove `fp_499_1w` from sale** (existing weekly subscribers keep renewing; the app no longer shows it).
- [ ] Create version 1.0.9, attach the build, paste Name/Subtitle/Keywords/Description/What's New for every locale.
- [ ] Add the **Spanish (Mexico)** localization.
- [ ] Export & upload screenshots: Figma → select a `v2` section → Export (JPG 1× already set on every frame) → upload to the 6.9" iPhone and 13" iPad slots.
- [ ] Update **Promotional Text** (can be changed anytime, no review).
- [ ] Verify the privacy policy URL (`https://giusscos.com/work/claud/privacy/`) is live; older docs used giusscos.com.
- [ ] App Review notes: mention that core features are free and Claud+ unlocks the gated screens; no account needed.
- [ ] Create the three in-app events.
- [ ] Privacy nutrition label: unchanged (no analytics SDK was added).

## Next growth steps (after release)

1. **Cross-promotion** from your other apps (PomoTask, Poly, yPrompt, Black Swan, Foo, ByJo, Oasis Keeper, Shop Survivors): add a "More apps" row or a one-time card linking to Claud via `SKOverlay`. App referrer traffic is currently ~0.
2. **Measure the paywall.** Add a privacy-friendly analytics SDK (e.g. TelemetryDeck) for: paywall shown / closed / trial started, gate tapped per feature. Update the privacy label when you do.
3. **Localize the listing** for markets already generating impressions without a translation: Japanese, Korean, Turkish, Arabic.
4. **Product Page Optimization**: once you get ~300+ product page views/month, A/B test screenshot 1 (mascot-first vs. chart-first).
5. **Apple Search Ads** only after download → paid is > 0; start with exact-match "carbon footprint" at a small daily budget.
