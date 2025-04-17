import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class UWBService with ChangeNotifier {
  static const _methodChannel = MethodChannel('com.example.uwbprivacyapp/uwb');
  static const _eventChannel =
      EventChannel("com.example.uwbprivacyapp/updates");

  bool _isConnected = false;
  List<String> _connectedBeacons = [];
  Map<String, dynamic> _coordinates = {};
  List<Map<String, dynamic>> _sensorsData = [];

  bool get isConnected => _isConnected;
  List<String> get connectedBeacons => _connectedBeacons;
  Map<String, dynamic> get coordinates => _coordinates;
  List<Map<String, dynamic>> get sensorsData => _sensorsData;

  StreamSubscription? _subscription;

  Future<void> startScanning() async {
    debugPrint("▶️ startScanning()");
    try {
      await _methodChannel.invokeMethod('startScanning');
      debugPrint("✅ Invoked native startScanning");
    } on PlatformException catch (e, st) {
      debugPrint("❌ startScanning error: $e\n$st");
      rethrow;
    }

    _subscription = _eventChannel.receiveBroadcastStream().listen(
      (data) async {
        debugPrint("📲 EventChannel → $data");

        if (data is Map) {
          final status = data["status"] ?? "scanning";

          // parse device list
          final beaconsRaw = data['beacons'] as List<dynamic>? ?? [];
          _connectedBeacons = beaconsRaw
              .map((b) {
                if (b is Map && b.containsKey('id')) return b['id'].toString();
                if (b is int) return b.toString();
                return '';
              })
              .where((id) => id.isNotEmpty)
              .toList();

          _coordinates = Map<String, dynamic>.from(
              data['coordinates'] ?? {"x": 0, "y": 0});
          _isConnected = _connectedBeacons.isNotEmpty;

          debugPrint(
              "🔗 isConnected=$_isConnected, beacons=$_connectedBeacons");

          if (status == "connected") {
            // Only fetch once we have at least 2 IDs
            if (_connectedBeacons.length >= 2) {
              // Sort so "112456485-143285168" not "143285168-112456485"
              final sorted = List<String>.from(_connectedBeacons)..sort();
              final groupId = sorted.join('-');
              debugPrint("🌐 Constructed beaconGroupId: $groupId");

              await _fetchSensorData(groupId);
            } else {
              debugPrint(
                  "⏳ Waiting for 2 beacons to connect before fetching sensors.");
            }
          } else {
            debugPrint("ℹ️ Status is '$status'; not fetching sensors.");
          }

          notifyListeners();
        }
      },
      onError: (e, st) => debugPrint("⚠️ EventChannel error: $e\n$st"),
    );
  }

  /// Change HOST logic as before...
  String get _backendHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    // iOS simulator → localhost; physical device → your LAN IP or production URL.
    return '192.168.0.118';
  }

  Future<void> _fetchSensorData(String beaconGroupId) async {
    final url = Uri.parse(
        'http://$_backendHost:8000/api/v1/beacons/$beaconGroupId/sensors');
    debugPrint("GET $url");

    try {
      final resp = await http.get(url);
      debugPrint("📥 ${resp.statusCode}: ${resp.body}");

      if (resp.statusCode == 200) {
        final List<dynamic> list = jsonDecode(resp.body);
        _sensorsData = List<Map<String, dynamic>>.from(list);
        debugPrint("✅ sensorsData: $_sensorsData");
      } else {
        debugPrint("❌ No sensors for $beaconGroupId");
      }
    } catch (e, st) {
      debugPrint("🚨 fetchSensorData error: $e\n$st");
    }
  }

  Future<void> stopScanning() async {
    debugPrint("🛑 stopScanning()");
    try {
      await _methodChannel.invokeMethod('stopScanning');
      debugPrint("✅ Invoked native stopScanning");
    } on PlatformException catch (e, st) {
      debugPrint("❌ stopScanning error: $e\n$st");
      rethrow;
    }

    _isConnected = false;
    _connectedBeacons.clear();
    _coordinates = {};
    _sensorsData.clear();
    await _subscription?.cancel();
    _subscription = null;
    notifyListeners();
  }
}