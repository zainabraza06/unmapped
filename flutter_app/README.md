# UNMAPPED Flutter App

Mobile frontend for the UNMAPPED Labor Intelligence System.

## Requirements

- Flutter SDK ≥ 3.3.0
- Android SDK (API 21+) or iOS 12+
- The Node.js API running on port 4000

## Setup

```bash
cd flutter_app
flutter pub get
```

### Connecting to the API

Edit `lib/core/api/api_service.dart`:

| Environment          | Base URL                  |
|----------------------|---------------------------|
| Android Emulator     | `http://10.0.2.2:4000`    |
| Real device (LAN)    | `http://<HOST_IP>:4000`   |
| Production           | `https://api.unmapped.io` |

## Run

```bash
# Android emulator
flutter run

# Specific device
flutter run -d <device-id>

# Release build (APK)
flutter build apk --release
```

## Project Structure

```
lib/
├── main.dart                  # App entry + bottom nav shell
├── core/
│   ├── theme/app_theme.dart   # Colors, typography, spacing
│   ├── models/                # Typed data models for all 3 modules
│   ├── api/api_service.dart   # HTTP client for the Node API
│   └── state/app_state.dart   # Central ChangeNotifier state
├── widgets/                   # Reusable UI components
│   ├── skill_chip.dart
│   ├── occupation_card.dart
│   ├── risk_task_card.dart
│   ├── opportunity_card.dart
│   ├── economic_signal_card.dart
│   └── shared.dart            # LoadingCard, ErrorCard, SectionHeader…
└── features/
    ├── intake/                # Home screen — user input form
    ├── profile/               # Module 1 — Skills Profile
    ├── risk/                  # Module 2 — AI Risk Analysis
    ├── opportunities/         # Module 3 — Opportunity Matching
    └── insights/              # Policy Insights dashboard
```

## Design Principles

- **LMIC-first**: No heavy animations, minimal dependencies, works on low-end Android
- **Offline-graceful**: API errors show clear error cards with retry buttons
- **Sequential pipeline**: M1 → M2 → M3 runs automatically on first profile generation
- **Country-aware**: Switching country clears all results and prompts re-run
- **Explainable**: Every result card shows sources and reasons
