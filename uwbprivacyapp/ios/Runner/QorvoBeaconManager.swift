import Foundation
import UIKit
import NearbyInteraction
import os.log

// MARK: - MessageId Enum
enum MessageId: UInt8 {
    // Messages from the accessory.
    case accessoryConfigurationData = 0x1
    case accessoryUwbDidStart      = 0x2
    case accessoryUwbDidStop       = 0x3

    // Messages to the accessory.
    case initialize              = 0xA
    case configureAndStart       = 0xB
    case stop                    = 0xC

    // User defined/notification messages
    case getReserved             = 0x20
    case setReserved             = 0x21
    case iOSNotify               = 0x2F
}

// MARK: - QorvoBeaconManager Class
/// This class encapsulates all beacon and UWB connection logic for Qorvo devices.
class QorvoBeaconManager: NSObject {

    // MARK: - Properties
    private let logger = OSLog(subsystem: "com.qorvo.uwb", category: "QorvoBeaconManager")

    /// The bluetooth manager handling BLE communications for our beacons.
    var bluetoothManager = QorvoBluetoothManager()

    /// The configuration generated from accessory data.
    var configuration: NINearbyAccessoryConfiguration?

    /// Currently selected accessory device ID.
    var selectedAccessory: Int = -1

    /// Mapping of device IDs to NI sessions.
    var referenceDict: [Int: NISession] = [:]

    /// Holds distance values received from accessories.
    var deviceDistances: [Int: Float] = [:]

    /// Fixed beacon positions used for coordinate calculations.
    /// We'll assume device 112456485 is at (0.0, 0.0),
    /// and device 143285168 is at (2.5, 0.0).
    let beaconPositions: [Int: (Float, Float)] = [
        112456485: (0.0, 0.0),  // Beacon A
        143285168: (2.5, 0.0)   // Beacon B
    ]
    
    /// Timer used to throttle communications/logging to 1-second intervals.
    var communicationTimer: Timer?
    
    /// Tracks the last time each device reported a distance update.
    var lastUpdateTimes: [Int: Date] = [:]

    // MARK: - Initialization
    override init() {
        super.init()
        // Set up callbacks from the Bluetooth manager.
        bluetoothManager.accessoryDataHandler = { [weak self] data, accessoryName, deviceID in
            self?.accessorySharedData(data: data, accessoryName: accessoryName, deviceID: deviceID)
        }
        bluetoothManager.accessorySynchHandler = { [weak self] _, _ in
            // No logging needed here.
        }
        bluetoothManager.accessoryConnectedHandler = { [weak self] deviceID in
            self?.accessoryConnected(deviceID: deviceID)
        }
        bluetoothManager.accessoryDisconnectedHandler = { [weak self] deviceID in
            self?.accessoryDisconnected(deviceID: deviceID)
        }
    }
    
    deinit {
        communicationTimer?.invalidate()
    }
    
    // MARK: - Public Methods for Scanning
    func startScanning() {
        bluetoothManager.start()
        // Schedule a timer to communicate with the beacon (and log) every 0.2 second.
        DispatchQueue.main.async {
            self.communicationTimer = Timer.scheduledTimer(timeInterval: 0.2,
                                                           target: self,
                                                           selector: #selector(self.communicationTimerFired),
                                                           userInfo: nil,
                                                           repeats: true)
        }
    }
    
    func stopScanning() {
        // Invalidate the communication timer.
        communicationTimer?.invalidate()
        communicationTimer = nil

        for deviceID in referenceDict.keys {
            disconnectFromAccessory(deviceID: deviceID)
        }
    }
    
    // MARK: - Timer Callback for Periodic Communication and Conditional Logging
    @objc func communicationTimerFired() {
        // 1) For each active accessory session, send a small "notify" command (optional).
        for deviceID in referenceDict.keys {
            let msg = Data([MessageId.iOSNotify.rawValue])
            sendDataToAccessory(data: msg, deviceID: deviceID)
        }
        
        // 2) Only log if BOTH known devices (112456485 and 143285168) have updated in the last second.
        let deviceA = 112456485
        let deviceB = 143285168
        guard deviceDistances.keys.contains(deviceA),
              deviceDistances.keys.contains(deviceB) else {
            // We only log if both devices exist in deviceDistances.
            return
        }
        
        // Check last update times for both devices.
        let now = Date()
        
        guard let timeA = lastUpdateTimes[deviceA],
              let timeB = lastUpdateTimes[deviceB] else {
            return
        }
        
        let updatedRecentlyA = now.timeIntervalSince(timeA) < 1.0
        let updatedRecentlyB = now.timeIntervalSince(timeB) < 1.0
        if updatedRecentlyA && updatedRecentlyB {
            // If both have new data within the last second, log them together, plus the coordinates.
            logBothDeviceDistancesAndCoordinates()
        }
    }
    
    // MARK: - Data Handlers
    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        guard data.count >= 1,
              let messageId = MessageId(rawValue: data.first!) else {
            return
        }
        
        switch messageId {
        case .accessoryConfigurationData:
            let message = data.advanced(by: 1)
            setupAccessory(configData: message, name: accessoryName, deviceID: deviceID)
        case .accessoryUwbDidStart:
            // No additional logging.
            break
        case .accessoryUwbDidStop:
            disconnectFromAccessory(deviceID: deviceID)
        default:
            break
        }
    }
    
    func accessoryConnected(deviceID: Int) {
        if selectedAccessory == -1 {
            selectedAccessory = deviceID
        }
        // Create and store a new NI session.
        let session = NISession()
        session.delegate = self
        referenceDict[deviceID] = session
        
        // Send initialization command to the accessory.
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(data: msg, deviceID: deviceID)
    }
    
    func accessoryDisconnected(deviceID: Int) {
        if let session = referenceDict[deviceID] {
            session.invalidate()
            referenceDict.removeValue(forKey: deviceID)
        }
        if selectedAccessory == deviceID {
            selectedAccessory = -1
        }
    }
    
    func setupAccessory(configData: Data, name: String, deviceID: Int) {
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            configuration?.isCameraAssistanceEnabled = true
        } catch {
            return
        }
        if let config = configuration, let session = referenceDict[deviceID] {
            session.run(config)
        }
    }
    
    // MARK: - Communication Methods
    func sendDataToAccessory(data: Data, deviceID: Int) {
        do {
            try bluetoothManager.sendData(data, deviceID)
        } catch {
            // Error handling if needed.
        }
    }
    
    func disconnectFromAccessory(deviceID: Int) {
        do {
            try bluetoothManager.disconnectPeripheral(deviceID)
        } catch {
            // Error handling if needed.
        }
    }
    
    // MARK: - Logging Helpers
    
    /// Logs both beacon distances AND the user coordinates based on those distances.
    private func logBothDeviceDistancesAndCoordinates() {
        let deviceA = 112456485
        let deviceB = 143285168
        
        guard let distA = deviceDistances[deviceA],
              let distB = deviceDistances[deviceB] else {
            return
        }
        
        // Calculate (x, y) using the two distances.
        let (coordX, coordY) = calculateUserCoordinates(distA: distA, distB: distB)
        
        // Log everything in a single line.
        let distanceString = String(format: "{ device %d: %.2f m, device %d: %.2f m }",
                                    deviceA, distA, deviceB, distB)
        let coordsString = String(format: "(x: %.2f, y: %.2f)", coordX, coordY)
        os_log("Distances: %@ -> Coordinates: %@", log: .default, type: .info, distanceString, coordsString)
    }
    
    /// Given distances from beaconA and beaconB, compute the user's (x,y).
    /// Basic 2-beacon trilateration assuming a linear arrangement (beaconB is 2.5m to the right of beaconA).
    private func calculateUserCoordinates(distA: Float, distB: Float) -> (Float, Float) {
        let deviceA = 112456485
        let deviceB = 143285168
        
        guard let beaconA = beaconPositions[deviceA],
              let beaconB = beaconPositions[deviceB] else {
            // If we have no known positions, just return (0,0).
            return (0,0)
        }
        
        let (x1, y1) = beaconA
        let (x2, y2) = beaconB
        
        // Convert distances to squared for reuse.
        let distA2 = distA * distA
        let distB2 = distB * distB
        
        // Standard 2-beacon trilateration math
        // A = 2 * (x2 - x1)
        let A = 2 * (x2 - x1)
        // C = distA^2 - distB^2 - x1^2 + x2^2 - y1^2 + y2^2
        let C = distA2 - distB2 - (x1*x1) + (x2*x2) - (y1*y1) + (y2*y2)
        
        // x = C / A
        let x = C / A
        
        // yTerm = distA^2 - (x - x1)^2
        let yTerm = distA2 - (x - x1)*(x - x1)
        
        // If yTerm is negative, that suggests the distances don't form a real intersection; clamp at 0.
        let y = (yTerm > 0) ? sqrt(yTerm) : 0
        
        return (x, y)
    }
}

// MARK: - NISessionDelegate Conformance
extension QorvoBeaconManager: NISessionDelegate {
    
    func session(_ session: NISession,
                 didGenerateShareableConfigurationData shareableConfigurationData: Data,
                 for object: NINearbyObject) {
        guard let config = configuration,
              object.discoveryToken == config.accessoryDiscoveryToken else { return }
        var msg = Data([MessageId.configureAndStart.rawValue])
        msg.append(shareableConfigurationData)
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: msg, deviceID: deviceID)
    }
    
    func session(_ session: NISession,
                 didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence,
                 for object: NINearbyObject?) {
        // No log here.
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        // Update distance values from the first nearby object.
        guard let accessory = nearbyObjects.first,
              let distance = accessory.distance else { return }
        
        let deviceID = deviceIDFromSession(session)
        // Store the new distance
        deviceDistances[deviceID] = distance
        
        // Record the last time we updated this device
        lastUpdateTimes[deviceID] = Date()
        
        // No direct logging here; rely on the timer-based approach in communicationTimerFired().
    }
    
    func session(_ session: NISession,
                 didRemove nearbyObjects: [NINearbyObject],
                 reason: NINearbyObject.RemovalReason) {
        guard reason == .timeout else { return }
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
        sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
    }
    
    func sessionWasSuspended(_ session: NISession) {
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        let deviceID = deviceIDFromSession(session)
        switch error {
        case NIError.invalidConfiguration, NIError.userDidNotAllow:
            break
        default:
            sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
            if let oldSession = referenceDict[deviceID] {
                oldSession.invalidate()
                referenceDict.removeValue(forKey: deviceID)
            }
            let newSession = NISession()
            newSession.delegate = self
            referenceDict[deviceID] = newSession
            sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
        }
    }
    
    // Helper: Get device ID from an NI session.
    func deviceIDFromSession(_ session: NISession) -> Int {
        for (key, value) in referenceDict where value == session {
            return key
        }
        return -1
    }
}

// MARK: - Utility Functions
func azimuth(_ direction: simd_float3) -> Float {
    return atan2(direction.x, direction.z)
}

func rad2deg(_ number: Double) -> Double {
    return number * 180 / .pi
}
