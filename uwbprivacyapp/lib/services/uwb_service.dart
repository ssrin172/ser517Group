import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class UWBService with ChangeNotifier {
  static const platform = MethodChannel('com.example.uwbprivacyapp/uwb');

  bool _isConnected = false;
  List<String> _connectedBeacons = [];
  Map<String, dynamic> _coordinates = {};

  bool get isConnected => _isConnected;
  List<String> get connectedBeacons => _connectedBeacons;
  Map<String, dynamic> get coordinates => _coordinates;

  Future<void> startScanning() async {
    try {
      final result = await platform.invokeMethod('startScanning');

      if (result is Map) {
        _isConnected = true;
        _connectedBeacons = List<String>.from(result['beaconIDs'] ?? []);
        _coordinates = Map<String, dynamic>.from(result['coordinates'] ?? {});
        notifyListeners();
      }
    } on PlatformException catch (e) {
      throw Exception("Failed to start scanning: ${e.message}");
    }
  }

  Future<void> stopScanning() async {
    try {
      await platform.invokeMethod('stopScanning');
      _isConnected = false;
      _connectedBeacons = [];
      _coordinates = {};
      notifyListeners();
    } on PlatformException catch (e) {
      throw Exception("Failed to stop scanning: ${e.message}");
    }
  }
}
