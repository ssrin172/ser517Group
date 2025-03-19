# UWB Privacy App

## Overview

UWB Privacy App is a Flutter-based application that utilizes **Ultra-Wideband (UWB)** technology for secure and private proximity detection. It integrates **CoreBluetooth** and **NearbyInteraction** frameworks to interact with Qorvo DWM3001CDK beacons and determine relative positions.

## Features

- **Real-time Distance Measurement** from multiple UWB beacons
- **Native iOS Integration** using CoreBluetooth & NearbyInteraction
- **Privacy-Focused Scanning** for secure communication
- **Flutter Support** for cross-platform development

## Setup & Installation

### **1. Clone the Repository**

```bash
    git clone <your-repo-url>
    cd uwbprivacyapp
```

### **2. Install Dependencies**

Run the following command to fetch necessary Flutter packages:

```bash
    flutter pub get
```

### **3. Clean & Build the iOS App**

```bash
    flutter clean
    flutter build ios
```

### **4. Run the Application**

```bash
    flutter run
```

This will launch the app on a connected iOS device or simulator.

## Troubleshooting

If you encounter build issues, try:

```bash
    cd ios
    pod install --repo-update
    cd ..
```

Then rebuild and run the app.
