# MC Santé

A personal iOS health correlation app for Marie-Claude. Aggregates Apple Watch data (HealthKit) and local weather, allows quick daily logging of habits, and surfaces statistically significant correlations between all tracked metrics.

**Private use only — no backend, no accounts, no App Store.**

---

## What it does

- Reads sleep phases (REM/Core/Deep), resting heart rate, HRV, exercise minutes, menstrual cycle, blood pressure, and mood (`HKStateOfMind`) from Apple Health
- Fetches daily weather (temperature, atmospheric pressure, humidity) via WeatherKit with an Open-Meteo fallback
- Lets you log custom categories (counter / yes-no / 1–5 scale) in under 30 seconds per day
- Computes Pearson correlations between every pair of metrics with lag detection (same-day and next-day)
- Displays timeline and scatter charts for each correlation
- Home screen widget (small + medium) with daily summary and top insight

---

## Requirements

| Tool | Version |
|------|---------|
| Xcode | 16.0+ |
| iOS deployment target | 18.0 |
| Apple Developer Program | Required (for HealthKit + WeatherKit entitlements) |
| Device | iPhone with Apple Watch recommended |

---

## Setup instructions

### 1. Clone the repo

```bash
git clone https://github.com/emileaublet/health-app.git
cd health-app
open MC-Sante.xcodeproj
```

### 2. Set your Team ID

In Xcode, select the **MC-Sante** project in the navigator, then for **each target** (MC-Sante and MC-SanteWidget):

1. Go to **Signing & Capabilities**
2. Set **Team** to your Apple Developer account
3. Xcode will auto-manage provisioning profiles

Alternatively, find the two occurrences of `DEVELOPMENT_TEAM = "";` in `MC-Sante.xcodeproj/project.pbxproj` and replace with your 10-character Team ID (e.g. `DEVELOPMENT_TEAM = "AB12CD34EF";`).

### 3. Set your Bundle Identifier

The default bundle IDs are:
- App: `com.mcsante.app`
- Widget: `com.mcsante.app.widget`

Change these in Xcode (**Signing & Capabilities → Bundle Identifier**) or directly in `project.pbxproj` if the default IDs are already taken in your Developer account.

### 4. Enable capabilities in the Apple Developer Portal

Log in to [developer.apple.com](https://developer.apple.com) → **Certificates, Identifiers & Profiles** → **Identifiers**:

**For `com.mcsante.app`:**
- [x] HealthKit
- [x] WeatherKit
- [x] Background Modes → App processing

**For `com.mcsante.app.widget`:**
- [x] App Groups → `group.com.mcsante.app`

> WeatherKit is included in the Apple Developer Program membership ($99/year) at no extra cost. Quota: 500,000 calls/month — vastly more than needed for one user.

### 5. Add the app icon

Replace the placeholder in `MC-Sante/Assets.xcassets/AppIcon.appiconset/` with a 1024×1024 PNG. Xcode will generate all required sizes automatically.

### 6. Build and run

Select your iPhone as the run destination and press **⌘R**. On first launch the app will:
1. Show a 3-screen onboarding flow
2. Request HealthKit read/write permissions
3. Request location permission (for weather)
4. Schedule a daily 9 PM reminder
5. Seed 5 built-in tracking categories (coffee, refined sugar, stress, energy, sleep quality)

### 7. Deploy to Marie-Claude's iPhone

**Option A — TestFlight (recommended):**
1. Archive the app: **Product → Archive**
2. Upload to App Store Connect
3. Distribute via TestFlight internal testing
4. Marie-Claude installs from the TestFlight app

**Option B — Ad Hoc:**
1. Register Marie-Claude's device UDID in the Developer Portal
2. Archive and export with **Ad Hoc** distribution
3. Install via Xcode, Apple Configurator 2, or a direct IPA link

---

## Project structure

```
MC-Sante/
├── MC_SanteApp.swift          # @main, ModelContainer, background task
├── ContentView.swift          # TabView (Home / Log / Trends / Settings)
├── Models/                    # SwiftData @Model classes
├── Services/                  # HealthKit, Weather, Snapshot, Correlation, Seed, Notifications
├── ViewModels/                # Observable view models
├── Views/
│   ├── Home/                  # Dashboard
│   ├── Log/                   # Daily entry (counter / bool / scale inputs)
│   ├── Trends/                # Correlation charts and list
│   ├── Settings/              # Category management, data sources, export
│   ├── Onboarding/            # First-launch flow
│   └── Shared/                # EmojiPicker, CalendarStrip
├── Extensions/                # Date, Double, Color helpers
├── Assets.xcassets/
├── Info.plist                 # HealthKit + location permission strings
└── MC_Sante.entitlements      # HealthKit + WeatherKit

MC-SanteWidget/                # WidgetKit extension (small + medium)
```

---

## Weather attribution

WeatherKit requires displaying Apple's **Weather** logo and a legal attribution link wherever weather data is shown. See [Apple's WeatherKit guidelines](https://developer.apple.com/weatherkit/get-started/#attribution-requirements) for the required assets and link text.

---

## Privacy

All data stays on-device. No analytics, no crash reporting, no external services except:
- **WeatherKit** (Apple) or **Open-Meteo** (open-source, no account required) for weather data
- Both are read-only and do not receive any health data

---

## Correlation disclaimer

Correlations shown in the app are statistical (Pearson r) and **do not imply causation**. They require a minimum of 7 days of overlapping data and a minimum |r| of 0.3 to be displayed. Always consult a healthcare professional before making medical decisions.
