Below is a shorter, step-by-step explanation of what happens, followed by one diagram that summarizes all the steps:

App Launch:

The app starts using a generated main function (triggered by @UIApplicationMain).

iOS creates an instance of your AppDelegate and calls its application(\_:didFinishLaunchingWithOptions:) method to set everything up.

UI Loading:

The storyboard is read. This file tells iOS how to build the visual parts of your app.

A Navigation Controller is set up, which manages different screens.

The Qorvo Demo View Controller loads as the first screen, showing UI elements like the header (logo, settings, SwitchAR button) and the main content.

Tapping the Settings button triggers a segue to the Settings View Controller.

NI Session and Beacon Detection:

The app starts a Nearby Interaction (NI) session, which acts like a “magic radar” that listens for beacon signals.

When a beacon comes nearby, this NI session detects it.

Delegate methods are triggered to process the beacon data (like distance and direction).

The app updates the UI accordingly (for example, moving an arrow or updating labels).

```
[App Launched]
│
▼
[AppDelegate Initialized & didFinishLaunchingWithOptions Called]
│
▼
[Storyboard Loads Navigation Controller]
│
▼
[Qorvo Demo View Controller Displays UI]
│
▼
[User Interaction & NI Session Started (Magic Radar ON)]
│
▼
[Beacon Detected via NI Session]
│
▼
[Delegate Callback Processes Data]
│
▼
[UI Updated with Beacon Info]
```

QorvoDemoViewController.swift

```
           [ QorvoDemoViewController.swift ]
                         │
         ┌───────────────┴───────────────┐
         │        Import Statements      │
         │  (UIKit, NearbyInteraction, os.log)  │
         └───────────────┬───────────────┘
                         │
                         ▼
                   [ MessageId Enum ]
                         │
           ┌────────────┴────────────┐
           │                         │
[Accessory → App Messages]  [App → Accessory Messages]
           │                         │
   ┌───── accessoryConfigurationData = 0x1    ──────┐
   │         accessoryUwbDidStart    = 0x2         │
   │         accessoryUwbDidStop     = 0x3         │
           │                         │
           └────────────┬────────────┘
                         │
                ┌────────┴────────┐
                │  Messages for   │
                │  UI/Notifications  │
                │  getReserved  = 0x20  │
                │  setReserved  = 0x21  │
                │  iOSNotify    = 0x2F  │
                └────────┬────────┘
                         │
           [ App → Accessory Messages ]
                         │
           ┌────────────┴────────────┐
           │   initialize = 0xA      │
           │  configureAndStart = 0xB │
           │         stop = 0xC       │
           └─────────────────────────┘
                         │
                         ▼
             [ Communication Protocol ]
                         │
         ┌───────────────┴───────────────┐
         │       Protocols Defined       │
         ├───────────────────────────────┤
         │ ArrowProtocol:                │
         │    └── switch3DArrow()        │
         │                               │
         │ TableProtocol:                │
         │    ├── buttonSelect(sender)   │
         │    ├── buttonAction(sender)   │
         │    └── sendStopToDevice(id)   │
         └───────────────────────────────┘
```

---

# Qorvo Real-Time Beacon Communication

This document provides a complete explanation of how the Qorvo demo app obtains real-time data from beacons. It covers the communication protocol, beacon discovery, data exchange, session management, and detailed code examples. This is a comprehensive guide that includes everything discussed.

---

## Table of Contents

1. [Overview](#overview)
2. [Communication Protocol: MessageId Enum](#communication-protocol-messsageid-enum)
3. [Data Channel Setup & Beacon Discovery](#data-channel-setup--beacon-discovery)
4. [Sending Data to the Accessory](#sending-data-to-the-accessory)
5. [Receiving Data from the Accessory](#receiving-data-from-the-accessory)
6. [Handler Functions and Session Management](#handler-functions-and-session-management)
7. [Summary of Steps](#summary-of-steps)
8. [Implementation Considerations](#implementation-considerations)

---

## Overview

The Qorvo demo app establishes a real-time connection with beacon accessories using a dedicated data communication channel. The app exchanges messages with the beacon using uniquely defined message IDs. When beacons are discovered, the app creates a Nearby Interaction (NI) session, receives configuration data, and gets ongoing ranging updates such as distance, direction, and elevation. The user interface then updates in real time to reflect the beacon’s state.

---

## Communication Protocol: MessageId Enum

A key component of the Qorvo system is the `MessageId` enum. This enum defines unique IDs (in hexadecimal) to differentiate various types of messages exchanged between the beacon (accessory) and the app.

### MessageId Definition

```swift
enum MessageId: UInt8 {
    // Messages from the accessory (Beacon → App):
    case accessoryConfigurationData = 0x1  // Beacon sends configuration information.
    case accessoryUwbDidStart        = 0x2  // Beacon indicates UWB (Ultra-Wideband) ranging has started.
    case accessoryUwbDidStop         = 0x3  // Beacon indicates UWB ranging has stopped.

    // Messages to the accessory (App → Beacon):
    case initialize                = 0xA  // Commands the beacon to initialize and prepare for connection.
    case configureAndStart         = 0xB  // Commands the beacon to configure itself and start ranging.
    case stop                      = 0xC  // Commands the beacon to stop ranging.

    // User defined/notification messages:
    case getReserved               = 0x20 // Reserved for future or specific query operations.
    case setReserved               = 0x21 // Reserved for future settings or commands.
    case iOSNotify                 = 0x2F // Notifications from the app to the beacon.
}
Each message ID tells both sides what type of message is being exchanged:

Beacon → App: For example, configuration data (0x1) or UWB state changes (0x2, 0x3).

App → Beacon: For example, initialize (0xA) to start the connection, configureAndStart (0xB) to begin ranging, or stop (0xC) when ending the session.

Reserved/Notification: For any custom or user-specific notifications.

Data Channel Setup & Beacon Discovery
Data Communication Channel
The app uses a dedicated DataCommunicationChannel to send and receive messages. This channel is responsible for:

Registering Callbacks: Handlers such as accessoryDataHandler, accessoryConnectedHandler, accessoryDisconnectedHandler, and accessorySynchHandler are set so that when events occur, the appropriate functions are called.

Sending Data: Commands like initialize, configureAndStart, or stop are sent to the beacon.

Receiving Data: The channel receives messages from the beacon, including configuration or state updates.

Beacon Discovery Process
Beacon Discovery:

The device detects a beacon via BLE or another wireless protocol.

Connection Initialization:

The accessoryConnectedHandler is triggered when a beacon is detected.

Session Creation:

A Nearby Interaction (NI) session is created and stored in a reference dictionary (e.g., referenceDict[deviceID]).

Initialization Message:

The app sends an initialize command to the beacon to kickstart communication.

Sending Data to the Accessory
Steps to Send a Command
Convert the Message:

Convert a MessageId to a Data object. For example, the initialize command:

swift
Copy
let messageData = Data([MessageId.initialize.rawValue])
Use the Data Channel:

Send the data via your communication channel:

swift
Copy
func sendDataToAccessory(_ message: MessageId, deviceID: Int) {
    let messageData = Data([message.rawValue])
    dataChannel.send(messageData, toDevice: deviceID)
}
Trigger at Connection:

When a beacon connects, send the initialize message:

swift
Copy
func accessoryConnected(deviceID: Int) {
    // Additional NI session creation code goes here...

    // Send initialization command to the beacon
    sendDataToAccessory(.initialize, deviceID: deviceID)
}
Receiving Data from the Accessory
Setting Up a Data Handler
Data Handler Definition:

The app uses a function like accessorySharedData as a callback to process incoming messages.

Parse Incoming Data:

The first byte of the message is read as the MessageId.

swift
Copy
func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
    // Ensure data contains at least one byte.
    guard data.count >= 1 else {
        print("Received empty data")
        return
    }

    // Convert the first byte into a MessageId.
    guard let messageId = MessageId(rawValue: data.first!) else {
        fatalError("Invalid MessageId: \(data.first!)")
    }

    // Process the message based on its type.
    switch messageId {
    case .accessoryConfigurationData:
        // Process configuration data (skip first byte)
        let configData = data.advanced(by: 1)
        setupAccessory(with: configData, name: accessoryName, deviceID: deviceID)

    case .accessoryUwbDidStart:
        handleAccessoryUwbDidStart(deviceID: deviceID)

    case .accessoryUwbDidStop:
        handleAccessoryUwbDidStop(deviceID: deviceID)

    // These messages are not expected to be received from the beacon.
    case .configureAndStart, .initialize, .stop:
        fatalError("Accessory should not send \(messageId)")

    case .getReserved, .setReserved, .iOSNotify:
        print("Received a reserved/notification message: \(messageId)")
    }
}
Processing Messages:

Configuration Data (0x1):

Pass the remaining data to a handler (setupAccessory) to parse and apply configuration.

UWB Start (0x2):

Update your app's state to indicate the beacon is now ranging.

UWB Stop (0x3):

Handle stopping the session and clean up.

Handler Functions and Session Management
Configuration Handler
When configuration data is received, this function parses the data and starts an NI session:

swift
Copy
func setupAccessory(with configData: Data, name: String, deviceID: Int) {
    print("Received configuration data from '\(name)' for device \(deviceID)")
    do {
        let configuration = try NINearbyAccessoryConfiguration(data: configData)
        configuration.isCameraAssistanceEnabled = true
        referenceDict[deviceID]?.run(configuration)
        print("Configuration applied; session running.")
    } catch {
        print("Configuration error: \(error)")
    }
}
UWB Session Handlers
These functions manage the transitions in the beacon’s ranging state:

swift
Copy
func handleAccessoryUwbDidStart(deviceID: Int) {
    print("Beacon UWB session started for device \(deviceID)")
    // Update internal state and UI as necessary, e.g., mark as ranging.
}

func handleAccessoryUwbDidStop(deviceID: Int) {
    print("Beacon UWB session stopped for device \(deviceID)")
    // Clean up the session, remove associated UI elements, and update state.
}
Summary of Steps
Define the MessageId Enum:

Create unique message IDs to distinguish between messages from the beacon (e.g., configuration data, UWB start/stop) and messages sent to the beacon (e.g., initialize, configureAndStart, stop).

Sending Commands to the Accessory:

Convert a MessageId to a Data object.

Use the data channel to send the message to the accessory (e.g., on beacon discovery, send .initialize).

Receiving and Processing Data:

Set up a data handler that reads the first byte of incoming data as a MessageId.

Process the message by invoking the appropriate function:

accessoryConfigurationData: Parse and run an NI session.

accessoryUwbDidStart/Stop: Update the session and UI based on beacon status.

Handler Functions:

Implement functions like setupAccessory, handleAccessoryUwbDidStart, and handleAccessoryUwbDidStop that manage the connection process and state changes.

Session Management:

Create and manage NI sessions for each connected beacon.

Clean up sessions and update the UI when beacons disconnect.

Implementation Considerations
Data Channel:
Ensure you have a robust implementation for sending and receiving raw data (for instance, using BLE).

Error Handling:
Validate incoming data and handle unexpected messages gracefully with proper error reporting and logging.

UI Updates:
Although the focus here is on communication and beacon discovery, make sure that your UI reflects real-time updates accurately.

Testing:
Use logging utilities (like os.Logger) to track communication flows and diagnose issues during development.

```

NISessionDelegate

```
                    ┌─────────────────────────────────────────┐
                    │ NISessionDelegate Extension             │
                    └─────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ didGenerateShareableConfigurationData      │
         │  • Match discovery token                     │
         │  • Append configuration data to message      │
         │  • Send "configureAndStart" message          │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ didUpdateAlgorithmConvergence              │
         │  • Check convergence status                │
         │      ├─ .converged → update flag, UI         │
         │      ├─ .notConverged (insufficient light) →  │
         │      │     update UI ("LightError")            │
         │      └─ Others → update UI ("MovementNeeded")   │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ didUpdate nearbyObjects                    │
         │  • Retrieve updated accessory info         │
         │      (distance, direction, AR anchor)        │
         │  • Save distance in deviceDistances         │
         │  • Call updateLocationFields & updateMiniFields│
         │  • If two devices available, call            │
         │    calculateUserCoordinates                  │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ calculateUserCoordinates                   │
         │  • Use distances from two beacons          │
         │  • Compute user's (x, y) coordinates       │
         │  • Print the coordinates                   │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ didRemove nearbyObjects                    │
         │  • Remove accessory on timeout             │
         │  • Update accessoryMap and UI               │
         │  • Optionally retry connection by sending    │
         │    "stop" then "initialize" messages         │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ sessionWasSuspended                        │
         │  • Update UI (SessionSuspended)            │
         │  • Send a "stop" message to the accessory    │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ sessionSuspensionEnded                     │
         │  • Update UI (SessionSuspendedEnded)       │
         │  • Send an "initialize" message to restart   │
         │    configuration                           │
         └────────────────────────────────────────────┘
                                   │
                                   ▼
         ┌────────────────────────────────────────────┐
         │ didInvalidateWith error                    │
         │  • Inspect error type                       │
         │      ├─ Invalid configuration, etc.         │
         │      ├─ User did not allow                   │
         │      └─ Other errors → update UI & handle      │
         │          session invalidation              │
         └────────────────────────────────────────────┘
```

Helpers

```
┌─────────────────────────────────────────────┐
│          QorvoDemoViewController Helpers      │
└─────────────────────────────────────────────┘
             │           │           │
             │           │           │
             ▼           ▼           ▼
┌─────────────────┐ ┌─────────────────┐ ┌──────────────────┐
│  connectToAccessory(deviceID)            │
│  ──────────────────────────────────────   │
│  - Attempts to connect using           │
│    dataChannel.connectPeripheral.      │
│  - On error, updates arrowView info.   │
└─────────────────┘ └─────────────────┘
             │                                │
             ▼                                ▼
┌─────────────────┐                   ┌─────────────────┐
│ disconnectFromAccessory(deviceID)       │
│  ─────────────────────────────────────   │
│  - Attempts to disconnect via          │
│    dataChannel.disconnectPeripheral.   │
│  - On error, updates arrowView info.     │
└─────────────────┘                   └─────────────────┘
             │                                │
             ▼                                ▼
      ┌─────────────────┐              ┌─────────────────┐
      │ sendDataToAccessory(data, deviceID) │
      │  ─────────────────────────────────   │
      │  - Sends data to accessory via     │
      │    dataChannel.sendData.           │
      │  - On error, updates arrowView info.│
      └─────────────────┘              └─────────────────┘
                       │
                       ▼
              ┌──────────────────────────┐
              │ handleSessionInvalidation(deviceID) │
              │  ───────────────────────────────────── │
              │  - Notifies user of invalid session   │
              │    via arrowView info update.          │
              │  - Sends “stop” and then “initialize”  │
              │    messages to the accessory.          │
              │  - Replaces the old NISession with a    │
              │    new one.                             │
              └──────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │   shouldRetry(deviceID) │
         │  ────────────────────── │
         │  - Checks device connection  │
         │    state (via dataChannel).  │
         │  - Returns a Boolean value   │
         │    indicating if a retry is    │
         │    needed.                     │
         └─────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │  deviceIDFromSession(session) │
         │  ────────────────────────── │
         │  - Loops through referenceDict   │
         │    to find the matching deviceID.  │
         │  - Returns the deviceID.           │
         └─────────────────────────┘
                       │
                       ▼
         ┌─────────────────────────┐
         │   cacheToken(token, accessoryName)  │
         │  ────────────────────────── │
         │  - Associates a discovery token    │
         │    with an accessory name by        │
         │    adding it to accessoryMap.       │
         └─────────────────────────┘
                       │
                       ▼
         ┌────────────────────────────┐
         │ handleUserDidNotAllow()    │
         │  ───────────────────────── │
         │  - Updates the UI to indicate     │
         │    that Nearby Interaction access │
         │    is required.                    │
         │  - Presents an alert, offering    │
         │    a direct link to the app’s      │
         │    Settings so the user can enable │
         │    access.                         │
         └────────────────────────────┘
```

Utils

       ┌────────────────────────────┐
       │         azimuth            │
       │  Input: simd_float3 "direction"    │
       │  ────────────────────────── │
       │  If direction enabled:       │
       │     return asin(direction.x) │
       │  Else:                       │
       │     return atan2(direction.x, │
       │                    direction.z) │
       └────────────────────────────┘
                  │
                  ▼
       ┌────────────────────────────┐
       │         elevation          │
       │  Input: simd_float3 "direction"    │
       │  ────────────────────────── │
       │  return atan2(direction.z,   │
       │                direction.y)  │
       │         + π/2               │
       └────────────────────────────┘
                  │
                  ▼
       ┌────────────────────────────┐
       │         rad2deg            │
       │  Input: Double (in radians)│
       │  ────────────────────────── │
       │  return (number * 180) / π   │
       └────────────────────────────┘
                  │
                  ▼
       ┌────────────────────────────┐
       │ getDirectionFromHorizontal │
       │         Angle              │
       │  Input: Float "rad"        │
       │  ────────────────────────── │
       │  Print horizontal angle in │
       │     degrees                │
       │  return simd_float3 with:  │
       │     x = sin(rad)           │
       │     y = 0                  │
       │     z = cos(rad)           │
       └────────────────────────────┘
                  │
                  ▼
       ┌────────────────────────────┐
       │     getElevationFromInt    │
       │  Input: Optional Int       │
       │  ────────────────────────── │
       │  Uses vertical direction   │
       │  value (from NINearbyObject) │
       │  to return localized       │
       │  string ("above", "below",  │
       │   "same", or "unknown")     │
       └────────────────────────────┘
                  │
                  ▼
       ┌────────────────────────────┐
       │   String Extension:        │
       │  localized & localizedUppercase │
       │  ────────────────────────── │
       │  Returns NSLocalizedString │
       │  version of the string       │
       │  (normal or uppercase)       │
       └────────────────────────────┘
