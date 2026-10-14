# AquaGuard — Setup and Deployment Guide

This guide details the step-by-step instructions for running the **AquaGuard** mobile & web applications, configuring Firebase Cloud Firestore and Authentication, and flashing the ESP32 hardware node firmware with connected water quality sensors.

---

## 1. Prerequisites & Required Software

| Software | Minimum Version | Purpose |
|---|---|---|
| **Flutter SDK** | `3.24.x` or higher (`3.47.5` verified) | Mobile & Web application framework |
| **Dart SDK** | `3.5.x` or higher (`3.13.4` verified) | Core programming language |
| **Google Chrome / Edge** | Latest | Immediate web runner & demonstration |
| **Android Studio / SDK** | API 34+ (Build-Tools 34.0.0) | Android native APK compilation |
| **Arduino IDE / PlatformIO** | 2.x or PlatformIO Core | Flashing ESP32 firmware |
| **Firebase CLI** | `13.x` or higher | Deploying Firestore security rules & indexes |

---

## 2. Running the Mobile / Web Application

### Step 1: Install Dependencies
Open a terminal in the project root (`mobile_app`):
```bash
flutter pub get
```

### Step 2: Validate Environment
```bash
flutter analyze
flutter test
```
Ensure all tests pass (51 tests).

### Step 3: Run the Application
* **To run in Google Chrome (Recommended for immediate testing and presentation):**
  ```bash
  flutter run -d chrome
  ```
* **To run on a connected Android phone or emulator:**
  ```bash
  flutter run -d android
  ```
* **To build the production web release:**
  ```bash
  flutter build web --release
  ```

---

## 3. Switching Between Demo Mode and Live Firebase Data

AquaGuard is built with an intelligent dual-mode architecture:
1. **Offline & Demo Mode:**
   - Works immediately out-of-the-box without network connection or Firebase account.
   - Includes 3 pre-seeded water sources (Blue River Reach, Pine Valley Well, Emerald Lake Reservoir).
   - Generates 7 days of realistic chronological telemetry with a distinct turbidity anomaly spike on the river.
   - Simulates periodic live ESP32 telemetry every 10 seconds.
   - To toggle Demo Mode in the app: Go to **Settings Screen** -> Toggle **Demo Mode** or **Simulate Offline Mode**.
2. **Live Firebase Production Mode:**
   - Set `AppConfig.useMockData = false;` in `lib/core/config/app_config.dart`.
   - The app automatically initializes Firebase via `lib/firebase_options.dart`.
   - Live telemetry packets sent by the ESP32 node will stream immediately to the dashboard.

---

## 4. Firebase Project Configuration

AquaGuard is pre-configured with project `aquaguard-iot-b8ce2`.

### Firestore Security Rules Deployment
Deploy the audited security rules located at `firestore.rules`:
```bash
firebase login
firebase use aquaguard-iot-b8ce2
firebase deploy --only firestore:rules
```

### Firestore Database Collections
When live data is enabled, Firestore uses the following collections:
* `sources`: Monitored water sources (id, name, type, coordinates, lastReadingAt, status).
* `measurements`: Raw telemetry records from ESP32 nodes and community inputs (ph, tdsEc, turbidity, temperature, timestamp, source).
* `devices`: Hardware node registrations (id, name, batteryLevel, lastSeenAt, signalStrength).
* `alerts`: Anomaly alerts flagged by detection rules (parameter, value, waterSourceName, severity, acknowledged).
* `observations`: Community feed posts and citizen observations with upvoting.
* `demo_*`: Isolated demo mode collections preventing contamination of production records.

---

## 5. ESP32 Hardware Node Setup & Pinout

### Required Hardware:
1. ESP32 DevKit V1 (30-pin or 38-pin).
2. Analog pH Sensor Probe & Conditioning Board (DFRobot / Gravity standard).
3. Analog TDS / EC Sensor & Probe.
4. Optical Turbidity Sensor (TS-300B / Gravity).
5. Maxim DS18B20 Waterproof Temperature Probe (with 4.7kΩ pull-up resistor).
6. u-blox NEO-6M GPS Module.
7. 5V / 2A Power Source or Solar Battery Shield.

### Hardware Wiring Pinout:
| Sensor / Peripheral | ESP32 Pin | Signal Type | Notes |
|---|---|---|---|
| **pH Sensor Signal (AOUT)** | **GPIO 34** | ADC1_CH6 (Analog) | Input only pin |
| **TDS Sensor Signal (AOUT)** | **GPIO 35** | ADC1_CH7 (Analog) | Input only pin |
| **Turbidity Signal (AOUT)** | **GPIO 32** | ADC1_CH4 (Analog) | Set switch to 'A' (Analog) |
| **DS18B20 Data** | **GPIO 4** | Digital (1-Wire) | 4.7kΩ resistor between Data and 3.3V |
| **NEO-6M GPS TX** | **GPIO 16** | HardwareSerial 2 RX | 9600 baud |
| **NEO-6M GPS RX** | **GPIO 17** | HardwareSerial 2 TX | 9600 baud |
| **Status LED** | **GPIO 2** | Digital Output | Built-in LED blinks during telemetry |
| **Power (VCC)** | **5V / 3.3V** | Power | Connect analog boards to clean 5V/3.3V |
| **Ground (GND)** | **GND** | Common Ground | Common ground across all probes |

---

## 6. Sensor Calibration Procedure

### 1. pH Sensor Two-Point Calibration
1. Dip the pH probe into standard pH 7.00 buffer solution at 25°C.
2. Note the measured analog voltage on the Serial Monitor (`readAnalogVoltage(PIN_PH_ANALOG)`). Set `PH_CALIB_V_NEUTRAL` in `firmware/sketch.ino`.
3. Rinse probe with distilled water, then place in pH 4.01 buffer solution.
4. Note the voltage and set `PH_CALIB_V_ACID` in `firmware/sketch.ino`.

### 2. TDS / EC Temperature Compensation
The firmware applies dynamic temperature compensation using water temperature from the DS18B20 probe:
$$\text{Compensation Voltage} = \frac{V_{\text{actual}}}{1.0 + 0.02 \times (T - 25.0)}$$

### 3. Turbidity Calibration
1. Place the turbidity probe in clean distilled water.
2. Verify the voltage reading is approximately 4.1V – 4.2V.
3. The firmware translates voltage to NTU using the polynomial curve:
$$\text{NTU} = -1120.4 \times V^2 + 5742.3 \times V - 4352.9$$

---

## 7. Flashing the ESP32 Firmware

1. Install Arduino IDE.
2. Under **Boards Manager**, install `esp32 by Espressif Systems`.
3. Under **Library Manager**, install:
   - `OneWire` (by Jim Studt / Paul Stoffregen)
   - `DallasTemperature` (by Miles Burton)
   - `TinyGPSPlus` (by Mikal Hart)
4. Open `firmware/sketch.ino`.
5. Enter your local WiFi network details:
   ```cpp
   const char* WIFI_SSID     = "YOUR_WIFI_SSID";
   const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";
   ```
6. Select Board: **ESP32 Dev Module**.
7. Connect ESP32 via USB and click **Upload**.
8. Open Serial Monitor at **115200 baud** to view live sensor acquisition and Firestore dispatch logs.
