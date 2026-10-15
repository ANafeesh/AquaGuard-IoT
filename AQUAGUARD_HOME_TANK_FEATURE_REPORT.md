# AquaGuard — Home Water Tank Registration and Privacy Feature Verification Report

**Date:** October 15, 2026  
**Project:** AquaGuard — IoT-Based Smart Water Quality Monitoring & Community Mapping System  
**Status:** Complete, Verified, & Passed  

---

## 1. Executive Summary

The **Home Water Tank Registration and Privacy Feature** has been integrated into the existing AquaGuard mobile application architecture. This capability allows residential users and homeowners to install the AquaGuard IoT system on their own private home water tanks (e.g., rooftop overhead tanks, underground sumps, rainwater harvesting tanks), record the confirmed installation location, link an ESP32 hardware node, and monitor water quality parameters privately.

**Key Security & Privacy Guarantees:**
* **Owner-Only Isolation:** Every home tank is bound to the authenticated user's Firebase UID (`ownerUid`). Normal users cannot read, list, modify, or delete another user's tank.
* **Separation from Public Map:** Private home tanks are stored in the dedicated `/home_tanks` Firestore collection and subcollections. They **never appear on the public community map** (`MapScreen`), preventing accidental leakage of domestic coordinates.
* **Backend Security Rules:** Enforced directly in [firestore.rules](file:///e:/Workshops/IOT/mobile_app/firestore.rules) through strict authorization checks (`resource.data.ownerUid == request.auth.uid`), preventing unauthorized client-side tampering or ownership hijacking.
* **Hardware Device Protection:** Users cannot hijack another user's hardware sensor node; device linkage is verified before association.
* **Civic Reporting Disassociation:** If a user chooses to contribute their tank's reading to the public community water ledger, an explicit consent workflow strips private home addresses and coordinates, sharing only generalized civic district metrics.

---

## 2. Implemented Features & Architecture

### 2.1 My Home Tanks Management
* **Home Dashboard Integration:** Prominently placed "My Home Tanks" section on [HomeDashboardScreen](file:///e:/Workshops/IOT/mobile_app/lib/screens/home_dashboard_screen.dart) with private badge, status chips, and quick registration prompts.
* **Profile Integration:** Added "My Home Tanks" menu item in [ProfileScreen](file:///e:/Workshops/IOT/mobile_app/lib/screens/profile_screen.dart).
* **Dedicated Tank List:** [MyHomeTanksScreen](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/my_home_tanks_screen.dart) displaying all registered residential tanks, privacy status ribbons, and floating action button.
* **Card Widget:** [HomeTankCard](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/widgets/home_tank_card.dart) with type iconography, private lock badge, confirmed location, quick metrics (pH, TDS, Turbidity, Temp), device status, and touch feedback.
* **No Admin Approval Needed:** Users immediately register and access their private monitoring without waiting for administrative review.

### 2.2 Three-Way Installation Location Capture & Confirmation
Implemented in [RegisterTankScreen](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/register_tank_screen.dart):
1. **Use Current Location (GPS):** Captures high-accuracy GPS coordinates with accuracy indicators. Does not blindly save without owner confirmation.
2. **Select on Map:** Interactive map dialog allowing owners to select the pin directly on OpenStreetMap tiles.
3. **Manual Entry:** Address / description text entry with optional latitude/longitude inputs for cases where GPS permission is denied or device lacks GPS.
4. **Owner Confirmation:** Mandatory location confirmation card with clear privacy notice before persistence.

### 2.3 ESP32 Device Association & Offline States
* **Device Ownership Check:** Enforces that a hardware `deviceId` cannot be claimed if already registered to another user account.
* **Device Status Indicators:** Clear distinction between `Online` (recent heartbeat/telemetry), `Offline` (no recent telemetry), and `No Node Linked`.
* **Honest Telemetry:** Does not fabricate fake readings as real sensor data; displays explicit "No Data / Offline" states until genuine sensor packets are received.

### 2.4 Private Water-Quality Dashboard
Implemented in [PrivateTankDashboardScreen](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/private_tank_dashboard_screen.dart):
* **Parameters Monitored:** pH, TDS/EC (ppm), Turbidity (NTU), and Temperature (°C) conforming to [ParameterThresholds](file:///e:/Workshops/IOT/mobile_app/lib/core/config/parameter_thresholds.dart).
* **Regulatory Compliance Notice:** Integrated [DisclaimerBanner](file:///e:/Workshops/IOT/mobile_app/lib/core/widgets/disclaimer_banner.dart) stating that sensor baselines monitor indicators only and do not certify potable drinking water safety.
* **Interactive Charts:** Integrated [FlParameterChart](file:///e:/Workshops/IOT/mobile_app/lib/features/history/widgets/fl_parameter_chart.dart) for 24h, 7d, and 30d parameter trend inspection.
* **Management Operations:** Edit tank details, simulate sensor packets (demo/testing mode), and delete tank registration with cascading subcollection cleanup.
* **Anonymized Civic Sharing:** Voluntary option requiring explicit user consent, explicitly stripping exact private coordinates and home addresses before publishing to community observations.

---

## 3. Files Created & Modified

### Created Files
| File | Purpose |
|---|---|
| [lib/models/home_tank.dart](file:///e:/Workshops/IOT/mobile_app/lib/models/home_tank.dart) | Data models for `HomeTank`, `HomeTankType`, and `HomeTankInstallationLocation` |
| [lib/models/tank_reading.dart](file:///e:/Workshops/IOT/mobile_app/lib/models/tank_reading.dart) | Telemetry reading model for private tank subcollection |
| [lib/repositories/home_tank_repository.dart](file:///e:/Workshops/IOT/mobile_app/lib/repositories/home_tank_repository.dart) | Abstract interface contract for home tank operations |
| [lib/repositories/firebase/firebase_home_tank_repository.dart](file:///e:/Workshops/IOT/mobile_app/lib/repositories/firebase/firebase_home_tank_repository.dart) | Firestore repository with owner-scoped queries and device validation |
| [lib/repositories/mock/mock_home_tank_repository.dart](file:///e:/Workshops/IOT/mobile_app/lib/repositories/mock/mock_home_tank_repository.dart) | In-memory repository for unit testing and offline demo mode |
| [lib/features/tanks/providers/home_tank_providers.dart](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/providers/home_tank_providers.dart) | Riverpod stream and state providers for home tanks and readings |
| [lib/features/tanks/widgets/home_tank_card.dart](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/widgets/home_tank_card.dart) | UI card for home tanks with privacy badges, telemetry, and location |
| [lib/features/tanks/screens/register_tank_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/register_tank_screen.dart) | Tank registration and edit screen with GPS, map, and manual location methods |
| [lib/features/tanks/screens/private_tank_dashboard_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/private_tank_dashboard_screen.dart) | Owner-only tank monitoring screen with live metrics, charts, and device status |
| [lib/features/tanks/screens/my_home_tanks_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/features/tanks/screens/my_home_tanks_screen.dart) | Full-screen list of registered home tanks with search and floating action button |
| [test/unit/home_tank_test.dart](file:///e:/Workshops/IOT/mobile_app/test/unit/home_tank_test.dart) | Unit tests verifying models, two-user isolation, device conflict prevention, and offline states |
| [test/widget/home_tank_widget_test.dart](file:///e:/Workshops/IOT/mobile_app/test/widget/home_tank_widget_test.dart) | Widget tests verifying registration form, GPS confirmation, and map separation |

### Modified Files
| File | Modifications |
|---|---|
| [firestore.rules](file:///e:/Workshops/IOT/mobile_app/firestore.rules) | Added rules for `home_tanks/{tankId}` and subcollection `readings`, plus `demo_home_tanks` |
| [lib/core/config/app_config.dart](file:///e:/Workshops/IOT/mobile_app/lib/core/config/app_config.dart) | Added `homeTanksCollection` and `getHomeTanksCollection({bool isDemo = false})` |
| [lib/providers/repository_providers.dart](file:///e:/Workshops/IOT/mobile_app/lib/providers/repository_providers.dart) | Registered `homeTankRepositoryProvider` with mock/Firebase switching |
| [lib/screens/home_dashboard_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/screens/home_dashboard_screen.dart) | Added "My Home Tanks" section with cards and registration banner |
| [lib/screens/profile_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/screens/profile_screen.dart) | Added "My Home Tanks" navigation item |
| [lib/screens/map_screen.dart](file:///e:/Workshops/IOT/mobile_app/lib/screens/map_screen.dart) | Safely guarded map controller and verified isolation from private tanks |
| [test/widget/community_reporting_form_test.dart](file:///e:/Workshops/IOT/mobile_app/test/widget/community_reporting_form_test.dart) | Fixed widget finder ambiguity with hint text |

---

## 4. Firestore Schema & Security Rules

### 4.1 Document Schema: `home_tanks/{tankId}`
```json
{
  "id": "tank_a1b2c3d4",
  "ownerUid": "firebase_auth_uid_here",
  "tankName": "Main Rooftop Overhead Tank",
  "tankType": "rooftop",
  "capacityLiters": 1000,
  "location": {
    "latitude": 6.9271,
    "longitude": 79.8612,
    "address": "No. 24, Havelock Road, Colombo 05",
    "city": "Colombo",
    "locationMethod": "gps",
    "isConfirmed": true
  },
  "deviceId": "esp32_tank_node_01",
  "visibility": "private",
  "createdAt": "2026-10-15T08:00:00.000Z",
  "updatedAt": "2026-10-15T08:30:00.000Z",
  "lastReadingAt": "2026-10-15T08:28:00.000Z",
  "isActive": true,
  "ph": 7.18,
  "tdsEc": 215.0,
  "turbidity": 1.2,
  "temperature": 26.8,
  "status": "withinTypicalRange",
  "notes": "Cleaned recently; fitted with fine sediment filter."
}
```

### 4.2 Subcollection Document Schema: `home_tanks/{tankId}/readings/{readingId}`
```json
{
  "id": "tr_99887766",
  "tankId": "tank_a1b2c3d4",
  "ownerUid": "firebase_auth_uid_here",
  "deviceId": "esp32_tank_node_01",
  "ph": 7.18,
  "tdsEc": 215.0,
  "turbidity": 1.2,
  "temperature": 26.8,
  "timestamp": "2026-10-15T08:28:00.000Z",
  "source": "device",
  "status": "withinTypicalRange",
  "notes": "Routine telemetry packet"
}
```

### 4.3 Security Rules in `firestore.rules`
```javascript
// ---------------------------------------------------------
// Private Home Tanks: home_tanks/{tankId}
// Strictly private: Visible and editable ONLY by the tank owner.
// Exact installation coordinates and tank telemetry are NEVER
// exposed to other users, public queries, or community maps.
// Ownership cannot be altered or hijacked by any other client.
// ---------------------------------------------------------
match /home_tanks/{tankId} {
  allow read: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;
  allow create: if isAuthenticated()
                && request.resource.data.ownerUid == request.auth.uid
                && request.resource.data.visibility == 'private';
  allow update: if isAuthenticated()
                && resource.data.ownerUid == request.auth.uid
                && request.resource.data.ownerUid == resource.data.ownerUid
                && request.resource.data.visibility == 'private';
  allow delete: if isAuthenticated() && resource.data.ownerUid == request.auth.uid;

  // Private sensor readings subcollection for home tanks
  match /readings/{readingId} {
    allow read: if isAuthenticated()
                && get(/databases/$(database)/documents/home_tanks/$(tankId)).data.ownerUid == request.auth.uid;
    allow create: if isAuthenticated()
                  && (request.resource.data.ownerUid == request.auth.uid || request.resource.data.source == 'device')
                  && get(/databases/$(database)/documents/home_tanks/$(tankId)).data.ownerUid == request.auth.uid;
    allow update, delete: if isAuthenticated()
                          && get(/databases/$(database)/documents/home_tanks/$(tankId)).data.ownerUid == request.auth.uid;
  }
}
```

---

## 5. Verification & Test Results

### 5.1 Flutter Static Analysis
```bash
flutter analyze
```
* **Result:** `No issues found! (ran in 5.9s)`
* 0 errors, 0 warnings, 0 lints.

### 5.2 Full Test Suite Execution
```bash
flutter test
```
* **Result:** `00:15 +64: All tests passed!` (64 passing test cases across unit, widget, and repository suites).

### 5.3 Two-User Privacy & Security Tests Executed
Verified in [test/unit/home_tank_test.dart](file:///e:/Workshops/IOT/mobile_app/test/unit/home_tank_test.dart) and [test/widget/home_tank_widget_test.dart](file:///e:/Workshops/IOT/mobile_app/test/widget/home_tank_widget_test.dart):
1. **User A Tank Visibility:** User A registers a private tank (`tank_user_a`). User B queries their tanks list and stream; User A's tank is **completely absent** from User B's results.
2. **Tampering & Hijack Prevention:** User B attempting to update User A's tank or change `ownerUid` throws an unauthorized exception.
3. **Device Node Conflict Prevention:** User B attempting to register a device node already claimed by User A is blocked (`verifyDeviceAvailability` returns `false`).
4. **Community Map Isolation:** Tested `MapScreen` data sources against `MockHomeTankRepository`; private home tanks are never included in public map queries.

---

## 6. ESP32 Firmware Integration & Operational Guidance

### 6.1 ESP32 Telemetry Endpoint for Home Tanks
When configuring the ESP32 node for a private residential tank:
1. The ESP32 authenticates via Firebase Auth REST API using device credentials.
2. The telemetry payload should be directed to the private tank subcollection:
   ```
   POST https://firestore.googleapis.com/v1/projects/{PROJECT_ID}/databases/(default)/documents/home_tanks/{TANK_ID}/readings?key={API_KEY}
   ```
3. **No Private Keys Exposed:** The mobile client and ESP32 firmware use scoped Firebase authentication tokens; no service-account keys or root credentials are baked into client firmware.

### 6.2 Pre-Deployment Checklist for Production
1. **Firebase Security Rules:** Deploy updated [firestore.rules](file:///e:/Workshops/IOT/mobile_app/firestore.rules) using:
   ```bash
   firebase deploy --only firestore:rules
   ```
   *(Ensure confirmation of target Firebase project before deploying).*
2. **Location Permissions:** Location permissions on iOS (`NSLocationWhenInUseUsageDescription`) and Android (`ACCESS_FINE_LOCATION`) remain handled with graceful fallback to manual address input when denied.
