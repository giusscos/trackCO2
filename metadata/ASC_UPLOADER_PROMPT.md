# Project Prompt: App Store Connect Metadata Uploader

## Goal

Build a CLI tool called **`asc-push`** that reads App Store Connect metadata from structured YAML files and uploads it to App Store Connect via the REST API — supporting all locales, all metadata fields, screenshot references, and validation. No Fastlane dependency.

---

## Target user

An indie iOS developer who maintains metadata for 10–15 locales in a structured folder, wants to push updates in one command from the terminal, and needs to see a diff before anything is sent.

---

## File format: YAML (one file per locale)

Each locale lives in a file like `metadata/<version>/<locale>.yml`.

### Locale file schema (`en.yml` example)

```yaml
locale: en-US                        # App Store Connect locale code

app_info:
  name: Claud CO2                     # max 30 chars
  subtitle: Track Your Carbon Footprint   # max 30 chars
  promotional_text: |                # max 170 chars, can be updated without new version
    Meet Claud — your cloud mascot that reacts to your CO₂ score.

keywords: carbon,footprint,CO2,climate,sustainability,eco,green,transport   # max 100 chars

description: |                       # max 4000 chars
  Claud CO2 helps you understand and reduce your personal carbon footprint.

whats_new: |                         # max 4000 chars
  - Meet your new mascot — Claud reacts to your CO₂ score in real time
  - Weather-aware tips

urls:
  support: https://giusscos.com/trackco2/support
  marketing: https://giusscos.com/trackco2
  privacy: https://giusscos.com/trackco2/privacy
```

### Global config file (`asc-push.yml` at repo root)

```yaml
app_id: "6743588724"                 # numeric App Store app ID
bundle_id: giusscos.trackCO2
version: 1.0.7
metadata_dir: metadata/1.0.7        # path to locale YAML files

auth:
  key_id: XXXXXXXXXX                 # App Store Connect API key ID
  issuer_id: xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx
  key_path: ~/.asc/AuthKey.p8        # or env var ASC_KEY_PATH

locales:
  - en-US
  - en-GB
  - en-CA
  - de-DE
  - es-ES
  - fr-FR
  - it-IT
  - nl-NL
  - nb-NO
  - pt-PT
  - pt-BR
  - sv-SE

primary_category: HEALTH_AND_FITNESS
secondary_category: LIFESTYLE
```

---

## Features

### Core (must-have)

1. **`asc-push metadata`** — upload all locale metadata fields (name, subtitle, description, keywords, promotional text, what's new, URLs) via App Store Connect REST API v1
2. **`asc-push diff`** — fetch current live metadata from ASC and print a colour-coded diff (current → proposed) per locale before any write
3. **`asc-push validate`** — run all field-length checks and required-field checks locally, with clear pass/fail output per locale. Exit code 1 on failure
4. **Dry-run flag** (`--dry-run`) on all write commands — show exactly what would be sent, but make no API calls
5. **Locale filter** (`--locale en-US,de-DE`) — push only selected locales
6. **Interactive confirm** — after diff, prompt "Push these changes? [y/N]" before writing (skip with `--yes`)

### Metadata fields supported

| Field | API endpoint | Notes |
|---|---|---|
| Name | `appInfoLocalizations` | Version-independent |
| Subtitle | `appInfoLocalizations` | Version-independent |
| Promotional text | `appStoreVersionLocalizations` | No new version needed |
| Keywords | `appStoreVersionLocalizations` | Comma-separated, 100-char limit |
| Description | `appStoreVersionLocalizations` | 4000-char limit |
| What's New | `appStoreVersionLocalizations` | Per version |
| Support URL | `appStoreVersionLocalizations` | |
| Marketing URL | `appStoreVersionLocalizations` | |
| Privacy Policy URL | `appInfoLocalizations` | Version-independent |

### Validation rules (match App Store Connect server-side)

- Name ≤ 30 chars
- Subtitle ≤ 30 chars
- Promotional text ≤ 170 chars
- Keywords ≤ 100 chars (comma-separated, no spaces around commas)
- Description ≤ 4000 chars
- What's New ≤ 4000 chars
- All URL fields must be valid `https://` URLs
- No field may contain the app name in a way that violates Apple guidelines (warn only)

### Auth

- App Store Connect API key authentication (JWT, ES256)
  - Key ID + Issuer ID + `.p8` private key file
  - Also accept `ASC_KEY_ID`, `ASC_ISSUER_ID`, `ASC_KEY_PATH` env vars (env vars take precedence over config file)
- Token cached in memory for the process lifetime (10-minute expiry)

### Error handling

- Retry transient HTTP errors (429, 503) with exponential back-off (3 attempts)
- On 422 Unprocessable Entity, parse and display ASC's `errors` array in human-readable form
- If a locale doesn't exist yet in ASC (404 on GET), create it automatically before patching

### Output / UX

- Progress indicator per locale while uploading (spinner or `[3/12] de-DE ✓`)
- `--quiet` flag: suppress all output except errors
- `--json` flag: output structured JSON (for CI pipelines)
- Coloured terminal output (green = success, yellow = warning, red = error); auto-disable when stdout is not a TTY

---

## Competitor feature checklist

Features drawn from Fastlane deliver, Helm, Transporter, Appfigures, and AppFollow:

| Feature | Source | Include |
|---|---|---|
| Metadata upload (all fields) | Fastlane deliver | Yes |
| Diff before push | Fastlane deliver | Yes |
| Dry-run mode | Fastlane deliver | Yes |
| Locale filter | Fastlane deliver | Yes |
| Field-length validation | Fastlane deliver | Yes |
| Auto-create missing locale | Fastlane deliver | Yes |
| API key auth (JWT) | ASC REST API | Yes |
| YAML format | Helm | Yes |
| Per-field change summary | Appfigures | Yes (diff command) |
| JSON output for CI | Codemagic / Bitrise | Yes |
| Retry on rate-limit | ASC REST API best practice | Yes |
| Version-independent fields (name, subtitle) | Fastlane | Yes |
| Keywords character counter | AppTweak / AppFollow | Yes (validate command) |
| Screenshot upload | Fastlane deliver | Future / out of scope v1 |
| Binary upload | Transporter | Out of scope |
| ASO keyword suggestions | AppTweak | Out of scope |

---

## Project structure

```
asc-push/
├── asc_push/
│   ├── __init__.py
│   ├── cli.py            # Click/Typer entry point
│   ├── auth.py           # JWT token generation for ASC API
│   ├── client.py         # HTTP client (httpx), retry logic
│   ├── models.py         # Pydantic models for locale YAML schema
│   ├── config.py         # Load and validate asc-push.yml
│   ├── commands/
│   │   ├── metadata.py   # `asc-push metadata` upload logic
│   │   ├── diff.py       # `asc-push diff`
│   │   └── validate.py   # `asc-push validate`
│   └── utils/
│       ├── diff_printer.py   # Colour diff output
│       └── spinner.py        # Progress display
├── tests/
│   ├── test_auth.py
│   ├── test_validate.py
│   ├── test_client.py        # httpx mock tests
│   └── fixtures/
│       └── en.yml            # sample locale file for tests
├── pyproject.toml
├── README.md
└── asc-push.yml.example      # template config
```

---

## Tech stack

- **Language**: Python 3.12+
- **CLI framework**: [Typer](https://typer.tiangolo.com/) (Click under the hood)
- **HTTP**: [httpx](https://www.python-httpx.org/) (async, built-in retry)
- **YAML parsing**: PyYAML or ruamel.yaml
- **Schema validation**: Pydantic v2
- **JWT signing**: PyJWT + cryptography
- **Diff output**: difflib + rich (for colour)
- **Testing**: pytest + pytest-httpx (mock HTTP)
- **Packaging**: pyproject.toml, installable via `pip install .` or `pipx install .`

---

## App Store Connect API endpoints used

Base URL: `https://api.appstoreconnect.apple.com/v1`

| Operation | Method | Path |
|---|---|---|
| Get app info | GET | `/apps/{id}/appInfos` |
| Get app info localizations | GET | `/appInfos/{id}/appInfoLocalizations` |
| Patch app info localization | PATCH | `/appInfoLocalizations/{id}` |
| Create app info localization | POST | `/appInfoLocalizations` |
| Get version | GET | `/apps/{id}/appStoreVersions?filter[versionString]={version}` |
| Get version localizations | GET | `/appStoreVersions/{id}/appStoreVersionLocalizations` |
| Patch version localization | PATCH | `/appStoreVersionLocalizations/{id}` |
| Create version localization | POST | `/appStoreVersionLocalizations` |

---

## Migration helper (bonus command)

**`asc-push migrate --from metadata/1.0.7 --format md`**

Reads the existing Markdown locale files (the current Claud CO2 format) and converts them to YAML files in the same folder. This is a one-time command to bootstrap the YAML format from the existing `.md` files.

Field mapping from Markdown:
- `| **Name** | value |` → `app_info.name`
- `| **Subtitle** | value |` → `app_info.subtitle`
- `| **Promotional Text** | value |` → `app_info.promotional_text`
- Keywords code block → `keywords`
- Description section body → `description`
- What's New section body → `whats_new`
- URLs table rows → `urls.support`, `urls.marketing`, `urls.privacy`

---

## Acceptance criteria

- `asc-push validate` passes for all 12 locales with zero errors
- `asc-push diff` prints a readable diff with no API write calls
- `asc-push metadata --dry-run` prints the full request payload per locale without sending
- `asc-push metadata` successfully PATCHes all locales against a live ASC sandbox app
- All field-length errors surface as clear messages (not stack traces)
- `asc-push migrate` converts the 12 existing `.md` files to valid `.yml` with no data loss
- 80%+ test coverage on auth, validation, and client modules
