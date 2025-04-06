import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {
    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Register plugins (this registers all plugins from GeneratedPluginRegistrant)
        GeneratedPluginRegistrant.register(with: self)
        
        // Manually register your UWB plugin
        if let controller = window?.rootViewController as? FlutterViewController {
            UWBHandler.register(with: controller.registrar(forPlugin: "UWBHandler")!)
        }
        
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
}
