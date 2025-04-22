import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sensor.dart';
import 'uwb_service.dart';

class APIService {
  static const String baseUrl = 'https://ser517group.onrender.com/api/v1/beacons';

  final BuildContext context;

  APIService(this.context);

  Future<List<Sensor>> fetchConnectedSensors() async {
    final uwbService = Provider.of<UWBService>(context, listen: false);

    if (uwbService.connectedBeacons.isEmpty) {
      return [];
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/sensors'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'beacon_ids': uwbService.connectedBeacons,
          'coordinates': uwbService.coordinates,
        }),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Sensor.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load sensors: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('API call failed: $e');
    }
  }
}
