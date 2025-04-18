import Foundation
import UIKit
import NearbyInteraction
import os.log

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

class QorvoBeaconManager: NSObject {
    
    // MARK: - Singleton
    static let shared = QorvoBeaconManager()
    
    private override init() {
        super.init()
        // Set up callbacks from the Bluetooth manager.
        bluetoothManager.accessoryDataHandler = { [weak self] data, accessoryName, deviceID in
            self?.accessorySharedData(data: data, accessoryName: accessoryName, deviceID: deviceID)
        }
        bluetoothManager.accessorySynchHandler = { [weak self] _, _ in }
        bluetoothManager.accessoryConnectedHandler = { [weak self] deviceID in
            self?.accessoryConnected(deviceID: deviceID)
        }
        bluetoothManager.accessoryDisconnectedHandler = { [weak self] deviceID in
            self?.accessoryDisconnected(deviceID: deviceID)
        }
    }
    
    // MARK: - Properties
    let bluetoothManager = QorvoBluetoothManager()
    var configuration: NINearbyAccessoryConfiguration?
    var selectedAccessory: Int = -1
    var referenceDict: [Int: NISession] = [:]
    var deviceDistances: [Int: Float] = [:]
    var lastUpdateTimes: [Int: Date] = [:]
    
    // A computed property that returns connected QorvoDevices.
    var connectedDevices: [QorvoDevice] {
        // Filter the global device list (qorvoDevices) to return devices that have a nonzero distance.
        return qorvoDevices.filter { ($0.uwbLocation?.distance ?? 0) > 0 }
    }
    
    // Timer for periodic communication.
    var communicationTimer: Timer?
    
    // Fixed beacon positions used for coordinate calculations.
    let beaconPositions: [Int: (Float, Float)] = [
        112456485: (0.0, 0.0),
        143285168: (7.0, 0.0)
    ]
    
    // MARK: - Public Methods for Scanning
    func startScanning() {
        bluetoothManager.start()
        DispatchQueue.main.async {
            self.communicationTimer = Timer.scheduledTimer(timeInterval: 0.2,
                                                           target: self,
                                                           selector: #selector(self.communicationTimerFired),
                                                           userInfo: nil,
                                                           repeats: true)
        }
    }
    
    func stopScanning() {
        communicationTimer?.invalidate()
        communicationTimer = nil
        
        for deviceID in referenceDict.keys {
            disconnectFromAccessory(deviceID: deviceID)
        }
    }
    
    // MARK: - Timer Callback
    @objc func communicationTimerFired() {
        // For each active accessory session, send a notify message.
        for deviceID in referenceDict.keys {
            let msg = Data([MessageId.iOSNotify.rawValue])
            sendDataToAccessory(data: msg, deviceID: deviceID)
        }
        
        // Only log if both known devices have updated in the last second.
        let deviceA = 112456485
        let deviceB = 143285168
        guard deviceDistances.keys.contains(deviceA),
              deviceDistances.keys.contains(deviceB) else { return }
        
        let now = Date()
        guard let timeA = lastUpdateTimes[deviceA],
              let timeB = lastUpdateTimes[deviceB] else { return }
        let updatedRecentlyA = now.timeIntervalSince(timeA) < 1.0
        let updatedRecentlyB = now.timeIntervalSince(timeB) < 1.0
        if updatedRecentlyA && updatedRecentlyB {
            logBothDeviceDistancesAndCoordinates()
        }
    }
    
    // MARK: - Data Handlers
    func accessorySharedData(data: Data, accessoryName: String, deviceID: Int) {
        guard data.count >= 1,
              let messageId = MessageId(rawValue: data.first!) else { return }
        
        switch messageId {
        case .accessoryConfigurationData:
            let message = data.advanced(by: 1)
            setupAccessory(configData: message, name: accessoryName, deviceID: deviceID)
        case .accessoryUwbDidStart:
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
        let session = NISession()
        session.delegate = self
        referenceDict[deviceID] = session
        
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
    
    func sendDataToAccessory(data: Data, deviceID: Int) {
        do {
            try bluetoothManager.sendData(data, deviceID)
        } catch {
            // Handle error as necessary.
        }
    }
    
    func disconnectFromAccessory(deviceID: Int) {
        do {
            try bluetoothManager.disconnectPeripheral(deviceID)
        } catch {
            // Handle error if needed.
        }
    }
    
    // MARK: - Logging Helpers
    private func logBothDeviceDistancesAndCoordinates() {
        let deviceA = 112456485
        let deviceB = 143285168
        
        guard let distA = deviceDistances[deviceA],
              let distB = deviceDistances[deviceB] else { return }
        
        let (coordX, coordY) = calculateUserCoordinates(distA: distA, distB: distB)
        let distanceString = String(format: "{ device %d: %.2f m, device %d: %.2f m }",
                                    deviceA, distA, deviceB, distB)
        let coordsString = String(format: "(x: %.2f, y: %.2f)", coordX, coordY)
        os_log("Distances: %@ -> Coordinates: %@", log: .default, type: .info, distanceString, coordsString)
    }
    
    /// Basic 2-beacon trilateration using given distances.
    func calculateUserCoordinates(distA: Float, distB: Float) -> (Float, Float) {
        let deviceA = 112456485
        let deviceB = 143285168
        
        guard let beaconA = beaconPositions[deviceA],
              let beaconB = beaconPositions[deviceB] else {
            return (0,0)
        }
        
        let (x1, y1) = beaconA
        let (x2, y2) = beaconB
        
        let distA2 = distA * distA
        let distB2 = distB * distB
        
        let A = 2 * (x2 - x1)
        let C = distA2 - distB2 - (x1*x1) + (x2*x2) - (y1*y1) + (y2*y2)
        let x = C / A
        
        let yTerm = distA2 - (x - x1)*(x - x1)
        let y = (yTerm > 0) ? sqrt(yTerm) : 0
        
        return (x, y)
    }
}

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
        // Not used for logging in this example.
    }
    
    func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        guard let accessory = nearbyObjects.first,
              let distance = accessory.distance else { return }
        
        let deviceID = deviceIDFromSession(session)
        deviceDistances[deviceID] = distance
        lastUpdateTimes[deviceID] = Date()
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
    
    func deviceIDFromSession(_ session: NISession) -> Int {
        for (key, value) in referenceDict where value == session {
            return key
        }
        return -1
    }
}

// Add this extension to ensure QorvoDevice provides the expected `deviceID` property.
extension QorvoDevice {
    var deviceID: Int {
        return bleUniqueID
    }
}
