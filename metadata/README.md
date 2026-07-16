# App Store Connect Metadata

This folder contains localized App Store Connect copy and screenshot guidance for **Claud CO2**.

## Structure

```
metadata/
├── README.md                 ← this file
└── 1.0.7/                    ← current app version (MARKETING_VERSION)
    ├── README.md             ← version index and checklist
    ├── screenshots.md        ← device sizes, file naming, design rules
    ├── en.md                 ← English (U.S.)
    ├── en-GB.md              ← English (U.K.)
    ├── en-CA.md              ← English (Canada)
    ├── de.md                 ← German
    ├── es.md                 ← Spanish
    ├── fr.md                 ← French
    ├── it.md                 ← Italian
    ├── nl.md                 ← Dutch
    ├── nb.md                 ← Norwegian Bokmål
    ├── pt.md                 ← Portuguese (Portugal)
    ├── pt-BR.md              ← Portuguese (Brazil)
    └── sv.md                 ← Swedish
```

## How to use

1. Open the version folder that matches `MARKETING_VERSION` in Xcode (`1.0.7` today).
2. Copy fields from the locale file into App Store Connect → App → [locale] → App Information / Version Information.
3. Follow `screenshots.md` when capturing and exporting marketing screenshots.
4. Update the version folder when shipping a new release (duplicate the folder and refresh What's New + screenshots).

## App details

| Property | Value |
|---|---|
| App name | Claud CO2 |
| Bundle ID | `giusscos.trackCO2` |
| Current version | 1.0.7 |
| Build | 1 |
| Minimum iOS | 18.5 |
| Primary category | Health & Fitness |
| Secondary category | Lifestyle |
| Monetization | Auto-renewable subscriptions + lifetime purchase |
