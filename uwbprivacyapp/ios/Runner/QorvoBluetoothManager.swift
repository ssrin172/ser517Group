import Foundation
import NearbyInteraction
import CoreBluetooth
import simd

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

struct Location {
    var distance: Float
    var direction: simd_float3
    var elevation: Int
    var noUpdate: Bool
}

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

let statusDiscovered = "Discovered"
let statusConnected = "Connected"
let statusRanging = "Ranging"

var qorvoDevices = [QorvoDevice]()

// MARK: - Bluetooth Manager Class

class QorvoBluetoothManager: NSObject {
    
    var centralManager: CBCentralManager!
    let defaultIterations = 5
    var writeIterationsComplete = 0
    var connectionIterationsComplete = 0
    
    var accessorySynchHandler: ((Int, Bool) -> Void)?
    var accessoryConnectedHandler: ((Int) -> Void)?
    var accessoryDisconnectedHandler: ((Int) -> Void)?
    var accessoryDataHandler: ((Data, String, Int) -> Void)?
    
    var bluetoothReady = false
    var shouldStartWhenReady = false
    
    override init() {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil, options: [CBCentralManagerOptionShowPowerAlertKey: true])
        Timer.scheduledTimer(timeInterval: 0.2, target: self, selector: #selector(timerHandler), userInfo: nil, repeats: true)
    }
    
    deinit {
        centralManager.stopScan()
    }
    
    @objc func timerHandler() {
        var index = 0
        for device in qorvoDevices {
            if device.blePeripheralStatus == statusDiscovered {
                let timeStamp = Int64(Date().timeIntervalSince1970 * 1000.0)
                if timeStamp > (device.bleTimestamp + 5000) {
                    dataSourceHandler(nil, index)
                }
            }
            index += 1
        }
    }
    
    func dataSourceHandler(_ device: QorvoDevice?, _ index: Int) {
        if let device = device {
            qorvoDevices.append(device)
            accessorySynchHandler?(qorvoDevices.count - 1, true)
        } else if qorvoDevices.indices.contains(index) {
            qorvoDevices.remove(at: index)
            accessorySynchHandler?(index, false)
        }
    }
    
    func start() {
        if bluetoothReady {
            startScan()
            retrievePeripheral()
        } else {
            shouldStartWhenReady = true
        }
    }
    
    private func startScan() {
        centralManager.scanForPeripherals(withServices: [TransferService.serviceUUID, QorvoNIService.serviceUUID],
                                          options: [CBCentralManagerScanOptionAllowDuplicatesKey: true])
    }
    
    private func retrievePeripheral() {
        // Implement retrieval logic if necessary.
    }
    
    func connectPeripheral(_ uniqueID: Int) throws {
        if let device = getDeviceFromUniqueID(uniqueID) {
            if device.blePeripheralStatus != statusDiscovered { return }
            device.blePeripheralStatus = statusConnected
            centralManager.connect(device.blePeripheral, options: nil)
        } else {
            throw BluetoothLECentralError.noPeripheral
        }
    }
    
    func disconnectPeripheral(_ uniqueID: Int) throws {
        if let device = getDeviceFromUniqueID(uniqueID) {
            if device.blePeripheralStatus == statusDiscovered { return }
            centralManager.cancelPeripheralConnection(device.blePeripheral)
        } else {
            throw BluetoothLECentralError.noPeripheral
        }
    }
    
    func sendData(_ data: Data, _ uniqueID: Int) throws {
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
        peripheral.writeValue(packetData, for: characteristic, type: .withResponse)
        writeIterationsComplete += 1
    }
    
    func getDeviceFromUniqueID(_ uniqueID: Int) -> QorvoDevice? {
        return qorvoDevices.first { $0.bleUniqueID == uniqueID }
    }
}

enum BluetoothLECentralError: Error {
    case noPeripheral
}

extension QorvoBluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .poweredOn:
            bluetoothReady = true
            if shouldStartWhenReady { start() }
        case .poweredOff:
            break
        case .resetting:
            break
        case .unauthorized:
            handleCBUnauthorized()
        case .unknown:
            break
        case .unsupported:
            break
        @unknown default:
            break
        }
    }
    
    func handleCBUnauthorized() {
        switch CBManager.authorization {
        case .denied:
            break
        case .restricted:
            break
        default:
            break
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
        do {
            try connectPeripheral(peripheral.hashValue)
        } catch { }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) { }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        connectionIterationsComplete += 1
        writeIterationsComplete = 0
        peripheral.delegate = self
        peripheral.discoverServices([TransferService.serviceUUID, QorvoNIService.serviceUUID])
    }
    
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        let uniqueID = peripheral.hashValue
        if let device = getDeviceFromUniqueID(uniqueID) {
            device.bleTimestamp = Int64(Date().timeIntervalSince1970 * 1000.0)
            device.blePeripheralStatus = statusDiscovered
        }
        accessoryDisconnectedHandler?(uniqueID)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            do {
                try self.connectPeripheral(uniqueID)
            } catch { }
        }
    }
}

extension QorvoBluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didModifyServices invalidatedServices: [CBService]) {
        for service in invalidatedServices {
            if service.uuid == TransferService.serviceUUID {
                peripheral.discoverServices([TransferService.serviceUUID])
            }
            if service.uuid == QorvoNIService.serviceUUID {
                peripheral.discoverServices([QorvoNIService.serviceUUID])
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let error = error { return }
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
        if let error = error { return }
        let uniqueID = peripheral.hashValue
        guard let device = getDeviceFromUniqueID(uniqueID),
              let characteristics = service.characteristics else { return }
        
        for characteristic in characteristics {
            if characteristic.uuid == TransferService.rxCharacteristicUUID ||
                characteristic.uuid == QorvoNIService.rxCharacteristicUUID {
                device.rxCharacteristic = characteristic
            }
            if characteristic.uuid == TransferService.txCharacteristicUUID ||
                characteristic.uuid == QorvoNIService.txCharacteristicUUID {
                device.txCharacteristic = characteristic
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
        
        accessoryConnectedHandler?(uniqueID)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { return }
        guard let characteristicData = characteristic.value else { return }
        let uniqueID = peripheral.hashValue
        if let device = getDeviceFromUniqueID(uniqueID), let handler = accessoryDataHandler {
            handler(characteristicData, device.blePeripheralName, uniqueID)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error { return }
        if characteristic.isNotifying {
            // Notification enabled.
        } else {
            cleanup()
        }
    }
    
    func cleanup() {
        centralManager.stopScan()
    }
}
