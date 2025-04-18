// lib/screens/sensors_screen.dart

import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';
import '../widgets/background_scaffold.dart';
import 'loading_screen.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  @override
  _SensorsScreenState createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  late final UWBService _uwbService;

  @override
  void initState() {
    super.initState();
    _uwbService = Provider.of<UWBService>(context, listen: false);
    _uwbService.addListener(_checkOutOfRange);
  }

  Future<void> _checkOutOfRange() async {
    // only start checking once we've fetched sensor data
    if (_uwbService.sensorsData.isEmpty) return;

    final coords = _uwbService.coordinates;
    if (!coords.containsKey('x') || !coords.containsKey('y')) return;

    final x = (coords['x'] as num).toDouble();
    final y = (coords['y'] as num).toDouble();

    // midpoint = (3.5, 0), radius = 4.5
    final dx = x - 3.5;
    final dy = y - 0.0;
    final dist = sqrt(dx * dx + dy * dy);
    debugPrint("🎯 Distance from center: $dist");

    if (dist > 4.5) {
      await _uwbService.stopScanning();
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => const LoadingScreen(
            initialShowError: true,
            initialErrorMessage: 'Out of range',
          ),
        ),
      );
    }
  }

  @override
  void dispose() {
    _uwbService.removeListener(_checkOutOfRange);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uwb = context.watch<UWBService>();
    final userX = (uwb.coordinates['x'] as num?)?.toDouble() ?? 0.0;
    final userY = (uwb.coordinates['y'] as num?)?.toDouble() ?? 0.0;

    final sensorsWithStats = uwb.sensorsData.map((s) {
      final coords = s['coordinates'] as Map<String, dynamic>;
      final sx = (coords['x'] as num).toDouble();
      final sy = (coords['y'] as num).toDouble();
      final range = (s['sensorTrackingRange'] as num).toDouble();
      final dx = sx - userX, dy = sy - userY;
      final dist = sqrt(dx * dx + dy * dy);
      final inRange = dist <= range;
      return {'sensor': s, 'distance': dist, 'inRange': inRange};
    }).toList()
      ..sort((a, b) =>
          (a['distance'] as double).compareTo(b['distance'] as double));

    return BackgroundScaffold(
      appBar: AppBar(
        title:
            const Text('Sensors Info', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: uwb.isConnected && sensorsWithStats.isNotEmpty
            ? ListView.builder(
                itemCount: sensorsWithStats.length,
                itemBuilder: (context, i) {
                  final entry = sensorsWithStats[i];
                  return SensorTile(
                    sensor: entry['sensor'] as Map<String, dynamic>,
                    distance: entry['distance'] as double,
                    inRange: entry['inRange'] as bool,
                  );
                },
              )
            : Center(
                child: Text(
                  uwb.isConnected
                      ? 'Loading Sensors Info...'
                      : 'Waiting For Connection...',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
              ),
      ),
    );
  }
}

class SensorTile extends StatefulWidget {
  final Map<String, dynamic> sensor;
  final double distance;
  final bool inRange;

  const SensorTile({
    Key? key,
    required this.sensor,
    required this.distance,
    required this.inRange,
  }) : super(key: key);

  @override
  _SensorTileState createState() => _SensorTileState();
}

class _SensorTileState extends State<SensorTile> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.sensor;
    final dist = widget.distance;
    final inRange = widget.inRange;
    final coords = s['coordinates'] as Map<String, dynamic>;

    final headerColor =
        inRange ? Colors.red.withOpacity(0.7) : Colors.green.withOpacity(0.7);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: headerColor,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: ExpansionTile(
          onExpansionChanged: (expanded) => setState(() {
            _isExpanded = expanded;
          }),
          backgroundColor: const Color(0xFF1E2023),
          collapsedBackgroundColor: headerColor,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  s['sensorName'] ?? 'Unnamed Sensor',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _isExpanded
                        ? (inRange ? Colors.red : Colors.green)
                        : Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Text(
                '${dist.toStringAsFixed(1)} m',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
                textAlign: TextAlign.left,
              ),
            ],
          ),
          children: [
            _detailSection('Type', s['sensorType']),
            _detailSection('Purpose', s['purpose']),
            _detailSection('Why', s['description']),
            _detailSection('Where', '(${coords['x']}, ${coords['y']})'),
            _detailSection('Mitigation', s['mitigationDetails']),
          ],
        ),
      ),
    );
  }
}

Widget _detailSection(String label, String? value) {
  return Align(
    alignment: Alignment.centerLeft,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$label:',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 4),
        Text(
          value ?? '—',
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
          textAlign: TextAlign.left,
        ),
        const SizedBox(height: 12),
      ],
    ),
  );
}
