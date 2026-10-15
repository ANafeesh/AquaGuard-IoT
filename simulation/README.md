# AquaGuard ESP32 Simulation (Wokwi + PlatformIO)

This folder contains the official VS Code + PlatformIO + Wokwi simulation of the AquaGuard IoT sensor node.

It simulates multi-sensor telemetry (pH, TDS/EC, turbidity, DS18B20 water temperature, and NEO-6M GPS), flags water quality anomalies, triggers local buzzer and LED alarms, buffers packets during network disruptions in an offline RAM FIFO queue, and **streams live telemetry directly into the AquaGuard Flutter mobile application via Cloud Firestore REST API** (as well as optional Firebase Realtime Database).

---

## 1. Circuit & Hardware Connections (Wokwi `diagram.json`)

| Component | Sensor Interface | ESP32 GPIO Pin | Description |
|---|---|---|---|
| **pH Sensor** | Potentiometer Stand-In | **GPIO 36 (ADC1_CH0)** | Simulates 0.0 – 14.0 pH analog probe output |
| **TDS / EC Sensor** | Potentiometer Stand-In | **GPIO 39 (ADC1_CH3)** | Simulates 0 – 1000 ppm dissolved solids output |
| **Turbidity Sensor** | Potentiometer Stand-In | **GPIO 34 (ADC1_CH6)** | Simulates 0.0 – 100.0 NTU optical sensor output |
| **Water Temperature** | Maxim DS18B20 | **GPIO 4 (OneWire)** | Digital 1-Wire waterproof probe with 4.7 kΩ pull-up |
| **GPS Module** | u-blox NEO-6M | **GPIO 16 (RX2) / GPIO 17 (TX2)** | HardwareSerial 2 stream (NMEA coordinates & UTC) |
| **Piezo Buzzer** | Audio Alarm | **GPIO 25 (DAC1 / Digital)** | Local audible alert when readings exceed typical range |
| **Status / Alarm LED**| Visual Alarm | **GPIO 26 (via 220 Ω resistor)** | Local visual alert indicator |
| **Common Ground** | Ground Bus | **ESP32 GND** | Shared common reference |
| **Power Supply** | 3.3V Rail | **ESP32 3V3** | Sensor power bus |

> **Note on ADC Pin Choice:** GPIO 34, 36, and 39 belong exclusively to **ADC1**. On the ESP32, ADC2 cannot be used concurrently with WiFi. Because all analog sensors use ADC1, readings remain completely accurate and jitter-free while WiFi/HTTPS transmissions take place.

---

## 2. Integration with AquaGuard Flutter Mobile App

The simulation firmware is fully aligned with the AquaGuard mobile app data models:

1. **Cloud Firestore REST Protocol:**
   - Transmits HTTPS POST requests with valid `Authorization: Bearer <ID_TOKEN>` acquired via Firebase Authentication (`signInWithPassword`).
   - Writes directly to either:
     - `measurements` (for Community Map and Public Water Source monitoring).
     - `home_tanks/{tankId}/readings` (for Private Home Water Tank monitoring).
2. **Schema & Field Standardization:**
   - `tdsEc`: Total dissolved solids in ppm (matches mobile app model).
   - `status`: Standard enum string (`withinTypicalRange` or `unusual`), enabling status badges in the mobile app.
   - `timestamp`: UTC ISO-8601 string (e.g. `2026-10-15T12:00:00Z`).
   - `deviceId`: Node identifier (e.g. `esp32_node_river_01` or `esp32_tank_node_01`).
   - `source`: Strictly marked as `device`.
   - `sourceId` / `waterSourceName`: Mapped to target source or private home tank.

---

## 3. How to Open and Run in VS Code

1. Open this `simulation` folder in VS Code.
2. Ensure the **PlatformIO IDE** and **Wokwi Simulator** extensions are installed.
3. Open `include/secrets.h` and verify your credentials:
   - For Wokwi simulation, keep `AQUAGUARD_WIFI_SSID` set to `"Wokwi-GUEST"` with an empty password.
   - Set `AQUAGUARD_FIREBASE_API_KEY` to `"AIzaSyCfVyFmFrvELir5w9_2-_RZwZ-m8t-XMXE"`.
   - Set `AQUAGUARD_FIREBASE_EMAIL` and `AQUAGUARD_FIREBASE_PASSWORD` to your registered node/user credentials.
4. Click **PlatformIO: Build** (or run `pio run` in terminal).
5. Press the **Play** button in Wokwi (`diagram.json`) to start the simulation.
6. Open the Serial Monitor at **115200 baud** to see live readings, GPS acquisition, and Firestore upload logs.

---

## 4. Interactive Serial Monitor Commands

You can type any of the following commands into the Serial Monitor at runtime:

| Command | Action | Example |
|---|---|---|
| `OFFLINE` | Pauses Firebase uploads and buffers readings in the local 16-packet RAM queue. | `OFFLINE` |
| `ONLINE` | Re-enables uploads and immediately flushes buffered samples in FIFO order. | `ONLINE` |
| `TANK <tankId>` | Dynamically switches upload destination to a **Private Home Tank** subcollection (`home_tanks/{tankId}/readings`). | `TANK demo_tank_01` |
| `SOURCE <sourceId>` | Switches upload destination back to a **Public Community Water Source** (`measurements`). | `SOURCE demo_src_river` |
| `DEVICE <deviceId>` | Updates the simulated hardware node identifier. | `DEVICE esp32_tank_node_01` |
| `ANOMALY` | Forces an immediate anomaly spike on the next telemetry cycle to test local buzzer/LED alerts and mobile app push notifications. | `ANOMALY` |
| `STATUS` | Prints the current network, token, upload mode, target collection, and buffer count. | `STATUS` |

---

## 5. Parameter Baseline Thresholds

The firmware monitors the 4 core environmental indicators using AquaGuard's demonstration baseline:

| Indicator | Baseline Typical Range | Anomaly Trigger Limit (Sudden Delta) |
|---|---|---|
| **pH Level** | 6.5 – 8.5 | $\Delta > 1.5$ pH |
| **TDS / EC** | 150 – 500 ppm | $\Delta > 150.0$ ppm |
| **Turbidity** | 0.5 – 5.0 NTU | $\Delta > 15.0$ NTU |
| **Water Temperature** | 20.0 – 32.0 °C | $\Delta > 5.0$ °C |

*Regulatory Disclaimer: These thresholds are demonstration baselines for IoT sensor simulation. Physical sensors alone do not certify biological drinking water safety.*
