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
/// It uses your real data communication channel and Nearby Interaction configurations
/// to connect and exchange data with your Qorvo beacons.
class QorvoBeaconManager: NSObject {

    // MARK: - Properties
    private let logger = OSLog(subsystem: "com.qorvo.uwb", category: "QorvoBeaconManager")

    /// The data channel handling low-level communication with the accessories.
    var dataChannel = DataCommunicationChannel()

    /// The configuration generated from accessory data.
    var configuration: NINearbyAccessoryConfiguration?

    /// Currently selected accessory device ID.
    var selectedAccessory: Int = -1

    /// Flag indicating algorithm convergence.
    var isConverged: Bool = false

    /// Mapping of device IDs to NI sessions.
    var referenceDict: [Int: NISession] = [:]

    /// Mapping from discovery token to accessory names.
    var accessoryMap: [NIDiscoveryToken: String] = [:]

    /// Holds distance values received from accessories.
    var deviceDistances: [Int: Float] = [:]

    /// Fixed beacon positions used for coordinate calculations.
    let beaconPositions: [Int: (Float, Float)] = [
        112456485: (0.0, 0.0),   // For example: beacon 1 position
        143285168: (2.5, 0.0)      // For example: beacon 2 position
    ]

    // MARK: - Initialization
    override init() {
        super.init()
        // Set up callbacks on the data channel (ensure these point to your real implementation).
        dataChannel.accessoryDataHandler = { [weak self] data, accessoryName, deviceID in
            self?.accessorySharedData(data: data, accessoryName: accessoryName, deviceID: deviceID)
        }
        dataChannel.accessorySynchHandler = { [weak self] index, insert in
            self?.accessorySynch(index: index, insert: insert)
        }
        dataChannel.accessoryConnectedHandler = { [weak self] deviceID in
            self?.accessoryConnected(deviceID: deviceID)
        }
        dataChannel.accessoryDisconnectedHandler = { [weak self] deviceID in
            self?.accessoryDisconnected(deviceID: deviceID)
        }
        // Note: The channel is started in startScanning().
    }
    
    // MARK: - Public Methods for Scanning
    func startScanning() {
        os_log("startScanning called in QorvoBeaconManager.", log: logger, type: .info)
        // Start the real data channel which begins scanning for beacons.
        dataChannel.start()
    }
    
    func stopScanning() {
        os_log("stopScanning called in QorvoBeaconManager.", log: logger, type: .info)
        // Disconnect from all accessories.
        for deviceID in referenceDict.keys {
            disconnectFromAccessory(deviceID: deviceID)
        }
        // If supported by your data channel, stop it here.
        // e.g., dataChannel.stop()
    }
    
    // MARK: - Data Channel Handlers
    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        if data.count < 1 {
            os_log("Received empty data from accessory.", log: logger, type: .error)
            return
        }
        guard let messageId = MessageId(rawValue: data.first!) else {
            fatalError("\(data.first!) is not a valid MessageId.")
        }
        
        // Process the received message from the accessory.
        switch messageId {
        case .accessoryConfigurationData:
            let message = data.advanced(by: 1)
            setupAccessory(configData: message, name: accessoryName, deviceID: deviceID)
        case .accessoryUwbDidStart:
            handleAccessoryUwbDidStart(deviceID: deviceID)
        case .accessoryUwbDidStop:
            handleAccessoryUwbDidStop(deviceID: deviceID)
        case .configureAndStart, .initialize, .stop:
            os_log("Unexpected message (%{public}d) received from accessory.", log: logger, type: .error, messageId.rawValue)
        case .getReserved:
            os_log("getReserved not implemented.", log: logger, type: .debug)
        case .setReserved:
            os_log("setReserved not implemented.", log: logger, type: .debug)
        case .iOSNotify:
            os_log("iOSNotify not implemented.", log: logger, type: .debug)
        }
    }
    
    func accessorySynch(index: Int, insert: Bool) {
        os_log("Accessory synch: index = %d, insert = %{public}@", log: logger, type: .info, index, String(describing: insert))
    }
    
    func accessoryConnected(deviceID: Int) {
        if selectedAccessory == -1 {
            selectedAccessory = deviceID
            os_log("Selected device set to %d.", log: logger, type: .info, deviceID)
        }
        // Create a new NI session and register it.
        let session = NISession()
        session.delegate = self
        referenceDict[deviceID] = session
        os_log("Device %d connected; NI Session created.", log: logger, type: .info, deviceID)
        
        // Send the real initialization command to the accessory.
        let msg = Data([MessageId.initialize.rawValue])
        sendDataToAccessory(data: msg, deviceID: deviceID)
    }
    
    func accessoryDisconnected(deviceID: Int) {
        if let session = referenceDict[deviceID] {
            session.invalidate()
            referenceDict.removeValue(forKey: deviceID)
            os_log("Device %d disconnected; NI Session invalidated.", log: logger, type: .info, deviceID)
        }
        if selectedAccessory == deviceID {
            selectedAccessory = -1
        }
    }
    
    func setupAccessory(configData: Data, name: String, deviceID: Int) {
        os_log("Received configuration data from '%{public}@' for device %d.", log: logger, type: .info, name, deviceID)
        do {
            configuration = try NINearbyAccessoryConfiguration(data: configData)
            configuration?.isCameraAssistanceEnabled = true
        } catch {
            os_log("Failed to create configuration for '%{public}@': %{public}@", log: logger, type: .error, name, "\(error)")
            return
        }
        
        if let config = configuration {
            accessoryMap[config.accessoryDiscoveryToken] = name
            if let session = referenceDict[deviceID] {
                session.run(config)
                os_log("NI Session run for device %d.", log: logger, type: .info, deviceID)
            }
        }
    }
    
    func handleAccessoryUwbDidStart(deviceID: Int) {
        os_log("Accessory UWB did start for device %d.", log: logger, type: .info, deviceID)
        // Here you can add any additional logic once the accessory’s UWB is active.
    }
    
    func handleAccessoryUwbDidStop(deviceID: Int) {
        os_log("Accessory UWB did stop for device %d.", log: logger, type: .info, deviceID)
        disconnectFromAccessory(deviceID: deviceID)
    }
    
    // MARK: - Communication Methods
    func sendDataToAccessory(data: Data, deviceID: Int) {
        do {
            try dataChannel.sendData(data, deviceID)
            os_log("Data sent to device %d.", log: logger, type: .info, deviceID)
        } catch {
            os_log("Failed to send data to device %d: %{public}@", log: logger, type: .error, deviceID, "\(error)")
        }
    }
    
    func disconnectFromAccessory(deviceID: Int) {
        do {
            try dataChannel.disconnectPeripheral(deviceID)
            os_log("Disconnected from device %d.", log: logger, type: .info, deviceID)
        } catch {
            os_log("Failed to disconnect from device %d: %{public}@", log: logger, type: .error, deviceID, "\(error)")
        }
    }
    
    // MARK: - Coordinate Calculation
    func calculateUserCoordinates() {
        guard deviceDistances.count == 2 else {
            os_log("Not enough data to calculate coordinates.", log: logger, type: .error)
            return
        }
        
        let deviceIDs = Array(deviceDistances.keys)
        guard let distance1 = deviceDistances[deviceIDs[0]],
              let distance2 = deviceDistances[deviceIDs[1]] else {
            os_log("Error: Missing distance data.", log: logger, type: .error)
            return
        }
        
        guard let beacon1 = beaconPositions[deviceIDs[0]],
              let beacon2 = beaconPositions[deviceIDs[1]] else {
            os_log("Error: Missing beacon positions.", log: logger, type: .error)
            return
        }
        
        let (x1, y1) = beacon1
        let (x2, y2) = beacon2
        let A = 2 * (x2 - x1)
        let C = (distance1 * distance1) - (distance2 * distance2) - (x1 * x1) + (x2 * x2) - (y1 * y1) + (y2 * y2)
        let x = C / A
        let yTerm = (distance1 * distance1) - (x - x1) * (x - x1)
        let y = max(0, yTerm).squareRoot()
        
        os_log("Calculated User Coordinates: (%.2f, %.2f)", log: logger, type: .info, x, y)
    }
    
    // Helper: Get device ID from an NI Session.
    func deviceIDFromSession(_ session: NISession) -> Int {
        for (key, value) in referenceDict where value == session {
            return key
        }
        return -1
    }
    
    // Helper: Cache accessory discovery token.
    func cacheToken(_ token: NIDiscoveryToken, accessoryName: String) {
        accessoryMap[token] = accessoryName
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
        os_log("Sending shareable configuration data for device %d.", log: logger, type: .info, deviceID)
        sendDataToAccessory(data: msg, deviceID: deviceID)
    }
    
    func session(_ session: NISession,
                 didUpdateAlgorithmConvergence convergence: NIAlgorithmConvergence,
                 for object: NINearbyObject?) {
        os_log("Convergence status: %{public}@", log: logger, type: .info, "\(convergence.status)")
        switch convergence.status {
        case .converged:
            os_log("Device converged.", log: logger, type: .info)
            isConverged = true
        case .notConverged(let reasons) where reasons.contains(.insufficientLighting):
            os_log("Insufficient lighting for convergence.", log: logger, type: .info)
            isConverged = false
        default:
            os_log("Movement needed for convergence.", log: logger, type: .info)
        }
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first, let distance = accessory.distance else { return }
        let deviceID = deviceIDFromSession(session)
        deviceDistances[deviceID] = distance
        os_log("Updated device %d distance: %.2f meters.", log: logger, type: .info, deviceID, distance)
        
        if deviceDistances.count == 2 {
            calculateUserCoordinates()
        }
        
        if let direction = accessory.direction {
            // Log computed directional (azimuth) data.
            let azimuthValue = Settings().isDirectionEnable ?
                Int(90 * Double(azimuth(direction))) : Int(rad2deg(Double(azimuth(direction))))
            os_log("Device %d updated with direction (azimuth): %d", log: logger, type: .info, deviceID, azimuthValue)
        }
    }
    
    func session(_ session: NISession,
                 didRemove nearbyObjects: [NINearbyObject],
                 reason: NINearbyObject.RemovalReason) {
        guard reason == .timeout else { return }
        os_log("Accessory session timed out.", log: logger, type: .info)
        let deviceID = deviceIDFromSession(session)
        if shouldRetry(deviceID: deviceID) {
            sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
            sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
        }
    }
    
    func sessionWasSuspended(_ session: NISession) {
        os_log("NI Session was suspended.", log: logger, type: .info)
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
    }
    
    func sessionSuspensionEnded(_ session: NISession) {
        os_log("NI Session suspension ended.", log: logger, type: .info)
        let deviceID = deviceIDFromSession(session)
        sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
    }
    
    func session(_ session: NISession, didInvalidateWith error: Error) {
        let deviceID = deviceIDFromSession(session)
        switch error {
        case NIError.invalidConfiguration:
            os_log("Invalid configuration for device %d.", log: logger, type: .error, deviceID)
        case NIError.userDidNotAllow:
            os_log("User did not allow required permissions.", log: logger, type: .error)
        default:
            os_log("NI Session invalidated for device %d with error: %{public}@.", log: logger, type: .error, deviceID, "\(error)")
            sendDataToAccessory(data: Data([MessageId.stop.rawValue]), deviceID: deviceID)
            if let session = referenceDict[deviceID] {
                session.invalidate()
                referenceDict[deviceID] = NISession()
                referenceDict[deviceID]?.delegate = self
                sendDataToAccessory(data: Data([MessageId.initialize.rawValue]), deviceID: deviceID)
            }
        }
    }
    
    func shouldRetry(deviceID: Int) -> Bool {
        // In your full implementation, you would check the accessory’s state.
        return true
    }
}

// MARK: - Utility Functions

func azimuth(_ direction: simd_float3) -> Float {
    if Settings().isDirectionEnable {
        return asin(direction.x)
    } else {
        return atan2(direction.x, direction.z)
    }
}

func elevation(_ direction: simd_float3) -> Float {
    return atan2(direction.z, direction.y) + .pi / 2
}

func rad2deg(_ number: Double) -> Double {
    return number * 180 / .pi
}

func getDirectionFromHorizontalAngle(rad: Float) -> simd_float3 {
    os_log("Horizontal Angle in deg = %{public}.2f", rad2deg(Double(rad)))
    return simd_float3(x: sin(rad), y: 0, z: cos(rad))
}
