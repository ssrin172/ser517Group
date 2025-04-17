# 👁️‍🗨️ SENSAI - Privacy Application

> **"Know who's watching."**  
A mobile app that empowers users with **transparency** and **control** over the **sensor devices** tracking them in any room using UWB beacon detection.

---

## 🧠 About the Project

**SENSAI** is a privacy-awareness application that connects your smartphone to **UWB beacons** present in a room. Once connected, it fetches all **sensor devices** linked to those beacons and displays:
- 📍 The **types** of sensors (e.g., Cameras, Microphones, Motion Detectors)
- 📊 The **data being captured**
- 🔐 **Mitigation strategies** to avoid being tracked

This ensures that users are always aware of what devices are collecting data around them.

---

## 🚀 Getting Started

### 🔄 Reset Build State
Clean up any previous build files or cached states:

```bash
flutter clean
```

## 📦 Install Flutter Dependencies
```
flutter pub get
```

## 🍎 Install CocoaPods (for iOS)
```
cd ios
pod install
cd ..
```

## ▶️ Run the Flutter App
```
flutter run
```

## 🛠️ Features
- 🔎 Detects Sensors: Automatically identifies all sensor devices in a room.

- 🛰️ Beacon Connection: Utilizes UWB beacons to determine your location.

- 👁️ Real-Time Awareness: Lists what kind of data (Audio, Video, Motion) is being collected.

- 🧯 Mitigation Tips: Suggests ways to avoid sensor tracking.
