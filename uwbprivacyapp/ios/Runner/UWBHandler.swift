import Flutter
import UIKit
import NearbyInteraction
import simd
import os

// This file now focuses only on handling user coordinates.

public class UWBHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    var connectionManager = ConnectionManager()
    var updateTimer: Timer?
    var eventSink: FlutterEventSink?
    var pendingResult: FlutterResult?
    var connectedDevices: [QorvoDevice]?
    let logger = os.Logger(subsystem: "com.example.uwbprivacyapp", category: "UWBHandler")
    
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
        connectionManager.delegate = self
        niSession = NISession()
        // If needed, set the NI session delegate here.
    }
    
    // Calculate user coordinates using the distances from connected devices.
    func calculateUserCoordinates() -> (x: Float, y: Float) {
        guard let devices = connectedDevices,
              devices.count >= 2,
              let distance1 = devices[0].uwbLocation?.distance,
              let distance2 = devices[1].uwbLocation?.distance else {
            return (0, 0)
        }
        
        // Example beacon positions; adjust according to actual setup.
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
    
    // MARK: - Method Channel Handler
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            pendingResult = result
            connectionManager.startScanning()
        case "stopScanning":
            connectionManager.stopScanning()
            updateTimer?.invalidate()
            updateTimer = nil
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    func callResultIfNeeded() {
        if let res = self.connectedCoordinatesResult(), let pending = pendingResult {
            pending(res)
            pendingResult = nil
        }
    }
    
    func connectedCoordinatesResult() -> [String: Any]? {
        guard let devices = connectedDevices, devices.count >= 2 else { return nil }
        let coords = calculateUserCoordinates()
        let beaconIDs = devices.prefix(2).map { "\($0.deviceID)" }
        return [
            "beaconIDs": beaconIDs,
            "coordinates": ["x": coords.x, "y": coords.y]
        ]
    }
    
    // MARK: - FlutterStreamHandler Methods
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        // Start a timer to update coordinates every second.
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            if let result = self?.connectedCoordinatesResult() {
                self?.eventSink?(result)
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

extension UWBHandler: ConnectionManagerDelegate {
    func didConnectToDevices(_ devices: [QorvoDevice]) {
        connectedDevices = devices
        connectionManager.stopScanning()
        callResultIfNeeded()
    }
}
