import UIKit
import Flutter

@UIApplicationMain
class AppDelegate: FlutterAppDelegate {

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Get the FlutterViewController.
    guard let controller = window?.rootViewController as? FlutterViewController else {
      fatalError("Unable to retrieve FlutterViewController")
    }
    
    // Manually register your custom plugin.
    UWBHandler.register(with: controller.registrar(forPlugin: "UWBHandler")!)
    
    // Register plugins (this will register plugins from GeneratedPluginRegistrant).
    GeneratedPluginRegistrant.register(with: self)
    
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
