# 💧 AquaGuard: IoT-Based Smart Water Quality Monitoring & Community Mapping System

> **IoTrix 2.0 Semi-Final Submission**  
> **Track:** Track A – Embedded IoT System  
> **Interactive Simulation:** [Live Wokwi Simulation](https://wokwi.com) *(Insert your public Wokwi share link here)*

---

## 📌 Project Overview
AquaGuard is a portable, low-cost IoT device designed to monitor critical water quality indicators (pH, TDS/EC, Turbidity, Temperature) and attach precise spatial coordinates via GPS. Collected data is transmitted to a cloud backend and rendered on a mobile application for real-time visualization and community water mapping.

*Note: AquaGuard serves as an early-anomaly identification tool; it does not independently certify water as potable.*

---

## 🔧 Hardware & Technology Stack
* **Microcontroller:** ESP32 Dev Module
* **Sensors:** Analog pH Sensor, Analog TDS/EC Sensor, Optical Turbidity Sensor, DS18B20 Temperature Sensor, NEO-6M GPS Module
* **Backend & Mobile:** Firebase Realtime Database, Flutter / React Native, Google Maps API

---

## 📐 System Architecture & Wokwi Circuit
![Wokwi Circuit Diagram](docs/wokwi_circuit.png)

---

## 🚀 How to Run the Flutter App
```bash
flutter pub get
flutter run
```

---

## 🌐 How to Run the Web Build
```bash
flutter build web --release
```
Then open `build/web/index.html` in your browser, or deploy to Vercel.

---

## 📊 Technical Validation & Testing
| Metric / Feature | Test Procedure | Status / Result |
| :--- | :--- | :--- |
| **Sensor Sampling** | Measured simulated analog variance across pH & TDS pots. | Verified dynamic mapping in ADC firmware. |
| **GPS Fix** | Tested UART NMEA sentence processing. | Lat/Long coordinates logged successfully. |
| **Data Buffering** | Tested network drop handling. | System buffers logs locally when offline. |

---

## 👥 Team
* **Team Name:** [Your Team Name]
* **Repository Link:** [https://github.com/ANafeesh/AquaGuard-IoT](https://github.com/ANafeesh/AquaGuard-IoT)
