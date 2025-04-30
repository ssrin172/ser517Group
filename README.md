# SENSAI - USER PRIVACY APPLICATION

## About the Application

SENSAI is a cutting-edge application designed to enhance user privacy by leveraging ultra-wideband technology for precise real-time location tracking. The application provides users with detailed information about sensors present within their confined range, alerts them about potential tracking risks, and offers mitigation techniques to avoid being tracked. By utilizing Qorvo's DWM3001 CDK beacons, SENSAI ensures secure and accurate positioning, enabling users to maintain control over their location data. This innovative approach sets a new standard in the privacy domain, combining advanced technology with user-centric design to deliver a seamless and secure experience.

## Running the Application

## Requirements for Running the Application

To successfully run the application, ensure the following prerequisites are met:

1. **Ultra-Wideband Beacons**  
    The application requires 2 Qorvo ultra-wideband beacons (DWM3001 CDK) to function properly. These beacons are essential for providing the user's real-time live location.

2. **Beacon Setup**  
    - If the beacons are being used for the first time, they must be flashed with the appropriate firmware. Refer to the [Qorvo DWM3001C Starter Firmware](https://github.com/Uberi/DWM3001C-starter-firmware/blob/main/Src/main.c) for detailed flashing instructions.
    - Once flashed, the beacons should be placed 7 meters apart. The recommended coordinates for placement are:
      - Beacon 1: `(0, 0)`
      - Beacon 2: `(0, 7)`
    - If you wish to tweak the beacon coordinates, you can modify them in the `QorvoBeaconManager` file located in the `ios/Runner/QorvoBeaconManager.swift` folder.

3. **Device Compatibility**  
    The beacons should be connected to iPhones, which will serve as the interface for obtaining the user's live location data.

By following these steps, you can ensure the application runs smoothly and provides accurate location tracking.

## Steps to Run the Flutter Application

1. **Clone the Repository**  
    ```bash
    git clone <repository-url>
    cd <repository-folder>
    ```

2. **Install Flutter Dependencies**  
    Ensure you have Flutter installed and run:
    ```bash
    flutter pub get
    ```

3. **Run the Application**  
    To run the application on a connected device or emulator, use:
    ```bash
    flutter run
    ```

Replace `<repository-url>` and `<repository-folder>` with the actual repository details.

## Prerequisites

- Flutter SDK (version X.X.X or higher)
- A connected device or emulator

## Additional Notes

- Ensure your Flutter environment is properly set up.
- Refer to the Flutter documentation for advanced configurations.
- The backend is already hosted, so no additional setup is required for it.
- For any modifications to beacon coordinates, refer to the `QorvoBeaconManager` file in the `ios/Runner` folder.
