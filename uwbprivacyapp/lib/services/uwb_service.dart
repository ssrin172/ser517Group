import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class UWBService with ChangeNotifier {
  static const platform = MethodChannel('com.example.uwbprivacyapp/uwb');
  static const EventChannel eventChannel =
      EventChannel("com.example.uwbprivacyapp/updates");

  bool _isConnected = false;
  List<String> _connectedBeacons = [];
  Map<String, dynamic> _coordinates = {};

  bool get isConnected => _isConnected;
  List<String> get connectedBeacons => _connectedBeacons;
  Map<String, dynamic> get coordinates => _coordinates;

  StreamSubscription? _subscription;

  Future<void> startScanning() async {
    // Invoke scanning on the native side.
    try {
      await platform.invokeMethod('startScanning');
    } on PlatformException catch (e) {
      throw Exception("Failed to start scanning: ${e.message}");
    }

    // Subscribe to the event channel.
    _subscription = eventChannel.receiveBroadcastStream().listen((data) {
      if (data is Map) {
        final String status = data["status"] ?? "scanning";
        if (status == "connected") {
          // Update beacon and coordinate information.
          final List<dynamic> beaconList = data['beacons'] ?? [];
          // Convert each beacon entry to a string.
          _connectedBeacons = beaconList
              .map((b) {
                if (b is Map && b.containsKey('id')) {
                  return b['id'].toString();
                } else if (b is int) {
                  return b.toString();
                } else {
                  return "";
                }
              })
              .where((element) => element.isNotEmpty)
              .toList();

          _coordinates = Map<String, dynamic>.from(
              data['coordinates'] ?? {"x": 0, "y": 0});

          // Mark as connected if at least one beacon is found.
          _isConnected = _connectedBeacons.isNotEmpty;
        } else {
          _isConnected = false;
        }
        notifyListeners();
      }
    }, onError: (error) {
      print("Error receiving event channel data: $error");
    });
  }

  Future<void> stopScanning() async {
    try {
      await platform.invokeMethod('stopScanning');
      _isConnected = false;
      _connectedBeacons = [];
      _coordinates = {};
      await _subscription?.cancel();
      _subscription = null;
      notifyListeners();
    } on PlatformException catch (e) {
      throw Exception("Failed to stop scanning: ${e.message}");
    }
  }
}
