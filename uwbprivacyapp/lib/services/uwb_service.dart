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
        if (data is! Map) return;

        final status = data["status"] ?? "scanning";

        // parse beacons
        final beaconsRaw = data['beacons'] as List<dynamic>? ?? [];
        _connectedBeacons = beaconsRaw
            .map((b) {
              if (b is Map && b.containsKey('id')) return b['id'].toString();
              if (b is int) return b.toString();
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();

        // parse coords
        _coordinates = Map<String, dynamic>.from(
            data['coordinates'] as Map? ?? {'x': 0, 'y': 0});

        _isConnected = _connectedBeacons.isNotEmpty;
        debugPrint("🔗 isConnected=$_isConnected, beacons=$_connectedBeacons");

        if (status == "connected" && _connectedBeacons.length >= 2) {
          final sorted = List<String>.from(_connectedBeacons)..sort();
          final groupId = sorted.join('-');
          debugPrint("🌐 Constructed beaconGroupId: $groupId");
          await _fetchSensorData(groupId);
        } else {
          debugPrint(
              "ℹ️ status='$status'; need 2 beacons before fetching sensors.");
          _sensorsData = [];
          notifyListeners();
        }
      },
      onError: (e, st) => debugPrint("⚠️ EventChannel error: $e\n$st"),
    );
  }

  String get _backendHost {
    if (kIsWeb) return 'localhost';
    if (Platform.isAndroid) return '10.0.2.2';
    return '192.168.0.118'; // your LAN IP for iOS device
  }

  Future<void> _fetchSensorData(String beaconGroupId) async {
    final url = Uri.parse(
        'http://$_backendHost:8000/api/v1/beacons/$beaconGroupId/sensors');
    debugPrint('GET $url');

    try {
      final resp = await http.get(url);
      debugPrint('📥 ${resp.statusCode}: ${resp.body}');

      if (resp.statusCode == 200) {
        final Map<String, dynamic> wrapper = jsonDecode(resp.body);
        final List<dynamic> list = wrapper['data'] as List<dynamic>? ?? [];
        _sensorsData =
            list.map((e) => Map<String, dynamic>.from(e as Map)).toList();
        debugPrint('✅ Parsed sensorsData: $_sensorsData');
      } else {
        debugPrint('❌ No sensors for $beaconGroupId');
        _sensorsData = [];
      }
    } catch (e, st) {
      debugPrint('🚨 fetchSensorData error: $e\n$st');
      _sensorsData = [];
    }

    notifyListeners();
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
