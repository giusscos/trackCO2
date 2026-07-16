# Project Prompt: ASO ASAP

> Paste this file into a fresh Xcode project as the working instructions for the AI.
> It supersedes `ASC_UPLOADER_PROMPT.md` (an earlier CLI-only concept, kept for reference).

## What you are building

**ASO ASAP** — a native macOS app (SwiftUI), distributed on the Mac App Store, for indie iOS/macOS developers who ship apps in many locales.

It solves two problems:

1. **Metadata shipping.** Today the developer writes App Store metadata as Markdown files per locale, then copies and pastes every field into App Store Connect by hand, for 12+ locales, every release. ASO ASAP replaces that with: import or write the metadata once → review a diff → push everything (text fields *and* screenshots) to App Store Connect in a few clicks.
2. **ASO (App Store Optimization).** Keyword tracking, metadata quality scoring, guideline checks, and competitor comparison — so the developer can improve store ranking without a €50/month SaaS subscription.

### Target user

An indie developer with 1–10 apps, 5–15 locales each, who already has an App Store Connect API key and lives in Xcode/terminal. They value: seeing exactly what will change before it's sent, never losing data, and not re-entering anything twice.

---

## Non-negotiable product principles

- **Diff before write, always.** No API mutation happens without the user having seen a current → proposed comparison and clicked a confirm button. There is no "sync silently" mode.
- **Local-first.** All metadata lives on the user's Mac in plain, human-readable files (see Data model). App Store Connect is a *push/pull target*, not the source of truth. The app must be fully usable offline except for push/pull/ASO refresh.
- **Bring your own key.** Users authenticate with their own App Store Connect API key (Key ID, Issuer ID, `.p8` file). The private key goes into the **Keychain**, never into a file or UserDefaults. No ASO-ASAP server ever sees their key or metadata.
- **Honest ASO.** Apple provides no official keyword-ranking API. Be explicit in the UI about where every number comes from (see ASO data sources). Never fabricate a metric.

---

## Tech stack

- **Platform:** macOS 15+, SwiftUI, Swift 6 (strict concurrency)
- **Persistence:** SwiftData for app-level state (projects, keyword lists, rank history, cached ASC state); metadata content itself stored as files in the user's chosen folder (security-scoped bookmark)
- **Networking:** `URLSession` + `async/await`; no third-party HTTP dependency
- **JWT for ASC API:** ES256 via `CryptoKit` (`P256.Signing.PrivateKey` from the `.p8` PEM) — no external JWT library needed
- **Sandboxing:** App Sandbox on (Mac App Store requirement) with `com.apple.security.network.client`, user-selected read/write file access, security-scoped bookmarks for the metadata folder
- **Testing:** Swift Testing (`@Test`) for validation, JWT, import parsers, and API client (protocol-based `URLSession` injection with recorded fixtures)
- **No web views, no Electron, no Python.** Native throughout.

---

## Data model

### On disk (user-visible, git-friendly)

One folder per app project, one file per locale per version:

```
MyApp/
├── asoasap.yml                 # project config (no secrets)
├── 1.0.7/
│   ├── en-US.yml
│   ├── de-DE.yml
│   ├── it-IT.yml
│   └── screenshots/
│       ├── en-US/
│       │   ├── iphone-6.9/    # one folder per display type
│       │   │   ├── 01.png
│       │   │   └── 02.png
│       │   └── ipad-13/
│       └── de-DE/ …
```

Locale file schema:

```yaml
locale: en-US
name: Claud CO2                          # ≤ 30 chars
subtitle: Track Your Carbon Footprint    # ≤ 30 chars
promotional_text: |                      # ≤ 170 chars
  …
keywords: carbon,footprint,CO2,climate   # ≤ 100 chars total
description: |                           # ≤ 4000 chars
  …
whats_new: |                             # ≤ 4000 chars
  …
urls:
  support: https://…
  marketing: https://…
  privacy: https://…
```

`asoasap.yml` holds: app ID, bundle ID, version string, locale list, primary/secondary category, and the Key ID + Issuer ID (public identifiers only — the `.p8` key is in Keychain, referenced by Key ID).

### In SwiftData

Projects, per-keyword rank history (keyword, storefront, date, position), competitor list, cached last-known ASC state (for offline diffing), push history log.

---

## Feature spec

### Phase 1 — Metadata editor & import (usable before any API work)

1. **Project browser** — sidebar listing app projects; create new or open existing folder.
2. **Locale editor** — master–detail: locale list on the left, form on the right with every field, **live character counters** (turn amber at 90%, red over limit), and a keywords field that shows the comma-split terms as tokens with combined character count.
3. **Import** — from:
   - the existing Markdown format (tables with `| **Name** | value |` rows, `## Description` / `## What's New` section bodies, keywords code block, URLs table) — this bootstraps the developer's current `metadata/<version>/<locale>.md` files with zero data loss;
   - Fastlane `deliver` folder layout (`metadata/<locale>/name.txt`, `description.txt`, …);
   - a previous version folder ("start 1.0.8 from 1.0.7").
4. **Export** — back to Markdown or Fastlane layout (keeps the user's data portable; reinforces local-first).
5. **Validation panel** — per-locale pass/fail list, always visible:
   - name ≤ 30, subtitle ≤ 30, promotional text ≤ 170, keywords ≤ 100, description ≤ 4000, what's new ≤ 4000
   - URLs must be valid `https://`
   - warnings (never blockers): duplicated words between title/subtitle/keywords (wasted characters), keyword field containing spaces after commas, plural duplicates (`car,cars`), competitor brand names in keywords (guideline 2.3.7 risk), emoji in name/subtitle
6. **Screenshot manager** — drag-and-drop images into display-type slots per locale; validate pixel dimensions against Apple's accepted sizes per display type; reorder by drag; "apply en-US screenshots to all locales" action.

### Phase 2 — App Store Connect push/pull

7. **Connect account** — onboarding sheet: paste Key ID + Issuer ID, open `.p8` file; validate immediately with a `GET /v1/apps` call; store key in Keychain.
8. **Pull** — fetch current live metadata + screenshot sets for the app/version into the local cache (and optionally seed local files from it — the "I have an existing app, start from what's live" path).
9. **Diff view** — the heart of the app. Side-by-side or inline current → proposed per locale per field, plus screenshot set changes (added/removed/reordered, shown as thumbnails). Unchanged fields collapsed. Checkboxes to include/exclude individual fields or locales from the push.
10. **Push** — one confirm click, then a progress list (`de-DE ✓ name ✓ subtitle ✓ description …`) with per-item retry on failure. Creates missing `appInfoLocalizations` / `appStoreVersionLocalizations` automatically (POST on 404). Never touches fields the user excluded.
11. **Screenshot upload** — full asset flow: create/fetch `appScreenshotSets` per display type per locale → `POST /v1/appScreenshots` to reserve (fileName + fileSize) → upload binary chunks to the returned `uploadOperations` URLs with the given HTTP method/headers/offsets → `PATCH` with `uploaded: true` + MD5 `sourceFileChecksum` → verify processing state. Replace/reorder via set's `appScreenshots` relationship ordering. Show per-file progress; screenshots are the slowest, most error-prone part — make failures resumable, not restart-everything.
12. **Push history** — log of every push (when, what changed, result) stored in SwiftData.

### Phase 3 — ASO module

13. **Keyword tracker** — user maintains a keyword list per app per storefront. For each keyword, the app queries the iTunes Search API for that storefront and records the app's position in the results. History charted over time (Swift Charts). Manual + scheduled refresh (while app is open; no background daemon in v1).
14. **Keyword suggestions** — from: Apple's search **autocomplete/hints** endpoint (unofficial, label it as such), words extracted from top-10 competitors' titles/subtitles, and unused-space analysis of the user's own keyword field.
15. **Metadata score** — a transparent 0–100 per locale with an itemized breakdown (character utilization of name/subtitle/keywords, duplicate waste, tracked-keyword coverage in title/subtitle, screenshot completeness, localization coverage). Every point gained/lost links to a concrete fix. No black-box score.
16. **Competitor comparison** — user picks competitor apps (search by name via iTunes Search API). Table comparing: title/subtitle strategy, rating count & average, update frequency, price/IAP model, category rank. Side-by-side metadata view.
17. **Own-app performance** — impressions, product page views, conversion rate, downloads via the **official ASC Analytics Reports API** (`analyticsReportRequests` → instances → segments; async report generation, so poll and cache). This is the one fully-official ASO data source — lean on it.
18. **Guideline advisor** — static ruleset (no LLM in v1) flagging: keyword stuffing in name/subtitle, price/rank claims ("best", "#1") that risk rejection, mention of other platforms, hidden keyword-field mistakes. Each finding cites the App Review Guideline number.

### ASO data sources — be explicit in code and UI

| Data | Source | Status |
|---|---|---|
| Keyword rank | iTunes Search API (`itunes.apple.com/search`, per `country`) | Public but unofficial for ranking; throttle ≤ ~20 req/min, cache aggressively, degrade gracefully on 403 |
| Search suggestions | App Store autocomplete endpoint | Unofficial; feature-flag it so it can be disabled without an app update |
| Competitor metadata, ratings | iTunes Search/Lookup API | Public |
| Competitor reviews | iTunes customer-reviews RSS | Public, most-recent only |
| Own impressions/conversion | ASC Analytics Reports API | Official |
| Own metadata | ASC API | Official |

Never scrape App Store web pages. If an unofficial endpoint dies, the feature shows "temporarily unavailable", not wrong data.

---

## App Store Connect API reference (for Phase 2)

Base: `https://api.appstoreconnect.apple.com/v1` — JWT ES256, `iss` = Issuer ID, `kid` = Key ID, `aud` = `appstoreconnect-v1`, expiry ≤ 20 min (use 10, regenerate on demand).

| Operation | Method & path |
|---|---|
| List apps (auth check) | `GET /apps` |
| App infos | `GET /apps/{id}/appInfos` |
| App info localizations (name, subtitle, privacy URL) | `GET /appInfos/{id}/appInfoLocalizations` · `PATCH/POST appInfoLocalizations` |
| Find version | `GET /apps/{id}/appStoreVersions?filter[versionString]=` |
| Version localizations (description, keywords, promo, what's new, support/marketing URL) | `GET /appStoreVersions/{id}/appStoreVersionLocalizations` · `PATCH/POST appStoreVersionLocalizations` |
| Screenshot sets | `GET appStoreVersionLocalizations/{id}/appScreenshotSets` · `POST /appScreenshotSets` |
| Screenshots | `POST /appScreenshots` (reserve) → upload to `uploadOperations` → `PATCH /appScreenshots/{id}` (commit) |
| Analytics | `POST /analyticsReportRequests` → `GET` requests/reports/instances/segments |

Error handling: exponential backoff on 429/5xx (3 attempts); surface ASC 409/422 `errors[].detail` verbatim in the UI next to the offending field; one failed locale never aborts the others.

---

## Monetization (build the gate, tune the prices later)

Freemium via StoreKit 2, mirroring the developer's existing setup (offline + online `.storekit` configs):

- **Free:** 1 app project, unlimited locales, full editor + validation + import/export, push text metadata.
- **Pro (subscription, monthly/yearly + lifetime option):** unlimited apps, screenshot push, ASO module (keyword tracking, competitors, analytics), push history.

Paywall appears only when a gated action is attempted — never on launch.

---

## Build order & acceptance criteria

Work in vertical slices; each slice ends with something runnable and its tests green.

1. **Slice 1:** project/locale file model + YAML codec + validation engine + Markdown importer. ✅ Importing the 12 existing Claud CO2 `.md` locale files produces 12 valid `.yml` files with zero data loss; all limits enforced; unit tests cover every validation rule and importer edge case.
2. **Slice 2:** SwiftUI shell — project browser, locale editor with live counters, validation panel, screenshot manager (local only). ✅ Full metadata set for a 12-locale app can be authored/edited without touching a text editor.
3. **Slice 3:** ASC auth + pull + diff. ✅ JWT accepted by live API; diff view correctly shows changes against a real app and marks a freshly-pulled project as "no changes".
4. **Slice 4:** push text metadata. ✅ Dry-run shows exact payloads; a real push updates only selected fields/locales; missing localizations auto-created; failures reported per field with retry.
5. **Slice 5:** screenshot upload. ✅ A full 12-locale × 2-display-type screenshot set uploads with resumable per-file progress; checksums verified.
6. **Slice 6:** ASO — keyword tracker + suggestions + metadata score. ✅ Rank checks match manual App Store searches for the same storefront; score breakdown itemizes every point.
7. **Slice 7:** competitors + Analytics Reports + guideline advisor + paywall.

Definition of done for the whole v1: the developer ships a real Claud CO2 release (all 12 locales, text + screenshots) entirely from ASO ASAP, with no copy-paste into App Store Connect.
