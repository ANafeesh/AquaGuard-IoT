/*
 * ==============================================================================
 * AquaGuard - IoT-Based Smart Water Quality Monitoring System
 * ESP32 Microcontroller Firmware
 * ==============================================================================
 * Architecture:
 * - Microcontroller: ESP32 DevKit V1 (38-pin / 30-pin)
 * - Sensors:
 *   1. Analog pH Sensor Probe (DFRobot / Gravity or standard BNC analog interface)
 *   2. Analog TDS / EC Sensor (Total Dissolved Solids)
 *   3. Optical Turbidity Sensor (Gravity Turbidity Sensor, TS-300B)
 *   4. Digital Temperature Sensor (Maxim DS18B20 1-Wire, waterproof probe)
 *   5. GPS Module (u-blox NEO-6M / NEO-8M via HardwareSerial 2)
 *
 * Data Pipeline:
 * - Collects multi-sensor analog & digital signals at configured sampling intervals.
 * - Compensates TDS and pH for water temperature variations.
 * - Validates physical ranges and detects sensor disconnects/faults.
 * - Extracts latitude, longitude, and UTC timestamp from GPS NMEA stream.
 * - Employs an offline circular queue in RAM/Flash when WiFi is unavailable.
 * - Transmits JSON payloads matching the AquaGuard mobile app Firestore schema
 *   via HTTPS POST to Firebase Firestore REST API.
 * ==============================================================================
 */

#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <time.h>

// Set to 1 if you have a NEO-6M GPS module wired to GPIO 16/17 and TinyGPSPlus library installed
#define ENABLE_GPS 0

#if ENABLE_GPS
#include <TinyGPSPlus.h>
#endif

// ==============================================================================
// CONFIGURATION & CREDENTIALS
// ==============================================================================
// Network Credentials
const char* WIFI_SSID     = "YOUR_WIFI_SSID";
const char* WIFI_PASSWORD = "YOUR_WIFI_PASSWORD";

// Firebase Firestore Configuration
// Matches AquaGuard project settings: DefaultFirebaseOptions
const char* FIREBASE_PROJECT_ID   = "aquaguard-iot-b8ce2";
const char* FIREBASE_API_KEY      = "AIzaSyCfVyFmFrvELir5w9_2-_RZwZ-m8t-XMXE";
const char* FIREBASE_AUTH_EMAIL   = "node-river@aquaguard.io";
const char* FIREBASE_AUTH_PASS    = "NodeSecurePass123!";
const char* DEVICE_ID             = "esp32_node_river_01";
const char* WATER_SOURCE_ID       = "src_river_02"; // Target monitored water source
const char* WATER_SOURCE_NAME     = "Riverside Reach Station";

// Firebase Auth Token Management
String firebaseIdToken = "";
String firebaseUid = "";
unsigned long tokenExpiryTime = 0;

// Sampling & Telemetry Timing
const unsigned long SAMPLING_INTERVAL_MS = 10000; // 10 seconds telemetry cycle
const unsigned long GPS_TIMEOUT_MS       = 5000;

// ==============================================================================
// HARDWARE PIN DEFINITIONS
// ==============================================================================
#define PIN_PH_ANALOG       34  // ADC1_CH6 (Analog pH input)
#define PIN_TDS_ANALOG      35  // ADC1_CH7 (Analog TDS/EC input)
#define PIN_TURBIDITY_ANALOG 32 // ADC1_CH4 (Analog Turbidity input)
#define PIN_ONEWIRE_TEMP     4  // Digital IO 4 (DS18B20 1-Wire bus, 4.7k pullup required)
#define PIN_GPS_RX          16  // HardwareSerial 2 RX (Connect to GPS TX)
#define PIN_GPS_TX          17  // HardwareSerial 2 TX (Connect to GPS RX)
#define PIN_STATUS_LED       2  // Built-in blue LED for connection/status blink

// ==============================================================================
// CALIBRATION PARAMETERS
// ==============================================================================
// pH Sensor Two-Point Calibration:
// Calibration procedure: Measure in buffer pH 7.00 and pH 4.01 solutions.
// Record ADC voltage values and update PH_CALIB_V_NEUTRAL and PH_CALIB_V_ACID.
const float PH_CALIB_V_NEUTRAL = 1.65; // Voltage at neutral pH 7.00
const float PH_CALIB_V_ACID    = 2.02; // Voltage at acid pH 4.01
const float VREF               = 3.30; // ESP32 ADC Reference Voltage
const int   ADC_RESOLUTION     = 4095; // 12-bit ADC

// TDS Temperature Coefficient (typically 2% per °C from 25°C baseline)
const float TDS_TEMP_COEFFICIENT = 0.02;

// Turbidity Sensor Baseline (Clean distilled water typically outputs ~4.1V - 4.2V)
const float TURBIDITY_CLEAR_V = 4.20;

// ==============================================================================
// GLOBAL SENSOR OBJECTS & STATE
// ==============================================================================
OneWire oneWire(PIN_ONEWIRE_TEMP);
DallasTemperature tempSensors(&oneWire);
#if ENABLE_GPS
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;
#endif

// Offline Packet Buffer Structure
struct TelemetryPacket {
  float ph;
  float tdsEc;
  float turbidity;
  float temperature;
  double latitude;
  double longitude;
  unsigned long timestampEpoch;
  bool isAnomaly;
};

const int OFFLINE_QUEUE_CAPACITY = 20;
TelemetryPacket offlineQueue[OFFLINE_QUEUE_CAPACITY];
int queueHead = 0;
int queueTail = 0;
int queueCount = 0;

unsigned long lastTelemetryTime = 0;

// ==============================================================================
// SETUP & INITIALIZATION
// ==============================================================================
void setup() {
  Serial.begin(115200);
  delay(1000);
  Serial.println("\n========================================================");
  Serial.println("  AquaGuard IoT Node - ESP32 Multi-Sensor Telemetry     ");
  Serial.println("========================================================");

  pinMode(PIN_STATUS_LED, OUTPUT);
  digitalWrite(PIN_STATUS_LED, LOW);

  // Initialize DS18B20 Digital Temperature Sensor
  Serial.print("[INIT] Initializing DS18B20 Temperature Sensor... ");
  tempSensors.begin();
  int deviceCount = tempSensors.getDeviceCount();
  Serial.printf("Found %d sensor(s).\n", deviceCount);

#if ENABLE_GPS
  // Initialize GPS HardwareSerial 2
  Serial.println("[INIT] Initializing NEO-6M GPS (9600 baud, RX:16, TX:17)...");
  gpsSerial.begin(9600, SERIAL_8N1, PIN_GPS_RX, PIN_GPS_TX);
#endif

  // Connect to WiFi
  connectWiFi();

  // Synchronize system time with NTP
  configTime(0, 0, "pool.ntp.org", "time.google.com");
  Serial.println("[INIT] Synchronizing system clock with NTP...");
  struct tm timeinfo;
  if (getLocalTime(&timeinfo, 10000)) {
    Serial.println("[INIT] System clock synchronized successfully.");
  } else {
    Serial.println("[WARN] NTP sync failed. Fallback timestamps will be used.");
  }

  Serial.println("[READY] AquaGuard IoT monitoring loop active.");
}

// ==============================================================================
// MAIN LOOP
// ==============================================================================
void loop() {
#if ENABLE_GPS
  // Feed GPS parser with incoming serial stream
  while (gpsSerial.available() > 0) {
    gps.encode(gpsSerial.read());
  }
#endif

  // Periodic telemetry cycle
  unsigned long now = millis();
  if (now - lastTelemetryTime >= SAMPLING_INTERVAL_MS) {
    lastTelemetryTime = now;
    processAndDispatchTelemetry();
  }
}

// ==============================================================================
// SENSOR ACQUISITION & CALIBRATION FUNCTIONS
// ==============================================================================

// Reads analog pin with oversampling and median filtering to reject electrical noise
float readAnalogVoltage(int pin, int samples = 20) {
  int rawValues[samples];
  for (int i = 0; i < samples; i++) {
    rawValues[i] = analogRead(pin);
    delay(5);
  }
  // Simple bubble sort for median selection
  for (int i = 0; i < samples - 1; i++) {
    for (int j = i + 1; j < samples; j++) {
      if (rawValues[i] > rawValues[j]) {
        int temp = rawValues[i];
        rawValues[i] = rawValues[j];
        rawValues[j] = temp;
      }
    }
  }
  int medianRaw = rawValues[samples / 2];
  return ((float)medianRaw / ADC_RESOLUTION) * VREF;
}

// Water Temperature Acquisition (°C)
float readWaterTemperature() {
  tempSensors.requestTemperatures();
  float tempC = tempSensors.getTempCByIndex(0);
  // -127.0 is the Dallas library error code for disconnected sensor probe
  if (tempC == DEVICE_DISCONNECTED_C || tempC < -10.0 || tempC > 85.0) {
    Serial.println("[WARN] DS18B20 probe disconnected or reading out of bounds. Using 25.0°C baseline.");
    return 25.0; // Nominal fallback for temperature compensation
  }
  return tempC;
}

// pH Sensor Measurement with Temperature Compensation
float readPH(float waterTempC) {
  float voltage = readAnalogVoltage(PIN_PH_ANALOG);
  
  // Two-point linear calibration: pH = 7.0 + ((V_neutral - V) * (7.0 - 4.01) / (V_neutral - V_acid))
  float slope = (7.00 - 4.01) / (PH_CALIB_V_NEUTRAL - PH_CALIB_V_ACID);
  float phVal = 7.00 + ((PH_CALIB_V_NEUTRAL - voltage) * slope);

  // Nernst temperature compensation: (T_K / 298.15)
  float tempK = waterTempC + 273.15;
  phVal = 7.00 + ((phVal - 7.00) * (tempK / 298.15));

  // Bound check physical instrument limits
  if (phVal < 0.0) phVal = 0.0;
  if (phVal > 14.0) phVal = 14.0;
  return phVal;
}

// TDS / Electrical Conductivity Measurement (ppm)
float readTDS(float waterTempC) {
  float voltage = readAnalogVoltage(PIN_TDS_ANALOG);
  
  // Temperature compensation formula: V_25 = V_actual / (1.0 + 0.02 * (T - 25.0))
  float compensationCoefficient = 1.0 + TDS_TEMP_COEFFICIENT * (waterTempC - 25.0);
  float compensationVoltage = voltage / compensationCoefficient;

  // Empirical TDS equation: TDS (ppm) = (133.42 * V^3 - 255.86 * V^2 + 857.39 * V) * 0.5
  float tds = (133.42 * pow(compensationVoltage, 3) - 255.86 * pow(compensationVoltage, 2) + 857.39 * compensationVoltage) * 0.5;
  if (tds < 0.0) tds = 0.0;
  if (tds > 2000.0) tds = 2000.0; // Typical sensor ceiling
  return tds;
}

// Optical Turbidity Measurement (NTU)
float readTurbidity() {
  float voltage = readAnalogVoltage(PIN_TURBIDITY_ANALOG);
  
  // Gravity optical turbidity sensor curve:
  // For V >= 2.5V: NTU = -1120.4 * V^2 + 5742.3 * V - 4352.9
  // Below 2.5V: saturated high turbidity (NTU > 3000)
  float ntu = 0.0;
  if (voltage >= 2.5) {
    ntu = -1120.4 * pow(voltage, 2) + 5742.3 * voltage - 4352.9;
    if (ntu < 0.0) ntu = 0.0;
  } else {
    ntu = 3000.0;
  }
  return ntu;
}

// GPS Coordinates & Timestamp Acquisition
void getGPSData(double &lat, double &lng, unsigned long &epochTime) {
#if ENABLE_GPS
  if (gps.location.isValid() && gps.location.age() < 10000) {
    lat = gps.location.lat();
    lng = gps.location.lng();
  } else {
    lat = 6.9380; // Blue River Station
    lng = 79.8720;
  }
#else
  // Default configured station reference coordinates
  lat = 6.9380; // Blue River Station
  lng = 79.8720;
#endif

  time_t nowSec;
  time(&nowSec);
  epochTime = (unsigned long)nowSec;
}

// ==============================================================================
// TELEMETRY PROCESSING & DISPATCH
// ==============================================================================
void processAndDispatchTelemetry() {
  digitalWrite(PIN_STATUS_LED, HIGH);

  float temp = readWaterTemperature();
  float ph = readPH(temp);
  float tds = readTDS(temp);
  float turb = readTurbidity();

  double lat, lng;
  unsigned long epochSec;
  getGPSData(lat, lng, epochSec);

  Serial.println("--------------------------------------------------------");
  Serial.printf("[SENSOR] Water Temp: %.1f °C | pH: %.2f | TDS: %.1f ppm | Turbidity: %.1f NTU\n",
                temp, ph, tds, turb);
  Serial.printf("[GPS] Lat: %.5f | Lng: %.5f | Epoch: %lu\n", lat, lng, epochSec);

  TelemetryPacket packet;
  packet.ph = ph;
  packet.tdsEc = tds;
  packet.turbidity = turb;
  packet.temperature = temp;
  packet.latitude = lat;
  packet.longitude = lng;
  packet.timestampEpoch = epochSec;
  packet.isAnomaly = (turb > 15.0 || ph < 6.0 || ph > 9.0 || tds > 1000.0);

  // If WiFi is disconnected, queue packet locally
  if (WiFi.status() != WL_CONNECTED) {
    Serial.println("[OFFLINE] WiFi unavailable. Storing packet in local offline queue...");
    enqueuePacket(packet);
    connectWiFiAsync();
    digitalWrite(PIN_STATUS_LED, LOW);
    return;
  }

  // Flush any previously buffered offline packets first (FIFO)
  flushOfflineQueue();

  // Transmit current live packet
  bool sent = sendToFirestore(packet);
  if (!sent) {
    Serial.println("[ERROR] Failed to send telemetry to Firestore. Enqueuing for retry.");
    enqueuePacket(packet);
  } else {
    Serial.println("[SUCCESS] Live telemetry packet committed to Firebase Firestore.");
  }

  digitalWrite(PIN_STATUS_LED, LOW);
}

// Obtains/refreshes Firebase ID Token via Google Identity Toolkit REST API
bool refreshFirebaseAuthToken() {
  if (WiFi.status() != WL_CONNECTED) return false;
  
  WiFiClientSecure client;
  client.setInsecure();
  HTTPClient https;
  
  char url[256];
  snprintf(url, sizeof(url),
           "https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=%s",
           FIREBASE_API_KEY);

  if (!https.begin(client, url)) return false;
  https.addHeader("Content-Type", "application/json");

  String authPayload = "{\"email\":\"" + String(FIREBASE_AUTH_EMAIL) + "\",\"password\":\"" + String(FIREBASE_AUTH_PASS) + "\",\"returnSecureToken\":true}";
  int httpCode = https.POST(authPayload);

  if (httpCode == 200) {
    String response = https.getString();
    int tokenIdx = response.indexOf("\"idToken\": \"");
    if (tokenIdx != -1) {
      int start = tokenIdx + 12;
      int end = response.indexOf("\"", start);
      firebaseIdToken = response.substring(start, end);
      tokenExpiryTime = millis() + 3000000; // ~50 minutes
      Serial.println("[AUTH] Firebase Auth Bearer token acquired successfully.");
    }
    int uidIdx = response.indexOf("\"localId\": \"");
    if (uidIdx != -1) {
      int uStart = uidIdx + 12;
      int uEnd = response.indexOf("\"", uStart);
      firebaseUid = response.substring(uStart, uEnd);
      Serial.printf("[AUTH] Authenticated as UID: %s\n", firebaseUid.c_str());
    }
    https.end();
    return true;
  } else {
    Serial.printf("[AUTH] Auth sign-in returned code %d (fallback to API key)\n", httpCode);
  }
  https.end();
  return false;
}

// ==============================================================================
// FIRESTORE REST API INTEGRATION
// ==============================================================================
// Schema exactly maps to:
// - Collection: measurements/{docId}
// - Document fields:
//   sourceId (string), deviceId (string), ph (double), tdsEc (double),
//   turbidity (double), temperature (double), latitude (double),
//   longitude (double), timestamp (string ISO), submittedBy (string),
//   source (string = "device"), syncedAt (string ISO), notes (string)
bool sendToFirestore(const TelemetryPacket &pkt) {
  // Check if Firebase Auth token requires refresh
  if (firebaseIdToken.length() == 0 || millis() > tokenExpiryTime) {
    refreshFirebaseAuthToken();
  }

  WiFiClientSecure client;
  client.setInsecure(); // Uses TLS encryption without hardcoding root CA cert expiration

  HTTPClient https;
  char url[256];
  snprintf(url, sizeof(url),
           "https://firestore.googleapis.com/v1/projects/%s/databases/(default)/documents/measurements?key=%s",
           FIREBASE_PROJECT_ID, FIREBASE_API_KEY);

  if (!https.begin(client, url)) {
    Serial.println("[HTTP] Unable to establish HTTPS connection.");
    return false;
  }

  https.addHeader("Content-Type", "application/json");
  if (firebaseIdToken.length() > 0) {
    https.addHeader("Authorization", "Bearer " + firebaseIdToken);
  }

  // Format ISO8601 UTC timestamp
  char timeBuf[30];
  time_t rawTime = (time_t)pkt.timestampEpoch;
  struct tm *ti = gmtime(&rawTime);
  strftime(timeBuf, sizeof(timeBuf), "%Y-%m-%dT%H:%M:%SZ", ti);

  String submitter = firebaseUid.length() > 0 ? firebaseUid : String(DEVICE_ID);

  // Construct Firestore document REST JSON payload
  String payload = "{\n  \"fields\": {\n";
  payload += "    \"sourceId\": {\"stringValue\": \"" + String(WATER_SOURCE_ID) + "\"},\n";
  payload += "    \"deviceId\": {\"stringValue\": \"" + String(DEVICE_ID) + "\"},\n";
  payload += "    \"waterSourceName\": {\"stringValue\": \"" + String(WATER_SOURCE_NAME) + "\"},\n";
  payload += "    \"ph\": {\"doubleValue\": " + String(pkt.ph, 2) + "},\n";
  payload += "    \"tdsEc\": {\"doubleValue\": " + String(pkt.tdsEc, 1) + "},\n";
  payload += "    \"turbidity\": {\"doubleValue\": " + String(pkt.turbidity, 1) + "},\n";
  payload += "    \"temperature\": {\"doubleValue\": " + String(pkt.temperature, 1) + "},\n";
  payload += "    \"latitude\": {\"doubleValue\": " + String(pkt.latitude, 5) + "},\n";
  payload += "    \"longitude\": {\"doubleValue\": " + String(pkt.longitude, 5) + "},\n";
  payload += "    \"timestamp\": {\"stringValue\": \"" + String(timeBuf) + "\"},\n";
  payload += "    \"submittedBy\": {\"stringValue\": \"" + submitter + "\"},\n";
  payload += "    \"source\": {\"stringValue\": \"device\"},\n";
  payload += "    \"syncedAt\": {\"stringValue\": \"" + String(timeBuf) + "\"},\n";
  payload += "    \"notes\": {\"stringValue\": \"" + String(pkt.isAnomaly ? "Unusual measurement detected by node" : "Routine telemetry packet") + "\"}\n";
  payload += "  }\n}";

  Serial.printf("[FIRESTORE] Uploading reading for '%s' (%s)...\n", WATER_SOURCE_NAME, WATER_SOURCE_ID);
  int httpCode = https.POST(payload);
  String responseText = https.getString();
  https.end();

  if (httpCode >= 200 && httpCode < 300) {
    Serial.printf("[HTTP %d] Firestore accepted packet successfully.\n", httpCode);
    return true;
  } else {
    Serial.printf("[HTTP ERROR %d] %s\n", httpCode, responseText.c_str());
    return false;
  }
}

// ==============================================================================
// LOCAL OFFLINE QUEUE MANAGEMENT
// ==============================================================================
void enqueuePacket(const TelemetryPacket &pkt) {
  if (queueCount < OFFLINE_QUEUE_CAPACITY) {
    offlineQueue[queueTail] = pkt;
    queueTail = (queueTail + 1) % OFFLINE_QUEUE_CAPACITY;
    queueCount++;
    Serial.printf("[QUEUE] Enqueued offline packet. Current count: %d/%d\n",
                  queueCount, OFFLINE_QUEUE_CAPACITY);
  } else {
    // Buffer overflow: overwrite oldest packet (circular overwrite)
    offlineQueue[queueTail] = pkt;
    queueTail = (queueTail + 1) % OFFLINE_QUEUE_CAPACITY;
    queueHead = (queueHead + 1) % OFFLINE_QUEUE_CAPACITY;
    Serial.println("[QUEUE] Buffer full. Overwritten oldest sample.");
  }
}

void flushOfflineQueue() {
  if (queueCount == 0) return;
  Serial.printf("[QUEUE] Flushing %d buffered offline packet(s)...\n", queueCount);

  while (queueCount > 0) {
    TelemetryPacket &pkt = offlineQueue[queueHead];
    bool sent = sendToFirestore(pkt);
    if (sent) {
      queueHead = (queueHead + 1) % OFFLINE_QUEUE_CAPACITY;
      queueCount--;
      delay(200); // Gentle throttle between consecutive bursts
    } else {
      Serial.println("[QUEUE] Flush interrupted by network failure.");
      break;
    }
  }
}

// ==============================================================================
// WIFI CONNECTIVITY & RECOVERY
// ==============================================================================
void connectWiFi() {
  Serial.printf("[WIFI] Connecting to SSID '%s'...", WIFI_SSID);
  WiFi.mode(WIFI_STA);
  WiFi.begin(WIFI_SSID, WIFI_PASSWORD);

  unsigned long startAttempt = millis();
  while (WiFi.status() != WL_CONNECTED && millis() - startAttempt < 10000) {
    delay(500);
    Serial.print(".");
  }

  if (WiFi.status() == WL_CONNECTED) {
    Serial.printf("\n[WIFI] Connected! Assigned IP: %s (RSSI: %d dBm)\n",
                  WiFi.localIP().toString().c_str(), WiFi.RSSI());
  } else {
    Serial.println("\n[WIFI] Connection timeout. Running in offline buffering mode.");
  }
}

void connectWiFiAsync() {
  if (WiFi.status() != WL_CONNECTED) {
    WiFi.begin(WIFI_SSID, WIFI_PASSWORD);
  }
}
