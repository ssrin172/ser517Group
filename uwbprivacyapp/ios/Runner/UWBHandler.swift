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
    // For simplicity, we use only distance/direction; elevation can be added as needed.
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
        self.uwbLocation = Location(distance: 0, direction: SIMD3<Float>(0,0,0))
    }
}

// MARK: - Qorvo Beacon Manager (Simplified)

class QorvoBeaconManager: NSObject {
    private var centralManager: CBCentralManager!
    private var discoveredDevices: [QorvoDevice] = []
    private let logger = os.Logger(subsystem: "com.example.uwbprivacyapp", category: "QorvoBeaconManager")
    
    // Completion callback to call when two beacons are connected
    var onBeaconsConnected: (([QorvoDevice]) -> Void)?
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func startScanning() {
        // Scan for peripherals with the relevant service UUIDs
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID, QorvoNIService.serviceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
        logger.info("Started scanning for UWB beacons.")
    }
    
    func stopScanning() {
        centralManager.stopScan()
        logger.info("Stopped scanning.")
    }
    
    // When we have discovered at least two devices, auto-connect to them.
    private func tryConnectToTwoBeacons() {
        if discoveredDevices.count >= 2 {
            // For simplicity, pick the first two discovered devices
            let twoDevices = Array(discoveredDevices.prefix(2))
            twoDevices.forEach { device in
                centralManager.connect(device.blePeripheral, options: nil)
                logger.info("Connecting to device: \(device.name, privacy: .public)")
            }
        }
    }
    
    // After connection and (in a real implementation) ranging,
    // calculate user coordinates based on two distances.
    // Here we simulate two distances to produce a coordinate.
    func calculateUserCoordinates() -> (x: Float, y: Float) {
        guard discoveredDevices.count >= 2,
              let distance1 = discoveredDevices[0].uwbLocation?.distance,
              let distance2 = discoveredDevices[1].uwbLocation?.distance else {
            return (0, 0)
        }
        
        // For simplicity assume fixed beacon positions.
        let beacon1 = (x: Float(0.0), y: Float(0.0))
        let beacon2 = (x: Float(2.5), y: Float(0.0))
        
        let A = 2 * (beacon2.x - beacon1.x)
        let B = 2 * (beacon2.y - beacon1.y)
        let C = (distance1 * distance1) - (distance2 * distance2) - (beacon1.x * beacon1.x) + (beacon2.x * beacon2.x) - (beacon1.y * beacon1.y) + (beacon2.y * beacon2.y)
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
            startScanning()
        } else {
            logger.error("Bluetooth not available.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String : Any],
                        rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return }
        let deviceID = peripheral.hash
        let timeStamp = Int64(Date().timeIntervalSince1970 * 1000)
        
        // Avoid duplicate entries
        if discoveredDevices.contains(where: { $0.deviceID == deviceID }) {
            return
        }
        
        let device = QorvoDevice(peripheral: peripheral, deviceID: deviceID, name: name, timeStamp: timeStamp)
        discoveredDevices.append(device)
        logger.info("Discovered beacon: \(name, privacy: .public)")
        
        // If we have found two beacons, attempt to connect.
        tryConnectToTwoBeacons()
    }
    
    func centralManager(_ central: CBCentralManager,
                        didConnect peripheral: CBPeripheral) {
        logger.info("Connected to peripheral: \(peripheral.name ?? "Unknown", privacy: .public)")
        // In a real implementation, you would start service/characteristic discovery,
        // subscribe for notifications, and update `uwbLocation` when ranging data arrives.
        // For this example, we simulate that ranging data is received immediately.
        
        if let device = discoveredDevices.first(where: { $0.blePeripheral == peripheral }) {
            // Simulate a ranging update (in a real scenario, update from NI session)
            device.uwbLocation = Location(distance: Float.random(in: 0.5...3.0),
                                          direction: SIMD3<Float>(0, 0, 0))
        }
        
        // When both beacons are connected, call the completion.
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

//
// MARK: - Flutter Plugin Integration
//

public class UWBHandler: NSObject, FlutterPlugin {
    
    // Create an instance of our beacon manager.
    var beaconManager = QorvoBeaconManager()
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "com.example.uwbprivacyapp/uwb", binaryMessenger: registrar.messenger())
        let instance = UWBHandler()
        registrar.addMethodCallDelegate(instance, channel: channel)
    }
    
    public override init() {
        super.init()
        // When two beacons are connected, send the beacon IDs and calculated coordinates back to Flutter.
        beaconManager.onBeaconsConnected = { devices in
            // Calculate coordinates based on simulated ranging data.
            let coords = self.beaconManager.calculateUserCoordinates()
            let beaconIDs = devices.map { "\($0.deviceID)" }
            // Store the result so we can return it from the method channel call.
            self.connectedResult = ["beaconIDs": beaconIDs,
                                    "coordinates": ["x": coords.x, "y": coords.y]]
            // If waiting, call the stored result callback.
            self.callResultIfNeeded()
        }
    }
    
    // A placeholder to store the FlutterMethodCall result callback.
    var pendingResult: FlutterResult?
    var connectedResult: [String: Any]?
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            // Clear previous data
            connectedResult = nil
            pendingResult = result
            // Start scanning
            beaconManager.startScanning()
        case "stopScanning":
            beaconManager.stopScanning()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // If the connected result is ready and a result callback is pending, send data back to Flutter.
    func callResultIfNeeded() {
        if let res = connectedResult, let pending = pendingResult {
            pending(res)
            pendingResult = nil
        }
    }
}
