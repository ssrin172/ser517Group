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
    let beaconPositions: [Int: (Float, Float)] = [
        112456485: (0.0, 0.0),   // Example beacon 1 position
        143285168: (2.5, 0.0)      // Example beacon 2 position
    ]

    // MARK: - Initialization
    override init() {
        super.init()
        // Set up callbacks from the Bluetooth manager.
        bluetoothManager.accessoryDataHandler = { [weak self] data, accessoryName, deviceID in
            self?.accessorySharedData(data: data, accessoryName: accessoryName, deviceID: deviceID)
        }
        bluetoothManager.accessorySynchHandler = { [weak self] index, insert in
            // No logging needed here.
        }
        bluetoothManager.accessoryConnectedHandler = { [weak self] deviceID in
            self?.accessoryConnected(deviceID: deviceID)
        }
        bluetoothManager.accessoryDisconnectedHandler = { [weak self] deviceID in
            self?.accessoryDisconnected(deviceID: deviceID)
        }
    }
    
    // MARK: - Public Methods for Scanning
    func startScanning() {
        bluetoothManager.start()
    }
    
    func stopScanning() {
        for deviceID in referenceDict.keys {
            disconnectFromAccessory(deviceID: deviceID)
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
    
    // New helper that logs all device distances as an array-style string.
    private func logAllDeviceDistances() {
        let distancesString = deviceDistances.map { key, distance in
            "device \(key): \(String(format: "%.2f", distance)) meters"
        }
        let output = "{ " + distancesString.joined(separator: ", ") + " }"
        os_log("Distances update: %@", log: OSLog.default, type: .info, output)
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
        guard let accessory = nearbyObjects.first,
              let distance = accessory.distance else { return }
        let deviceID = deviceIDFromSession(session)
        deviceDistances[deviceID] = distance
        
        // Log all devices distances in one combined array-style format.
        logAllDeviceDistances()
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
            if let session = referenceDict[deviceID] {
                session.invalidate()
                referenceDict[deviceID] = NISession()
                referenceDict[deviceID]?.delegate = self
                sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
            }
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
