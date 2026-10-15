#include <Arduino.h>
#include <WiFi.h>
#include <WiFiClientSecure.h>
#include <HTTPClient.h>
#include <ArduinoJson.h>
#include <OneWire.h>
#include <DallasTemperature.h>
#include <TinyGPSPlus.h>
#include <math.h>
#include <time.h>
#include <stdlib.h>
#include <string.h>
#include "firebase_root_ca.h"

#if __has_include("secrets.h")
#include "secrets.h"
#endif

#ifndef AQUAGUARD_WIFI_SSID
#define AQUAGUARD_WIFI_SSID "Wokwi-GUEST"
#endif
#ifndef AQUAGUARD_WIFI_PASSWORD
#define AQUAGUARD_WIFI_PASSWORD ""
#endif
#ifndef AQUAGUARD_FIREBASE_PROJECT_ID
#define AQUAGUARD_FIREBASE_PROJECT_ID "aquaguard-iot-b8ce2"
#endif
#ifndef AQUAGUARD_FIREBASE_API_KEY
#define AQUAGUARD_FIREBASE_API_KEY ""
#endif
#ifndef AQUAGUARD_FIREBASE_DATABASE_URL
#define AQUAGUARD_FIREBASE_DATABASE_URL ""
#endif
#ifndef AQUAGUARD_FIREBASE_EMAIL
#define AQUAGUARD_FIREBASE_EMAIL ""
#endif
#ifndef AQUAGUARD_FIREBASE_PASSWORD
#define AQUAGUARD_FIREBASE_PASSWORD ""
#endif
#ifndef AQUAGUARD_DEVICE_ID
#define AQUAGUARD_DEVICE_ID "esp32_node_river_01"
#endif
#ifndef AQUAGUARD_TARGET_SOURCE_ID
#define AQUAGUARD_TARGET_SOURCE_ID "demo_src_river"
#endif
#ifndef AQUAGUARD_TARGET_SOURCE_NAME
#define AQUAGUARD_TARGET_SOURCE_NAME "Blue River Reach"
#endif
#ifndef AQUAGUARD_HOME_TANK_ID
#define AQUAGUARD_HOME_TANK_ID ""
#endif

namespace {

// ==============================================================================
// HARDWARE PIN DEFINITIONS (Matching Wokwi diagram.json)
// ==============================================================================
constexpr uint8_t kPhPin = 36;          // ADC1_CH0 (Potentiometer standing in for pH probe)
constexpr uint8_t kTdsPin = 39;         // ADC1_CH3 (Potentiometer standing in for TDS sensor)
constexpr uint8_t kTurbidityPin = 34;   // ADC1_CH6 (Potentiometer standing in for Turbidity sensor)
constexpr uint8_t kTemperaturePin = 4;  // OneWire (DS18B20 digital temperature probe)
constexpr uint8_t kGpsRxPin = 16;       // ESP32 RX2 (Connected to GPS module TX)
constexpr uint8_t kGpsTxPin = 17;       // ESP32 TX2 (Connected to GPS module RX)
constexpr uint8_t kBuzzerPin = 25;      // Piezo buzzer
constexpr uint8_t kAlarmLedPin = 26;    // Red alarm LED (via 220 ohm resistor)

// Telemetry & Timing Configuration
constexpr uint32_t kSampleIntervalMs = 2500;
constexpr uint32_t kAlarmDurationMs = 350;
constexpr size_t kOfflineQueueCapacity = 16;
constexpr uint32_t kWifiConnectTimeoutMs = 15000;
constexpr uint32_t kClockSyncTimeoutMs = 15000;
constexpr uint32_t kFirebaseRetryDelayMs = 25000;

// AquaGuard Mobile App Standard Parameter Thresholds
constexpr float kPhMin = 6.5F;
constexpr float kPhMax = 8.5F;
constexpr float kTdsMin = 150.0F;
constexpr float kTdsMax = 500.0F;
constexpr float kTurbidityMin = 0.5F;
constexpr float kTurbidityMax = 5.0F;
constexpr float kTemperatureMin = 20.0F;
constexpr float kTemperatureMax = 32.0F;

// Anomaly Delta Limits (Sudden single-step change triggers alert)
constexpr float kDeltaPh = 1.5F;
constexpr float kDeltaTds = 150.0F;
constexpr float kDeltaTurbidity = 15.0F;
constexpr float kDeltaTemperature = 5.0F;

struct Reading {
  uint32_t sequence;
  uint32_t timestampMs;
  float ph;
  float tds;
  float turbidity;
  float temperature;
  double latitude;
  double longitude;
  bool locationValid;
  bool withinTypicalRange;
  bool anomaly;
};

OneWire oneWire(kTemperaturePin);
DallasTemperature temperatureSensor(&oneWire);
HardwareSerial gpsSerial(2);
TinyGPSPlus gps;

Reading offlineQueue[kOfflineQueueCapacity];
size_t queueHead = 0;
size_t queueCount = 0;
uint32_t nextSequence = 1;
uint32_t lastSampleMs = 0;
uint32_t alarmOffAtMs = 0;
uint32_t nextFirebaseAttemptAtMs = 0;
String firebaseIdToken;
String firebaseUid;
uint32_t tokenRefreshAtMs = 0;
bool sendingEnabled = true;
bool firebaseConfigWarningShown = false;
bool hasPreviousReading = false;
bool alarmActive = false;
bool forceAnomaly = false;
Reading previousReading{};

// Dynamic runtime configuration
String targetProjectId = AQUAGUARD_FIREBASE_PROJECT_ID;
String targetDeviceId = AQUAGUARD_DEVICE_ID;
String targetSourceId = AQUAGUARD_TARGET_SOURCE_ID;
String targetSourceName = AQUAGUARD_TARGET_SOURCE_NAME;
String targetHomeTankId = AQUAGUARD_HOME_TANK_ID;

float readAnalogScale(uint8_t pin, float maximum) {
  return (static_cast<float>(analogRead(pin)) / 4095.0F) * maximum;
}

void readGpsData() {
  while (gpsSerial.available() > 0) {
    gps.encode(static_cast<char>(gpsSerial.read()));
  }
}

bool hasFreshGpsFix() {
  return gps.location.isValid() && gps.location.age() < 10000;
}

bool isWithinTypicalRange(const Reading& reading) {
  return reading.ph >= kPhMin && reading.ph <= kPhMax &&
         reading.tds >= kTdsMin && reading.tds <= kTdsMax &&
         reading.turbidity >= kTurbidityMin &&
         reading.turbidity <= kTurbidityMax &&
         reading.temperature >= kTemperatureMin &&
         reading.temperature <= kTemperatureMax;
}

bool isAnomaly(const Reading& reading) {
  if (forceAnomaly) {
    forceAnomaly = false;
    return true;
  }
  if (!hasPreviousReading) {
    return false;
  }
  return fabsf(reading.ph - previousReading.ph) > kDeltaPh ||
         fabsf(reading.tds - previousReading.tds) > kDeltaTds ||
         fabsf(reading.turbidity - previousReading.turbidity) > kDeltaTurbidity ||
         fabsf(reading.temperature - previousReading.temperature) > kDeltaTemperature;
}

bool firebaseConfigured() {
  return strlen(AQUAGUARD_WIFI_SSID) > 0 &&
         strlen(AQUAGUARD_FIREBASE_API_KEY) > 0 &&
         strlen(AQUAGUARD_FIREBASE_EMAIL) > 0 &&
         strlen(AQUAGUARD_FIREBASE_PASSWORD) > 0 &&
         (targetProjectId.length() > 0 || strlen(AQUAGUARD_FIREBASE_DATABASE_URL) > 0);
}

bool connectToWifi() {
  if (WiFi.status() == WL_CONNECTED) {
    return true;
  }
  if (strlen(AQUAGUARD_WIFI_SSID) == 0) {
    Serial.println("[WIFI ERROR] Configure AQUAGUARD_WIFI_SSID in include/secrets.h.");
    return false;
  }

  WiFi.mode(WIFI_STA);
  WiFi.begin(AQUAGUARD_WIFI_SSID, AQUAGUARD_WIFI_PASSWORD);
  Serial.printf("[WIFI] Connecting to '%s'", AQUAGUARD_WIFI_SSID);
  const uint32_t startedAt = millis();
  while (WiFi.status() != WL_CONNECTED &&
         millis() - startedAt < kWifiConnectTimeoutMs) {
    readGpsData();
    delay(100);
    Serial.print(".");
  }
  Serial.println();

  if (WiFi.status() != WL_CONNECTED) {
    Serial.printf("[WIFI ERROR] Connection failed (status %d).\n",
                  static_cast<int>(WiFi.status()));
    return false;
  }

  Serial.printf("[WIFI] Connected; IP address: %s\n",
                WiFi.localIP().toString().c_str());
  return true;
}

bool synchronizeClock() {
  if (time(nullptr) > 1700000000) {
    return true;
  }

  configTime(0, 0, "pool.ntp.org", "time.google.com");
  const uint32_t startedAt = millis();
  while (time(nullptr) <= 1700000000 &&
         millis() - startedAt < kClockSyncTimeoutMs) {
    readGpsData();
    delay(200);
  }

  if (time(nullptr) <= 1700000000) {
    Serial.println("[TIME WARN] NTP time sync pending; using fallback epoch.");
    return false;
  }
  Serial.println("[TIME] System clock synchronized with NTP.");
  return true;
}

bool authenticateFirebase() {
  if (!firebaseConfigured()) {
    Serial.println("[FIREBASE ERROR] Complete include/secrets.h before enabling Firebase.");
    return false;
  }
  if (!connectToWifi()) {
    return false;
  }
  synchronizeClock();

  WiFiClientSecure secureClient;
  secureClient.setCACert(kGoogleRootR1);
  HTTPClient http;
  http.setTimeout(12000);

  const String authUrl =
      String("https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=") +
      AQUAGUARD_FIREBASE_API_KEY;
  if (!http.begin(secureClient, authUrl)) {
    Serial.println("[FIREBASE ERROR] Could not initialize the authentication request.");
    return false;
  }

  JsonDocument request;
  request["email"] = AQUAGUARD_FIREBASE_EMAIL;
  request["password"] = AQUAGUARD_FIREBASE_PASSWORD;
  request["returnSecureToken"] = true;
  String requestBody;
  serializeJson(request, requestBody);

  http.addHeader("Content-Type", "application/json");
  const int status = http.POST(requestBody);
  const String responseBody = status > 0 ? http.getString() : String();
  const String error = status > 0 ? String() : http.errorToString(status);
  http.end();

  if (status < 200 || status >= 300) {
    Serial.printf("[FIREBASE AUTH ERROR] HTTP %d: %s\n", status,
                  status > 0 ? responseBody.c_str() : error.c_str());
    return false;
  }

  JsonDocument response;
  const DeserializationError parseError = deserializeJson(response, responseBody);
  if (parseError) {
    Serial.printf("[FIREBASE AUTH ERROR] Invalid response: %s\n", parseError.c_str());
    return false;
  }

  const char* idToken = response["idToken"] | "";
  const char* uid = response["localId"] | "";
  const char* expiresIn = response["expiresIn"] | "3600";
  if (strlen(idToken) == 0 || strlen(uid) == 0) {
    Serial.println("[FIREBASE AUTH ERROR] Missing ID token and user ID in auth response.");
    return false;
  }

  firebaseIdToken = idToken;
  firebaseUid = uid;
  const uint32_t lifetimeSeconds = strtoul(expiresIn, nullptr, 10);
  const uint32_t refreshSeconds = lifetimeSeconds > 120 ? lifetimeSeconds - 60 : 60;
  tokenRefreshAtMs = millis() + refreshSeconds * 1000UL;
  Serial.printf("[FIREBASE] Authentication succeeded (UID: %s).\n", firebaseUid.c_str());
  return true;
}

bool ensureFirebaseAuthenticated() {
  if (!firebaseIdToken.isEmpty() &&
      static_cast<int32_t>(millis() - tokenRefreshAtMs) < 0) {
    return true;
  }
  firebaseIdToken.clear();
  firebaseUid.clear();
  return authenticateFirebase();
}

String getIso8601Timestamp() {
  char timeBuf[30];
  time_t rawTime = time(nullptr);
  if (rawTime > 1700000000) {
    struct tm* ti = gmtime(&rawTime);
    strftime(timeBuf, sizeof(timeBuf), "%Y-%m-%dT%H:%M:%SZ", ti);
  } else {
    // Fallback ISO timestamp if clock uncalibrated
    snprintf(timeBuf, sizeof(timeBuf), "2026-10-15T12:00:00Z");
  }
  return String(timeBuf);
}

// ==============================================================================
// CLOUD FIRESTORE REST API (Primary for AquaGuard Flutter Mobile App)
// ==============================================================================
bool uploadToFirestore(const Reading& reading) {
  if (targetProjectId.isEmpty() || strlen(AQUAGUARD_FIREBASE_API_KEY) == 0) {
    return false;
  }

  const String timestamp = getIso8601Timestamp();
  String collectionPath;
  if (targetHomeTankId.length() > 0) {
    collectionPath = "home_tanks/" + targetHomeTankId + "/readings";
  } else {
    collectionPath = "measurements";
  }

  const String url = String("https://firestore.googleapis.com/v1/projects/") +
                     targetProjectId + "/databases/(default)/documents/" +
                     collectionPath + "?key=" + AQUAGUARD_FIREBASE_API_KEY;

  JsonDocument doc;
  JsonObject fields = doc["fields"].to<JsonObject>();

  if (targetHomeTankId.length() > 0) {
    fields["tankId"]["stringValue"] = targetHomeTankId;
    fields["ownerUid"]["stringValue"] = firebaseUid;
  } else {
    fields["sourceId"]["stringValue"] = targetSourceId;
    fields["waterSourceName"]["stringValue"] = targetSourceName;
  }

  fields["deviceId"]["stringValue"] = targetDeviceId;
  fields["submittedBy"]["stringValue"] = targetDeviceId;
  fields["source"]["stringValue"] = "device";
  fields["ph"]["doubleValue"] = reading.ph;
  fields["tdsEc"]["doubleValue"] = reading.tds;
  fields["turbidity"]["doubleValue"] = reading.turbidity;
  fields["temperature"]["doubleValue"] = reading.temperature;

  if (reading.locationValid) {
    fields["latitude"]["doubleValue"] = reading.latitude;
    fields["longitude"]["doubleValue"] = reading.longitude;
  } else {
    fields["latitude"]["doubleValue"] = 6.9271;
    fields["longitude"]["doubleValue"] = 79.8612;
  }

  fields["timestamp"]["stringValue"] = timestamp;
  fields["syncedAt"]["stringValue"] = timestamp;
  fields["status"]["stringValue"] = reading.withinTypicalRange ? "withinTypicalRange" : "unusual";
  fields["notes"]["stringValue"] = reading.anomaly ? "ANOMALY: Sudden single-step delta spike" : "Simulated ESP32 live packet";

  String requestBody;
  serializeJson(doc, requestBody);

  WiFiClientSecure secureClient;
  secureClient.setCACert(kGoogleRootR1);
  HTTPClient http;
  http.setTimeout(12000);

  if (!http.begin(secureClient, url)) {
    Serial.println("[FIRESTORE ERROR] Could not initialize HTTPS connection.");
    return false;
  }

  http.addHeader("Content-Type", "application/json");
  if (firebaseIdToken.length() > 0) {
    http.addHeader("Authorization", "Bearer " + firebaseIdToken);
  }

  const int status = http.POST(requestBody);
  const String responseBody = status > 0 ? http.getString() : String();
  const String error = status > 0 ? String() : http.errorToString(status);
  http.end();

  if (status < 200 || status >= 300) {
    Serial.printf("[FIRESTORE WRITE ERROR] HTTP %d: %s\n", status,
                  status > 0 ? responseBody.c_str() : error.c_str());
    return false;
  }

  Serial.printf("[FIRESTORE] Committed sample AG-%06lu directly to %s!\n",
                static_cast<unsigned long>(reading.sequence), collectionPath.c_str());
  return true;
}

// ==============================================================================
// REALTIME DATABASE INGESTION (Secondary / Dual Mode)
// ==============================================================================
bool uploadToRealtimeDatabase(const Reading& reading) {
  if (strlen(AQUAGUARD_FIREBASE_DATABASE_URL) == 0) return false;

  String databaseUrl = AQUAGUARD_FIREBASE_DATABASE_URL;
  while (databaseUrl.endsWith("/")) {
    databaseUrl.remove(databaseUrl.length() - 1);
  }
  const String url = databaseUrl + "/users/" + firebaseUid +
                     "/readings.json?auth=" + firebaseIdToken;

  JsonDocument document;
  document["sourceId"] = targetSourceId;
  document["deviceId"] = targetDeviceId;
  document["sequence"] = reading.sequence;
  document["ph"] = reading.ph;
  document["tdsEc"] = reading.tds;
  document["turbidity"] = reading.turbidity;
  document["temperature"] = reading.temperature;
  if (reading.locationValid) {
    document["latitude"] = reading.latitude;
    document["longitude"] = reading.longitude;
  } else {
    document["latitude"] = nullptr;
    document["longitude"] = nullptr;
  }
  document["timestamp"] = getIso8601Timestamp();
  document["timestampMs"] = reading.timestampMs;
  document["status"] = reading.withinTypicalRange ? "withinTypicalRange" : "unusual";
  document["anomaly"] = reading.anomaly;
  document["simulated"] = true;

  String requestBody;
  serializeJson(document, requestBody);

  WiFiClientSecure secureClient;
  secureClient.setCACert(kGoogleRootR1);
  HTTPClient http;
  http.setTimeout(12000);
  if (!http.begin(secureClient, url)) {
    return false;
  }
  http.addHeader("Content-Type", "application/json");
  const int status = http.POST(requestBody);
  http.end();

  if (status >= 200 && status < 300) {
    Serial.printf("[RTDB] Saved sample AG-%06lu under /users/%s/readings.\n",
                  static_cast<unsigned long>(reading.sequence), firebaseUid.c_str());
    return true;
  }
  return false;
}

bool uploadReading(const Reading& reading) {
  if (!firebaseConfigured()) {
    if (!firebaseConfigWarningShown) {
      Serial.println("[FIREBASE WARN] Firebase credentials incomplete in include/secrets.h.");
      firebaseConfigWarningShown = true;
    }
    return false;
  }
  if (static_cast<int32_t>(millis() - nextFirebaseAttemptAtMs) < 0) {
    return false;
  }
  if (!ensureFirebaseAuthenticated()) {
    nextFirebaseAttemptAtMs = millis() + kFirebaseRetryDelayMs;
    return false;
  }

  bool firestoreOk = false;
  if (targetProjectId.length() > 0) {
    firestoreOk = uploadToFirestore(reading);
  }

  if (strlen(AQUAGUARD_FIREBASE_DATABASE_URL) > 0) {
    uploadToRealtimeDatabase(reading);
  }

  if (firestoreOk) {
    nextFirebaseAttemptAtMs = millis();
    return true;
  } else {
    nextFirebaseAttemptAtMs = millis() + kFirebaseRetryDelayMs;
    return false;
  }
}

void printTelemetry(const Reading& reading) {
  const String timestamp = getIso8601Timestamp();
  Serial.printf(
      "{\"id\":\"AG-%06lu\",\"sourceId\":\"%s\",\"deviceId\":\"%s\","
      "\"ph\":%.2f,\"tdsEc\":%.1f,\"turbidity\":%.1f,\"temperature\":%.1f,"
      "\"status\":\"%s\",\"anomaly\":%s,\"timestamp\":\"%s\",",
      static_cast<unsigned long>(reading.sequence),
      targetHomeTankId.length() > 0 ? targetHomeTankId.c_str() : targetSourceId.c_str(),
      targetDeviceId.c_str(),
      reading.ph,
      reading.tds,
      reading.turbidity,
      reading.temperature,
      reading.withinTypicalRange ? "withinTypicalRange" : "unusual",
      reading.anomaly ? "true" : "false",
      timestamp.c_str());

  if (reading.locationValid) {
    Serial.printf("\"latitude\":%.6f,\"longitude\":%.6f", reading.latitude, reading.longitude);
  } else {
    Serial.print("\"latitude\":null,\"longitude\":null");
  }
  Serial.println(",\"simulated\":true}");
}

void triggerAlarm() {
  digitalWrite(kAlarmLedPin, HIGH);
  tone(kBuzzerPin, 2200);
  alarmOffAtMs = millis() + kAlarmDurationMs;
  alarmActive = true;
}

void updateAlarm(uint32_t now) {
  if (alarmActive && static_cast<int32_t>(now - alarmOffAtMs) >= 0) {
    noTone(kBuzzerPin);
    digitalWrite(kAlarmLedPin, LOW);
    alarmActive = false;
  }
}

void enqueueOffline(const Reading& reading) {
  if (queueCount == kOfflineQueueCapacity) {
    queueHead = (queueHead + 1) % kOfflineQueueCapacity;
    --queueCount;
    Serial.println("[OFFLINE] Buffer full; discarded oldest queued sample.");
  }

  const size_t tail = (queueHead + queueCount) % kOfflineQueueCapacity;
  offlineQueue[tail] = reading;
  ++queueCount;
  Serial.printf("[OFFLINE] Buffered sample AG-%06lu (%u/%u).\n",
                static_cast<unsigned long>(reading.sequence),
                static_cast<unsigned>(queueCount),
                static_cast<unsigned>(kOfflineQueueCapacity));
}

void flushOfflineQueue() {
  if (queueCount == 0) {
    return;
  }

  Serial.printf("[OFFLINE] Uploading %u queued sample(s) to Firebase in FIFO order.\n",
                static_cast<unsigned>(queueCount));
  while (queueCount > 0) {
    if (!uploadReading(offlineQueue[queueHead])) {
      Serial.printf("[OFFLINE] Upload failed; %u sample(s) remain buffered in RAM.\n",
                    static_cast<unsigned>(queueCount));
      return;
    }
    queueHead = (queueHead + 1) % kOfflineQueueCapacity;
    --queueCount;
  }
}

void handleSerialCommands() {
  while (Serial.available() > 0) {
    String line = Serial.readStringUntil('\n');
    line.trim();
    if (line.isEmpty()) continue;

    int spaceIdx = line.indexOf(' ');
    String command = (spaceIdx == -1) ? line : line.substring(0, spaceIdx);
    command.toUpperCase();
    String arg = (spaceIdx == -1) ? "" : line.substring(spaceIdx + 1);
    arg.trim();

    if (command == "OFFLINE") {
      sendingEnabled = false;
      Serial.println("[FIREBASE] Upload paused; new samples will be queued in RAM buffer.");
    } else if (command == "ONLINE") {
      sendingEnabled = true;
      nextFirebaseAttemptAtMs = 0;
      Serial.println("[FIREBASE] Upload enabled; releasing in-memory queue to Cloud Firestore...");
      flushOfflineQueue();
    } else if (command == "TANK") {
      if (arg.length() > 0) {
        targetHomeTankId = arg;
        Serial.printf("[TARGET] Switched to Private Home Tank: %s\n", targetHomeTankId.c_str());
      } else {
        targetHomeTankId = "demo_tank_01";
        Serial.println("[TARGET] Switched to Private Home Tank: demo_tank_01");
      }
    } else if (command == "SOURCE") {
      targetHomeTankId = "";
      if (arg.length() > 0) {
        targetSourceId = arg;
      }
      Serial.printf("[TARGET] Switched to Public Water Source: %s\n", targetSourceId.c_str());
    } else if (command == "DEVICE") {
      if (arg.length() > 0) {
        targetDeviceId = arg;
        Serial.printf("[DEVICE] Device ID set to: %s\n", targetDeviceId.c_str());
      }
    } else if (command == "STATUS") {
      Serial.println("\n--- AQUAGUARD NODE STATUS ---");
      Serial.printf("WiFi: %s (IP: %s)\n", (WiFi.status() == WL_CONNECTED) ? "CONNECTED" : "DISCONNECTED", WiFi.localIP().toString().c_str());
      Serial.printf("Auth Token: %s\n", firebaseIdToken.length() > 0 ? "VALID" : "NONE/EXPIRED");
      Serial.printf("Upload Mode: %s\n", sendingEnabled ? "ONLINE" : "PAUSED (OFFLINE)");
      Serial.printf("Target Collection: %s\n", targetHomeTankId.length() > 0 ? ("home_tanks/" + targetHomeTankId + "/readings").c_str() : ("measurements (" + targetSourceId + ")").c_str());
      Serial.printf("Device ID: %s\n", targetDeviceId.c_str());
      Serial.printf("Offline Queue: %u/%u samples buffered\n", static_cast<unsigned>(queueCount), static_cast<unsigned>(kOfflineQueueCapacity));
      Serial.println("-----------------------------\n");
    } else if (command == "ANOMALY") {
      forceAnomaly = true;
      Serial.println("[SIMULATION] Forcing anomaly spike on next telemetry cycle.");
    } else {
      Serial.println("[COMMAND] Available commands: OFFLINE, ONLINE, TANK [tankId], SOURCE [sourceId], DEVICE [id], STATUS, ANOMALY");
    }
  }
}

void collectAndReportReading(uint32_t now) {
  temperatureSensor.requestTemperatures();
  const float temperature = temperatureSensor.getTempCByIndex(0);

  if (temperature == DEVICE_DISCONNECTED_C || temperature < -5.0F ||
      temperature > 60.0F) {
    Serial.println("[SENSOR ERROR] DS18B20 missing or returned an invalid temperature.");
    return;
  }

  Reading reading{};
  reading.sequence = nextSequence++;
  reading.timestampMs = now;
  reading.ph = readAnalogScale(kPhPin, 14.0F);
  reading.tds = readAnalogScale(kTdsPin, 1000.0F);
  reading.turbidity = readAnalogScale(kTurbidityPin, 100.0F);
  reading.temperature = temperature;
  reading.locationValid = hasFreshGpsFix();
  if (reading.locationValid) {
    reading.latitude = gps.location.lat();
    reading.longitude = gps.location.lng();
  }
  reading.withinTypicalRange = isWithinTypicalRange(reading);
  reading.anomaly = isAnomaly(reading);

  Serial.printf(
      "[READING] pH %.2f | TDS %.1f ppm | turbidity %.1f NTU | "
      "temperature %.1f C | %s%s\n",
      reading.ph,
      reading.tds,
      reading.turbidity,
      reading.temperature,
      reading.withinTypicalRange ? "within baseline range" : "unusual reading",
      reading.anomaly ? " | ANOMALY: sudden shift" : "");

  if (reading.locationValid) {
    Serial.printf("[GPS] Fix: %.6f, %.6f\n", reading.latitude, reading.longitude);
  } else {
    Serial.println("[GPS] No fresh fix; station default coordinates will be used.");
  }

  if (!reading.withinTypicalRange || reading.anomaly) {
    Serial.println("[ALERT] Unusual parameter detected! Triggering local buzzer & LED alarm.");
    triggerAlarm();
  }

  printTelemetry(reading);

  if (sendingEnabled) {
    if (firebaseConfigured() && queueCount > 0) {
      flushOfflineQueue();
    }
    if (firebaseConfigured() && !uploadReading(reading)) {
      enqueueOffline(reading);
    }
  } else {
    enqueueOffline(reading);
  }

  previousReading = reading;
  hasPreviousReading = true;
}

}  // namespace

void setup() {
  Serial.begin(115200);
  Serial.setTimeout(50);
  analogReadResolution(12);
  temperatureSensor.begin();
  gpsSerial.begin(9600, SERIAL_8N1, kGpsRxPin, kGpsTxPin);
  pinMode(kBuzzerPin, OUTPUT);
  pinMode(kAlarmLedPin, OUTPUT);
  digitalWrite(kAlarmLedPin, LOW);

  Serial.println("\n========================================================");
  Serial.println("  AquaGuard ESP32 IoT Sensor Node Simulation (Wokwi)   ");
  Serial.println("========================================================");
  Serial.println("Potentiometers: pH (GPIO 36), TDS (GPIO 39), Turbidity (GPIO 34)");
  Serial.println("Temperature: DS18B20 (GPIO 4) | GPS: NEO-6M (RX:16, TX:17)");
  Serial.println("Alerts: Piezo Buzzer (GPIO 25), Red LED (GPIO 26)");
  Serial.printf("Target Collection: %s\n", targetHomeTankId.length() > 0 ? ("home_tanks/" + targetHomeTankId + "/readings").c_str() : ("measurements (" + targetSourceId + ")").c_str());

  if (firebaseConfigured()) {
    Serial.println("[INIT] Firebase configured; streaming live to Cloud Firestore.");
  } else {
    Serial.println("[INIT] Firebase not configured; add include/secrets.h to enable uploads.");
  }
  Serial.println("Interactive commands: OFFLINE, ONLINE, TANK [id], SOURCE [id], DEVICE [id], STATUS, ANOMALY\n");
  lastSampleMs = millis() - kSampleIntervalMs;
}

void loop() {
  readGpsData();
  handleSerialCommands();

  const uint32_t now = millis();
  updateAlarm(now);
  if (now - lastSampleMs >= kSampleIntervalMs) {
    lastSampleMs = now;
    collectAndReportReading(now);
  }
}
