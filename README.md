# 💧 AquaGuard: IoT Smart Water-Quality Monitoring & Community Mapping System

[![Flutter](https://img.shields.io/badge/Flutter-3.47.5-02569B?logo=flutter)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.13.4-0175C2?logo=dart)](https://dart.dev)
[![License: MIT](https://img.shields.io/badge/License-MIT-teal.svg)](LICENSE)
[![Tests Passing](https://img.shields.io/badge/Tests-42%2F42%20Passed-emerald.svg)](test)

---

## 📌 Project Purpose & Regulatory Notice

**AquaGuard** monitors **selected** environmental water-quality indicators:
1. **pH Level** (Unitless, baseline: 6.5 – 8.5)
2. **Total Dissolved Solids / Electrical Conductivity (TDS/EC)** (ppm or µS/cm, baseline: 150 – 500 ppm)
3. **Turbidity** (NTU, baseline: 0.5 – 5.0 NTU)
4. **Water Temperature** (°C or °F, baseline: 20.0 – 32.0 °C)

Telemetry is acquired from an **ESP32 IoT hardware node with GPS** and supplemented by verified citizen field reports.

> [!IMPORTANT]
> **REGULATORY LIMITATIONS STATEMENT**  
> AquaGuard monitors selected indicators only and **DOES NOT certify whether water is safe to drink, potable, or pathogen-free**.  
> The application strictly uses neutral indicator descriptions (e.g., *"Within expected range"*, *"Unusual change detected"*, *"Ambient baseline"*) and **never** classifies water as *"safe"*, *"clean"*, or *"potable"*. Always consult certified public health laboratory assays prior to consuming untreated water.

---

## 🏗️ System Architecture & Feature Matrix

```
lib/
├── config/              # App constants, collection names & demo_ prefixes
├── core/
│   ├── config/          # Parameter threshold definitions & anomaly delta limits
│   ├── constants/       # Ocean & teal water-themed palette, typography tokens
│   ├── services/        # Offline sync queue (client UUID), demo simulator (10s live stream)
│   ├── theme/           # Material 3 light & dark themes
│   ├── utils/           # Anomaly detector (3 std-dev & fixed deltas), reading validator, unit converter
│   └── widgets/         # Disclaimer banner, offline banner, status badges, empty/loading/error states
├── features/
│   ├── devices/         # Device status screen (online <10 min check, hardware specs)
│   └── history/         # fl_chart interactive graphs with tooltips & range filtering
├── models/              # WaterSource, Measurement, Device, AlertItem, CommunityObservation
├── providers/           # Riverpod state notifiers, streams, and preferences
├── repositories/        # Repository pattern with in-memory mock and Firebase Cloud Firestore implementations
├── screens/             # 10 production-ready screens + Custom Bottom Navigation
└── widgets/             # Reusable UI components
```

### The 10 Core Application Screens

1. **Authentication (`LoginScreen`, `SignUpScreen`, `ForgotPasswordScreen`)**:
   - Email/password authentication with format validation.
   - **"Continue as Guest"**: allows immediate exploration of the water map and community readings; blocks submission of manual readings without registration.
2. **Dashboard (`HomeDashboardScreen`)**:
   - Pull-to-refresh (`RefreshIndicator`).
   - Summary cards displaying latest readings from each monitored source.
   - Badge counter for unacknowledged anomaly alerts.
   - Community readings count for the current week.
   - Prominent indicator monitoring disclaimer banner.
3. **Water Quality Map (`MapScreen`)**:
   - Markers colored by water source status:
     - 🟢 **Teal**: Within expected range
     - 🟠 **Amber**: Unusual change detected
     - ⚪ **Slate**: No recent data
   - Tap marker to reveal a modal bottom sheet with source name, type, latest reading metrics, and *"View history"* button.
   - Floating Action Button: *"Add community reading"*.
   - Uses OpenStreetMap via `flutter_map` with an interactive vector canvas fallback for offline/low-bandwidth environments.
4. **Current Measurements (`WaterSourceDetailsScreen`)**:
   - Displays latest pH, TDS/EC, turbidity, and water temperature with unit badges.
   - Small status indicator for each metric with human-readable timestamps.
   - GPS coordinate badge with accuracy metadata.
5. **Historical Graphs (`HistoryScreen` & `FlParameterChart`)**:
   - Interactive line charts powered by `fl_chart`.
   - Range selector tabs: **24h**, **7d**, **30d**, and **All**.
   - Touch tooltips showing exact value and timestamp.
   - Explicit *"No data for this range"* empty state when samples are unavailable.
6. **Anomaly Alerts (`AlertsScreen`)**:
   - Standardized anomaly message: *"Unusual water-quality measurement detected at this location."*
   - Displays affected parameter, current value, and timestamp.
   - Individual alert acknowledgment button and *"Mark all read"* action.
   - Direct navigation to source telemetry history.
7. **Community Reporting (`ReportMeasurementScreen`)**:
   - Submit readings for an existing source or register a new source with sensor-detected GPS coordinates.
   - 4 parameter input fields with strict boundary validation (pH: 0–14, Temp: -5 to 60 °C, Turbidity: ≥ 0, TDS: ≥ 0).
   - At least 1 parameter required; optional field observation notes.
   - Automatic timestamp and permanent disclaimer banner.
8. **Community Feed (`CommunityScreen`)**:
   - Chronological ledger of citizen observations and ESP32 hardware logs.
   - Filter chips by source and source type (River, Lake, Well, Reservoir).
   - Displays *"Pending sync"* badges for observations queued while offline.
9. **Device Status (`DeviceStatusScreen`)**:
   - Shows registered ESP32 nodes, battery levels, signal strength, and firmware version.
   - Status calculation: **Online** if seen within the last 10 minutes; **Offline** otherwise.
10. **Settings (`SettingsScreen` & `AboutAppScreen`)**:
    - Units preferences: **°C vs. °F**, **ppm vs. µS/cm**, **NTU vs. JTU**.
    - Account sign out and guest session management.
    - *"About AquaGuard"* screen with project vision and regulatory statement.
    - **Hidden Demo Mode toggle**: Tap the version number 5 times to activate demo mode.

---

## 🧠 Explainable Anomaly Detection Engine

Client-side anomaly detection is handled in `lib/core/utils/anomaly_detector.dart`:
1. **Statistical Z-Score (3 Standard Deviations)**:
   - Evaluates the current sample against the mean and standard deviation of that source's last 30 readings:
     $$\text{z-score} = \frac{|x - \mu|}{\sigma} > 3.0$$
2. **Fixed Delta Jump Limits** (configured in `lib/core/config/parameter_thresholds.dart`):
   - **pH Jump**: $\Delta > 1.5$
   - **Temperature Jump**: $\Delta > 5.0^\circ\text{C}$
   - **Turbidity Jump**: $\Delta > 15.0\text{ NTU}$
   - **TDS Jump**: $\Delta > 150.0\text{ ppm}$
   *(All thresholds are commented as demonstration values configured for IoT simulation).*

---

## 📴 Offline Resilience & De-duplication

- **Local Persistence**: State is persisted locally via `LocalStorageService` so the app opens immediately with the last-loaded sources, measurements, and alerts without network delay.
- **Pending Sync Queue**: Community readings submitted without connectivity are enqueued with a *"Pending sync"* badge.
- **Client-Generated UUID**: Every observation generates a UUID v4 client-side (`const Uuid().v4()`), ensuring **zero duplicate uploads** on automatic retry when connectivity returns.

---

## 🎭 Demo Mode & Telemetry Simulation

### Activating Demo Mode
1. Open the **Settings** tab (gear icon).
2. Scroll to the bottom and **tap the version number ("v1.0.0 (Build 1)") 5 times**.
3. A confirmation SnackBar will confirm: *"Demo Mode Enabled - Loaded 3 sources, 7d history, and live ESP32 simulation stream."*

### What Demo Mode Provides:
- **3 Monitored Water Sources**:
  1. *Blue River Reach* (River)
  2. *Pine Valley Well* (Groundwater Well)
  3. *Emerald Lake Reservoir* (Impoundment Reservoir)
- **7 Days of Historical Telemetry**: 96 realistic chronological data points reflecting diurnal day/night cycles.
- **1 Designated Anomaly Alert**: Turbidity spike of **18.5 NTU** on *Blue River Reach*.
- **Live ESP32 Telemetry**: Simulates a live hardware node sending fresh readings **every 10 seconds** directly to the stream.
- **Separate Collection Prefix**: All demo documents use the `demo_` prefix (`demo_sources`, `demo_measurements`, `demo_devices`, `demo_alerts`) so production data is never mixed with demo data.

### Running the Seed Script
To generate or inspect the demo dataset JSON export:
```bash
dart run scripts/seed_demo_data.dart
```
This writes `.storage/demo_seed_export.json` ready for direct import into Google Cloud Firestore.

---

## 🔐 Cloud Firestore Data Model & Security Rules

### Collections
- `sources/{sourceId}`: `name`, `type` (`river` | `lake` | `well` | `reservoir` | `stream` | `other`), `latitude`, `longitude`, `createdBy`, `createdAt`, `lastReadingAt`
- `measurements/{measurementId}`: `sourceId`, `deviceId`, `ph`, `tdsEc`, `turbidity`, `temperature`, `latitude`, `longitude`, `timestamp`, `submittedBy`, `source` (`device` | `community`), `syncedAt`
- `devices/{deviceId}`: `name`, `ownerUid`, `lastSeenAt`
- `alerts/{alertId}`: `sourceId`, `measurementId`, `parameter`, `message`, `createdAt`, `acknowledged` (bool)
- `demo_*`: Identical schema matching `demo_sources`, `demo_measurements`, `demo_devices`, `demo_alerts`.

### Deploying Firestore Rules
The project includes `firestore.rules` enforcing authenticated read access and owner-only write permissions:
```bash
firebase deploy --only firestore:rules
```

---

## ⚙️ Setup & Installation Guide

### Prerequisites
- Flutter SDK (≥ 3.24.0, verified with Flutter 3.47.5)
- Dart SDK (≥ 3.5.0, verified with Dart 3.13.4)
- Git

### 1. Clone & Install Dependencies
```bash
git clone https://github.com/ANafeesh/AquaGuard-IoT.git
cd AquaGuard-IoT/mobile_app
flutter pub get
```

### 2. Configure Firebase (Optional for Live Cloud Mode)
To connect your own Firebase project:
```bash
# Install FlutterFire CLI
dart pub global activate flutterfire_cli

# Configure Firebase project credentials
flutterfire configure
```
AquaGuard comes preconfigured with `AppConfig.useMockData = true` so the application runs completely out-of-the-box with offline mock repositories if cloud credentials are not supplied.

### 3. Google Maps API Key Placement
If using Google Maps instead of OpenStreetMap:
- **Android**: Place your key in `android/app/src/main/AndroidManifest.xml`:
  ```xml
  <meta-data
      android:name="com.google.android.geo.API_KEY"
      android:value="YOUR_GOOGLE_MAPS_API_KEY_HERE" />
  ```
- **iOS**: Place your key in `ios/Runner/AppDelegate.swift`:
  ```swift
  GMSServices.provideAPIKey("YOUR_GOOGLE_MAPS_API_KEY_HERE")
  ```
*(Note: If no Google Maps key is provided, AquaGuard defaults to OpenStreetMap with vector fallback).*

---

## 🧪 Running Automated Tests

Run the complete test suite (unit and widget tests):
```bash
flutter test
```

### Test Coverage Highlights:
- **Unit Tests** (`test/unit/`):
  - `anomaly_detector_test.dart`: Validates 3 standard deviation Z-score detection, fixed delta jump thresholds for pH, Temp, Turbidity, TDS, multi-parameter evaluations, and strict non-potable terminology.
  - `reading_validator_test.dart`: Validates parameter bounds (pH: 0–14, Temp: -5–60°C, Turbidity: ≥ 0, TDS: ≥ 0), requirement for at least one parameter, and new source naming.
- **Widget Tests** (`test/widget/`):
  - `login_screen_test.dart`: Tests email/password validation, branding, and guest authentication flow.
  - `community_reporting_form_test.dart`: Tests regulatory disclaimer rendering, input validation banners, guest blocking dialog, and observation submission.

---

## 📦 Building Production APK

To build a standalone release APK for Android devices:
```bash
# Build release APK
flutter build apk --release

# The compiled APK is saved at:
# build/app/outputs/flutter-apk/app-release.apk
```

To build an Android App Bundle (AAB) for Google Play Store:
```bash
flutter build appbundle --release
```

---

## 📄 License
This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
