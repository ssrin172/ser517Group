import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

    let beaconManager = QorvoBeaconManager() // Instance of your beacon manager

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register plugins (this registers all plugins from GeneratedPluginRegistrant)
        GeneratedPluginRegistrant.register(with: self)
        
        if let controller = window?.rootViewController as? FlutterViewController {
            let channel = FlutterMethodChannel(
                name: "com.example.uwbprivacyapp/uwb",
                binaryMessenger: controller.binaryMessenger
            )
            channel.setMethodCallHandler { [weak self] (call, result) in
                guard let self = self else {
                    result(FlutterError(code: "UNAVAILABLE",
                                        message: "AppDelegate is unavailable",
                                        details: nil))
                    return
                }
                if call.method == "startScanning" {
                    self.beaconManager.startScanning()
                    result(nil)
                } else if call.method == "stopScanning" {
                    self.beaconManager.stopScanning()
                    result(nil)
                } else {
                    result(FlutterMethodNotImplemented)
                }
            }
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
