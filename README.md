<<<<<<< HEAD
# aquaguard

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
=======
# AquaGuard-IoT
IoT-Based Smart Water Quality Monitoring &amp; Community Mapping System for IoTrix 2.0

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

## 🚀 How to Run the Simulation
1. Open the [Wokwi Public Simulation Link](https://wokwi.com).
2. Click **Start Simulation** (Green Play Button).
3. Open the **Serial Monitor** to observe real-time telemetry output.
4. Interact with potentiometers and temperature sensors to simulate varying water quality conditions.

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
* **Repository Link:** [https://github.com/YourUsername/AquaGuard-IoT](https://github.com/YourUsername/AquaGuard-IoT)
>>>>>>> 9e51a1b58b8d37fc5ffa99059e0a8857d65dad03
