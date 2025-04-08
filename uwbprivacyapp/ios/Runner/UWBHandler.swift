import Flutter
import UIKit
import NearbyInteraction
import CoreBluetooth
import simd
import os

// MARK: - Constants and Data Structures

struct TransferService {
    static let serviceUUID = CBUUID(string: "6E400001-B5A3-F393-E0A9-E50E24DCCA9E")
    static let rxCharacteristicUUID = CBUUID(string: "6E400002-B5A3-F393-E0A9-E50E24DCCA9E")
    static let txCharacteristicUUID = CBUUID(string: "6E400003-B5A3-F393-E0A9-E50E24DCCA9E")
}

struct QorvoNIService {
    static let serviceUUID = CBUUID(string: "2E938FD0-6A61-11ED-A1EB-0242AC120002")
    static let scCharacteristicUUID = CBUUID(string: "2E93941C-6A61-11ED-A1EB-0242AC120002")
    static let rxCharacteristicUUID = CBUUID(string: "2E93998A-6A61-11ED-A1EB-0242AC120002")
    static let txCharacteristicUUID = CBUUID(string: "2E939AF2-6A61-11ED-A1EB-0242AC120002")
}

struct Location {
    var distance: Float
    var direction: simd_float3
}

class QorvoDevice {
    var blePeripheral: CBPeripheral
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    var deviceID: Int
    var name: String
    var lastUpdate: Int64
    var uwbLocation: Location?
    
    init(peripheral: CBPeripheral, deviceID: Int, name: String, timeStamp: Int64) {
        self.blePeripheral = peripheral
        self.deviceID = deviceID
        self.name = name
        self.lastUpdate = timeStamp
        self.uwbLocation = Location(distance: 0, direction: SIMD3<Float>(0, 0, 0))
    }
}

// MARK: - Qorvo Beacon Manager

class QorvoBeaconManager: NSObject {
    // Make discoveredDevices accessible for NI updates.
    var discoveredDevices: [QorvoDevice] = []
    private var centralManager: CBCentralManager!
    let logger = os.Logger(subsystem: "com.example.uwbprivacyapp", category: "QorvoBeaconManager")
    
    // Callback to be invoked when two beacons are connected.
    var onBeaconsConnected: (([QorvoDevice]) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID, QorvoNIService.serviceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        logger.info("Started scanning for UWB beacons.")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        logger.info("Stopped scanning.")
    }
    
    // Once at least two devices are discovered, attempt to connect.
    private func tryConnectToTwoBeacons() {
        if discoveredDevices.count >= 2 {
            let twoDevices = Array(discoveredDevices.prefix(2))
            twoDevices.forEach { device in
                centralManager.connect(device.blePeripheral, options: nil)
                logger.info("Connecting to device: \(device.name, privacy: .public)")
            }
        }
    }
    
    // Calculate user coordinates using the measured distances.
    func calculateUserCoordinates() -> (x: Float, y: Float) {
        guard discoveredDevices.count >= 2,
              let distance1 = discoveredDevices[0].uwbLocation?.distance,
              let distance2 = discoveredDevices[1].uwbLocation?.distance else {
            return (0, 0)
        }
        
        // Beacon positions – adjust these to your actual setup.
        let beacon1 = (x: Float(0.0), y: Float(0.0))
        let beacon2 = (x: Float(2.5), y: Float(0.0))
        
        let A = 2 * (beacon2.x - beacon1.x)
        let C = (distance1 * distance1) - (distance2 * distance2)
                  - (beacon1.x * beacon1.x) + (beacon2.x * beacon2.x)
                  - (beacon1.y * beacon1.y) + (beacon2.y * beacon2.y)
        let x = C / A
        let yTerm = (distance1 * distance1) - ((x - beacon1.x) * (x - beacon1.x))
        let y = (yTerm > 0 ? sqrt(yTerm) : 0)
        
        logger.info("Calculated coordinates: (\(x, privacy: .public), \(y, privacy: .public))")
        return (x, y)
    }
}

// MARK: - CBCentralManagerDelegate

extension QorvoBeaconManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            logger.info("Bluetooth is powered on.")
            // Do not auto-start scanning here.
        } else {
            logger.error("Bluetooth not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return }
        let deviceID = peripheral.hash
        let timeStamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        if discoveredDevices.contains(where: { $0.deviceID == deviceID }) {
            return
        }
        
        let device = QorvoDevice(peripheral: peripheral, deviceID: deviceID, name: name, timeStamp: timeStamp)
        discoveredDevices.append(device)
        logger.info("Discovered beacon: \(name, privacy: .public)")
        
        tryConnectToTwoBeacons()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        logger.info("Connected to peripheral: \(peripheral.name ?? "Unknown", privacy: .public)")
        // Ranging updates will come from the NI session delegate.
        let connected = discoveredDevices.filter { $0.blePeripheral.state == .connected }
        if connected.count == 2 {
            stopScanning()
            onBeaconsConnected?(connected)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        logger.error("Failed to connect to \(peripheral.name ?? "Unknown", privacy: .public): \(String(describing: error))")
    }
}

// MARK: - Nearby Interaction (NI) Integration

extension QorvoBeaconManager: NISessionDelegate {
    public func session(_ session: NISession, didUpdate nearbyObjects: [NINearbyObject]) {
        // If two distinct accessories are available, update each device separately.
        if nearbyObjects.count >= 2 {
            let accessory1 = nearbyObjects[0]
            let accessory2 = nearbyObjects[1]
            if let distance1 = accessory1.distance, let distance2 = accessory2.distance {
                if discoveredDevices.count >= 2 {
                    discoveredDevices[0].uwbLocation = Location(
                        distance: distance1,
                        direction: accessory1.direction ?? SIMD3<Float>(0, 0, 0)
                    )
                    discoveredDevices[1].uwbLocation = Location(
                        distance: distance2,
                        direction: accessory2.direction ?? SIMD3<Float>(0, 0, 0)
                    )
                    logger.info("NI update - Device 0 distance: \(distance1), Device 1 distance: \(distance2)")
                }
            }
        } else if let accessory = nearbyObjects.first, discoveredDevices.count > 0 {
            // If only one accessory is available, update only the first device.
            if let distance = accessory.distance {
                discoveredDevices[0].uwbLocation = Location(
                    distance: distance,
                    direction: accessory.direction ?? SIMD3<Float>(0, 0, 0)
                )
                logger.info("NI update - Single device distance: \(distance)")
            }
        }
    }
    
    public func session(_ session: NISession, didRemove nearbyObjects: [NINearbyObject], reason: NINearbyObject.RemovalReason) {
        // Handle accessory removal if needed.
    }
    
    public func sessionWasSuspended(_ session: NISession) {
        logger.info("NI session was suspended.")
    }
    
    public func sessionSuspensionEnded(_ session: NISession) {
        logger.info("NI session suspension ended.")
        // Optionally restart session if necessary.
    }
    
    public func session(_ session: NISession, didInvalidateWith error: Error) {
        logger.error("NI session invalidated: \(error.localizedDescription)")
    }
}

// MARK: - Flutter Plugin Integration & Streaming

public class UWBHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    var beaconManager = QorvoBeaconManager()
    
    // Event channel variables.
    var eventSink: FlutterEventSink?
    var updateTimer: Timer?
    
    // For method channel callbacks.
    var pendingResult: FlutterResult?
    var connectedResult: [String: Any]?
    
    // NI session instance.
    var niSession: NISession?
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(name: "com.example.uwbprivacyapp/uwb",
                                                   binaryMessenger: registrar.messenger())
        let eventChannel = FlutterEventChannel(name: "com.example.uwbprivacyapp/updates",
                                                 binaryMessenger: registrar.messenger())
        let instance = UWBHandler()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public override init() {
        super.init()
        niSession = NISession()
        niSession?.delegate = beaconManager
        
        // When two beacons are connected, start streaming updates.
        beaconManager.onBeaconsConnected = { [weak self] devices in
            guard let self = self else { return }
            self.beaconManager.stopScanning()
            
            // *** IMPORTANT ***
            // Replace the following placeholder NI session run with your actual configuration:
            // Example:
            // if let token = devices.first?.discoveryToken {
            //     let configuration = NINearbyAccessoryConfiguration(discoveryToken: token)
            //     configuration.isCameraAssistanceEnabled = true
            //     self.niSession?.run(configuration)
            // }
            
            self.updateTimer?.invalidate()
            self.updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                let coords = self.beaconManager.calculateUserCoordinates()
                let connectedDevices = self.beaconManager.discoveredDevices.prefix(2)
                let beaconIDs = connectedDevices.map { "\($0.deviceID)" }
                let data: [String: Any] = [
                    "beaconIDs": beaconIDs,
                    "coordinates": ["x": coords.x, "y": coords.y]
                ]
                self.eventSink?(data)
            }
            
            let coords = self.beaconManager.calculateUserCoordinates()
            let connectedDevices = self.beaconManager.discoveredDevices.prefix(2)
            let beaconIDs = connectedDevices.map { "\($0.deviceID)" }
            self.connectedResult = [
                "beaconIDs": beaconIDs,
                "coordinates": ["x": coords.x, "y": coords.y]
            ]
            self.callResultIfNeeded()
        }
    }
    
    // MARK: - Method Channel Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            connectedResult = nil
            pendingResult = result
            beaconManager.startScanning()
        case "stopScanning":
            beaconManager.stopScanning()
            updateTimer?.invalidate()
            updateTimer = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func callResultIfNeeded() {
        if let res = connectedResult, let pending = pendingResult {
            pending(res)
            pendingResult = nil
        }
    }
    
    // MARK: - FlutterStreamHandler Methods
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        updateTimer?.invalidate()
        updateTimer = nil
        return nil
    }
}
