import CoreBluetooth
import os
import simd


// This file handles scanning and connecting to nearby beacons.

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

protocol ConnectionManagerDelegate: AnyObject {
    func didConnectToDevices(_ devices: [QorvoDevice])
}

class ConnectionManager: NSObject {
    var discoveredDevices: [QorvoDevice] = []
    private var centralManager: CBCentralManager!
    let logger = os.Logger(subsystem: "com.example.uwbprivacyapp", category: "ConnectionManager")
    weak var delegate: ConnectionManagerDelegate?
    
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
    
    // Connect to devices once two are discovered.
    private func tryConnectToTwoBeacons() {
        if discoveredDevices.count >= 2 {
            let twoDevices = Array(discoveredDevices.prefix(2))
            for device in twoDevices {
                centralManager.connect(device.blePeripheral, options: nil)
                logger.info("Connecting to device: \(device.name, privacy: .public)")
            }
        }
    }
}

extension ConnectionManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        if central.state == .poweredOn {
            logger.info("Bluetooth is powered on.")
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
        
        // Avoid duplicates
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
        let connected = discoveredDevices.filter { $0.blePeripheral.state == .connected }
        if connected.count == 2 {
            stopScanning()
            delegate?.didConnectToDevices(connected)
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didFailToConnect peripheral: CBPeripheral,
                        error: Error?) {
        logger.error("Failed to connect to \(peripheral.name ?? "Unknown", privacy: .public): \(String(describing: error))")
    }
}
