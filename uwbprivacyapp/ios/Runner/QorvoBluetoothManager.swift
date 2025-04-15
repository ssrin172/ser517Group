import Foundation
import NearbyInteraction
import CoreBluetooth
import simd
import os

// MARK: - Service and Characteristic Definitions
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

// MARK: - Data Structures

/// Holds UWB location data.
struct Location {
    var distance: Float
    var direction: simd_float3
    var elevation: Int
    var noUpdate: Bool
}

/// Represents a Qorvo beacon device.
class QorvoDevice {
    var blePeripheral: CBPeripheral
    var rxCharacteristic: CBCharacteristic?
    var txCharacteristic: CBCharacteristic?
    
    var bleUniqueID: Int
    var blePeripheralName: String
    var blePeripheralStatus: String
    var bleTimestamp: Int64
    var uwbLocation: Location?
    
    init(peripheral: CBPeripheral, uniqueID: Int, peripheralName: String, timeStamp: Int64) {
        self.blePeripheral = peripheral
        self.bleUniqueID = uniqueID
        self.blePeripheralName = peripheralName
        self.blePeripheralStatus = statusDiscovered
        self.bleTimestamp = timeStamp
        self.uwbLocation = Location(distance: 0,
                                    direction: SIMD3<Float>(x: 0, y: 0, z: 0),
                                    elevation: NINearbyObject.VerticalDirectionEstimate.unknown.rawValue,
                                    noUpdate: false)
    }
}

/// Status constants used to track device state.
let statusDiscovered = "Discovered"
let statusConnected = "Connected"
let statusRanging = "Ranging"

// Global array to keep track of discovered devices.
var qorvoDevices = [QorvoDevice]()

// MARK: - Bluetooth Manager Class

/// This class manages the Bluetooth scanning, connection, and data exchange with Qorvo beacons.
/// It has no UI logic—it only implements the underlying connection and communication.
class QorvoBluetoothManager: NSObject {
    
    // CoreBluetooth Central Manager.
    var centralManager: CBCentralManager!
    
    // Counters used in managing connection iterations.
    let defaultIterations = 5
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0
    
    // Callback closures for notifying other parts of the logic.
    var accessorySynchHandler: ((Int, Bool) -> Void)?
    var accessoryConnectedHandler: ((Int) -> Void)?
    var accessoryDisconnectedHandler: ((Int) -> Void)?
    var accessoryDataHandler: ((Data, String, Int) -> Void)?
    
    var bluetoothReady = false
    var shouldStartWhenReady = false
    
    let logger = os.Logger(subsystem: "com.example.apple-samplecode.QorvoAccessorySample", category: "QorvoBluetoothManager")
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        // Start a timer to check for timed-out devices.
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
    }
    
    deinit {
        centralManager.stopScan()
        logger.info("Scanning stopped.")
    }
    
    // MARK: - Timer Handler
    @objc func timerHandler() {
        var index = 0
        for device in qorvoDevices {
            if device.blePeripheralStatus == statusDiscovered {
                let timeStamp = Int64(Date().timeIntervalSince1970 * 1000.0)
                if timeStamp > (device.bleTimestamp + 5000) {
                    logger.info("Device \(device.blePeripheralName) timed-out and removed at index \(index)")
                    dataSourceHandler(nil, index)
                }
            }
            index += 1
        }
    }
    
    // MARK: - Device Data Source Handling
    func dataSourceHandler(_ device: QorvoDevice?, _ index: Int) {
        if let device = device {
            qorvoDevices.append(device)
            accessorySynchHandler?(qorvoDevices.count - 1, true)
        } else if qorvoDevices.indices.contains(index) {
            qorvoDevices.remove(at: index)
            accessorySynchHandler?(index, false)
        }
    }
    
    // MARK: - Scanning and Connection Methods
    func start() {
        if bluetoothReady {
            startScan()
            retrievePeripheral()
        } else {
            shouldStartWhenReady = true
        }
    }
    
    private func startScan() {
        logger.info("Scanning started.")
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID, QorvoNIService.serviceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    private func retrievePeripheral() {
        // Implement retrieval logic if necessary.
    }
    
    func connectPeripheral(_ uniqueID: Int) throws {
        if let device = getDeviceFromUniqueID(uniqueID) {
            if device.blePeripheralStatus != statusDiscovered { return }
            logger.info("Connecting to Peripheral \(device.blePeripheral)")
            device.blePeripheralStatus = statusConnected
            centralManager.connect(device.blePeripheral, options: nil)
        } else {
            throw BluetoothLECentralError.noPeripheral
        }
    }
    
    func disconnectPeripheral(_ uniqueID: Int) throws {
        if let device = getDeviceFromUniqueID(uniqueID) {
            if device.blePeripheralStatus == statusDiscovered { return }
            logger.info("Disconnecting from Peripheral \(device.blePeripheral)")
            centralManager.cancelPeripheralConnection(device.blePeripheral)
        } else {
            throw BluetoothLECentralError.noPeripheral
        }
    }
    
    func sendData(_ data: Data, _ uniqueID: Int) throws {
        logger.info("Sending Data to device \(uniqueID)")
        if getDeviceFromUniqueID(uniqueID) != nil {
            writeData(data, uniqueID)
        } else {
            throw BluetoothLECentralError.noPeripheral
        }
    }
    
    private func writeData(_ data: Data, _ uniqueID: Int) {
        guard let device = getDeviceFromUniqueID(uniqueID),
              let peripheral = device.blePeripheral as? CBPeripheral,
              let characteristic = device.rxCharacteristic else { return }
        
        let mtu = peripheral.maximumWriteValueLength(for: .withResponse)
        let bytesToCopy = min(mtu, data.count)
        var rawPacket = [UInt8](repeating: 0, count: bytesToCopy)
        data.copyBytes(to: &rawPacket, count: bytesToCopy)
        let packetData = Data(rawPacket)
        logger.info("Writing \(bytesToCopy) bytes to device \(uniqueID).")
        peripheral.writeValue(packetData, for: characteristic, type: .withResponse)
        writeIterationsComplete += 1
    }
    
    func getDeviceFromUniqueID(_ uniqueID: Int) -> QorvoDevice? {
        return qorvoDevices.first { $0.bleUniqueID == uniqueID }
    }
}

// Define an error type for connection issues.
enum BluetoothLECentralError: Error {
    case noPeripheral
}

// MARK: - CBCentralManagerDelegate
extension QorvoBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            logger.info("CBManager is powered on")
            bluetoothReady = true
            if shouldStartWhenReady { start() }
        case .poweredOff:
            logger.error("CBManager is not powered on")
        case .resetting:
            logger.error("CBManager is resetting")
        case .unauthorized:
            handleCBUnauthorized()
        case .unknown:
            logger.error("CBManager state is unknown")
        case .unsupported:
            logger.error("Bluetooth is not supported on this device")
        @unknown default:
            logger.error("A previously unknown central manager state occurred")
        }
    }
    
    func handleCBUnauthorized() {
        switch CBManager.authorization {
        case .denied:
            logger.error("User denied Bluetooth access.")
        case .restricted:
            logger.error("Bluetooth access is restricted.")
        default:
            logger.error("Unexpected Bluetooth authorization state.")
        }
    }
    
    func centralManager(_ central: CBCentralManager,
                        didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any],
                        rssi RSSI: NSNumber) {
        guard let name = advertisementData[CBAdvertisementDataLocalNameKey] as? String else { return }
        let timeStamp = Int64(Date().timeIntervalSince1970 * 1000.0)
        if let device = getDeviceFromUniqueID(peripheral.hashValue) {
            device.bleTimestamp = timeStamp
            return
        }
        let newDevice = QorvoDevice(peripheral: peripheral,
                                     uniqueID: peripheral.hashValue,
                                     peripheralName: name,
                                     timeStamp: timeStamp)
        dataSourceHandler(newDevice, 0)
        logger.info("Discovered peripheral: \(newDevice.blePeripheralName) (UniqueID: \(newDevice.bleUniqueID))")
        
        do {
            try connectPeripheral(peripheral.hashValue)
        } catch {
            logger.error("Failed to connect to peripheral: \(error)")
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        logger.error("Failed to connect to peripheral \(peripheral): \(String(describing: error))")
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        logger.info("Peripheral Connected")
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        peripheral.delegate = self
        peripheral.discoverServices([TransferService.serviceUUID, QorvoNIService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        logger.info("Peripheral Disconnected: \(peripheral.name ?? "Unknown")")
        let uniqueID = peripheral.hashValue
        if let device = getDeviceFromUniqueID(uniqueID) {
            device.bleTimestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
            device.blePeripheralStatus = statusDiscovered
        }
        accessoryDisconnectedHandler?(uniqueID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                try self.connectPeripheral(uniqueID)
                self.logger.info("Reconnecting to \(peripheral.name ?? "Unknown")")
            } catch {
                self.logger.error("Reconnection failed: \(error)")
            }
        }
    }
}

// MARK: - CBPeripheralDelegate
extension QorvoBluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices {
            if service.uuid == TransferService.serviceUUID {
                logger.error("Transfer service invalidated; rediscovering services")
                peripheral.discoverServices([TransferService.serviceUUID])
            }
            if service.uuid == QorvoNIService.serviceUUID {
                logger.error("Qorvo NI service invalidated; rediscovering services")
                peripheral.discoverServices([QorvoNIService.serviceUUID])
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error {
            logger.error("Error discovering services: \(error.localizedDescription)")
            return
        }
        guard let services = peripheral.services else { return }
        for service in services {
            peripheral.discoverCharacteristics([TransferService.rxCharacteristicUUID,
                                                  TransferService.txCharacteristicUUID,
                                                  QorvoNIService.rxCharacteristicUUID,
                                                  QorvoNIService.txCharacteristicUUID],
                                                 for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if let error = error {
            logger.error("Error discovering characteristics: \(error.localizedDescription)")
            return
        }
        let uniqueID = peripheral.hashValue
        guard let device = getDeviceFromUniqueID(uniqueID),
              let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == TransferService.rxCharacteristicUUID ||
                characteristic.uuid == QorvoNIService.rxCharacteristicUUID {
                device.rxCharacteristic = characteristic
                logger.info("Discovered RX characteristic: \(characteristic) for device \(uniqueID)")
            }
            if characteristic.uuid == TransferService.txCharacteristicUUID ||
                characteristic.uuid == QorvoNIService.txCharacteristicUUID {
                device.txCharacteristic = characteristic
                logger.info("Discovered TX characteristic: \(characteristic) for device \(uniqueID)")
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        accessoryConnectedHandler?(uniqueID)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error receiving update for characteristic: \(error.localizedDescription)")
            return
        }
        guard let characteristicData = characteristic.value else { return }
        let byteString = characteristicData.map { String(format: "0x%02x", $0) }.joined(separator: ", ")
        logger.info("Received \(characteristicData.count) bytes: \(byteString)")
        let uniqueID = peripheral.hashValue
        if let device = getDeviceFromUniqueID(uniqueID), let handler = accessoryDataHandler {
            handler(characteristicData, device.blePeripheralName, uniqueID)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            logger.error("Error updating notification state: \(error.localizedDescription)")
            return
        }
        if characteristic.isNotifying {
            logger.info("Notification enabled for \(characteristic)")
        } else {
            logger.info("Notification disabled for \(characteristic). Initiating cleanup.")
            cleanup()
        }
    }
    
    func cleanup() {
        centralManager.stopScan()
        logger.info("Cleaning up peripheral connection.")
    }
}
