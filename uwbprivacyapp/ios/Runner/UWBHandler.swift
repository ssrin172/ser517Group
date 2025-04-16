import Flutter
import UIKit
import NearbyInteraction
import simd

public class UWBHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    var updateTimer: Timer?
    var eventSink: FlutterEventSink?
    var pendingResult: FlutterResult?
    var connectedDevices: [QorvoDevice]?  // Updated by your BLE connection logic.
    
    // NI session for receiving location updates.
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
    }
    
    // Calculate coordinates using the first two connected devices.
    func calculateUserCoordinates() -> (x: Float, y: Float) {
        guard let devices = connectedDevices,
              devices.count >= 2,
              let distance1 = devices[0].uwbLocation?.distance,
              let distance2 = devices[1].uwbLocation?.distance else {
            return (0, 0)
        }
        
        let beacon1 = (x: Float(0.0), y: Float(0.0))
        let beacon2 = (x: Float(2.5), y: Float(0.0))
        
        let A = 2 * (beacon2.x - beacon1.x)
        let C = (distance1 * distance1) - (distance2 * distance2)
                    - (beacon1.x * beacon1.x) + (beacon2.x * beacon2.x)
                    - (beacon1.y * beacon1.y) + (beacon2.y * beacon2.y)
        let x = C / A
        let yTerm = (distance1 * distance1) - ((x - beacon1.x) * (x - beacon1.x))
        let y = (yTerm > 0 ? sqrt(yTerm) : 0)
        
        return (x, y)
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            pendingResult = result
        case "stopScanning":
            updateTimer?.invalidate()
            updateTimer = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func connectedCoordinatesResult() -> [String: Any]? {
        guard let devices = connectedDevices, devices.count >= 2 else { return nil }
        
        let beaconData = devices.prefix(2).compactMap { device -> [String: Any]? in
            guard let distance = device.uwbLocation?.distance else { return nil }
            return ["id": "\(device.deviceID)", "distance": distance]
        }
        
        let coords = calculateUserCoordinates()
        return [
            "beacons": beaconData,
            "coordinates": ["x": coords.x, "y": coords.y]
        ]
    }
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let res = self?.connectedCoordinatesResult() {
                self?.eventSink?(res)
            }
        }
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        updateTimer?.invalidate()
        updateTimer = nil
        return nil
    }
}

extension QorvoDevice {
    var deviceID: Int {
        return bleUniqueID
    }
}
