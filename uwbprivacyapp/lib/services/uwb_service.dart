// lib/services/uwb_service.dart

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
  bool _hasFetchedSensors = false;

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
          _onEvent,
          onError: (e, st) => debugPrint("⚠️ EventChannel error: $e\n$st"),
        );
  }

  Future<void> _onEvent(dynamic data) async {
    debugPrint("📲 EventChannel → $data");
    if (data is! Map) return;

    final status = data["status"] as String? ?? "scanning";

    // parse beacon IDs
    final beaconsRaw = data['beacons'] as List<dynamic>? ?? [];
    _connectedBeacons = beaconsRaw
        .map((b) {
          if (b is Map && b.containsKey('id')) return b['id'].toString();
          if (b is int) return b.toString();
          return '';
        })
        .where((id) => id.isNotEmpty)
        .toList();

    // parse coordinates
    _coordinates = Map<String, dynamic>.from(
        data['coordinates'] as Map<dynamic, dynamic>? ?? {'x': 0, 'y': 0});

    _isConnected = _connectedBeacons.isNotEmpty;
    debugPrint("🔗 isConnected=$_isConnected, beacons=$_connectedBeacons");

    // fetch sensors once when we first have 2+ beacons
    if (status == "connected" &&
        _connectedBeacons.length >= 2 &&
        !_hasFetchedSensors) {
      final sorted = List<String>.from(_connectedBeacons)..sort();
      final groupId = sorted.join('-');
      debugPrint("🌐 Fetching sensors for groupId: $groupId");
      await _fetchSensorData(groupId);
      _hasFetchedSensors = true;
    }

    // reset if all beacons drop
    if (_connectedBeacons.isEmpty) {
      debugPrint("🚪 All beacons disconnected — clearing cached sensors");
      _hasFetchedSensors = false;
      _sensorsData = [];
    }

    notifyListeners();
  }

 String get _backendHost => 'ser517group.onrender.com';

  Future<void> _fetchSensorData(String beaconGroupId) async {
    final url = Uri.parse(
        'https://ser517group.onrender.com/api/v1/beacons/$beaconGroupId/sensors');
    debugPrint("GET $url");

    try {
      final resp = await http.get(url);
      debugPrint("📥 ${resp.statusCode}: ${resp.body}");

      if (resp.statusCode == 200) {
        final wrapper = jsonDecode(resp.body) as Map<String, dynamic>;
        final list = wrapper['data'] as List<dynamic>? ?? [];
        _sensorsData =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        debugPrint("✅ Loaded ${_sensorsData.length} sensors");
      } else {
        debugPrint(
            "❌ No sensors for $beaconGroupId (status ${resp.statusCode})");
        _sensorsData = [];
      }
    } catch (e, st) {
      debugPrint("🚨 fetchSensorData error: $e\n$st");
      _sensorsData = [];
    }
  }

  Future<void> stopScanning() async {
    debugPrint("🛑 stopScanning()");
    // 1️⃣ Cancel the Dart side subscription immediately
    await _subscription?.cancel();
    _subscription = null;

    // 2️⃣ Tell native to stop
    try {
      await _methodChannel.invokeMethod('stopScanning');
      debugPrint("✅ Invoked native stopScanning");
    } on PlatformException catch (e, st) {
      debugPrint("❌ stopScanning error: $e\n$st");
      rethrow;
    }

    // 3️⃣ Clear all Flutter state
    _isConnected = false;
    _connectedBeacons = [];
    _coordinates = {};
    _sensorsData = [];
    _hasFetchedSensors = false;
    notifyListeners();
  }
}
