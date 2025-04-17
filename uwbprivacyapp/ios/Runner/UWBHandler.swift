import Flutter
import UIKit
import NearbyInteraction
import simd

public class UWBHandler: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    var updateTimer: Timer?
    var eventSink: FlutterEventSink?
    
    // Use the shared beacon manager instance.
    let beaconManager = QorvoBeaconManager.shared

    public static func register(with registrar: FlutterPluginRegistrar) {
        let methodChannel = FlutterMethodChannel(
            name: "com.example.uwbprivacyapp/uwb",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.example.uwbprivacyapp/updates",
            binaryMessenger: registrar.messenger()
        )
        let instance = UWBHandler()
        registrar.addMethodCallDelegate(instance, channel: methodChannel)
        eventChannel.setStreamHandler(instance)
    }
    
    public override init() {
        super.init()
    }
    
    /// Returns the current update dictionary containing beacon data and computed coordinates.
    /// - It looks for two known beacon IDs (112456485 and 143285168) in the deviceDistances dictionary.
    /// - If both distances are available, it uses trilateration; if only one is available, it uses that beacon’s fixed coordinate.
    /// - The update always sends the beacon data as a list of maps.
    func currentCoordinatesUpdate() -> [String: Any] {
        let deviceA = 112456485
        let deviceB = 143285168
        
        var beaconData: [[String: Any]] = []
        
        if let distanceA = beaconManager.deviceDistances[deviceA] {
            beaconData.append(["id": deviceA, "distance": distanceA])
        }
        if let distanceB = beaconManager.deviceDistances[deviceB] {
            beaconData.append(["id": deviceB, "distance": distanceB])
        }
        
        let status = beaconData.isEmpty ? "scanning" : "connected"
        
        var coordinates: (Float, Float) = (0, 0)
        if beaconData.count >= 2,
           let distA = beaconManager.deviceDistances[deviceA],
           let distB = beaconManager.deviceDistances[deviceB] {
            // Use trilateration if both beacon distances are available.
            coordinates = beaconManager.calculateUserCoordinates(distA: distA, distB: distB)
        } else if beaconData.count == 1,
                  let firstBeaconID = beaconData.first?["id"] as? Int,
                  let fixed = beaconManager.beaconPositions[firstBeaconID] {
            // For a single beacon, use its fixed coordinate (if available).
            coordinates = fixed
        }
        
        let update: [String: Any] = [
            "status": status,
            "beacons": beaconData,
            "coordinates": ["x": coordinates.0, "y": coordinates.1]
        ]
        return update
    }
    
    // MARK: - Flutter Method Channel Handling
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "startScanning":
            beaconManager.startScanning()
            result(["status": "scanning"])
        case "stopScanning":
            beaconManager.stopScanning()
            result(nil)
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Flutter Event Channel Handling
    
    /// Called when Flutter subscribes to our event channel.
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        updateTimer?.invalidate()
        updateTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            let update = self.currentCoordinatesUpdate()
            print("Sending update: \(update)")
            self.eventSink?(update)
        }
        return nil
    }
    
    /// Called when the event channel is canceled.
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        eventSink = nil
        updateTimer?.invalidate()
        updateTimer = nil
        return nil
    }
}
