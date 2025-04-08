import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  late Timer _timer;

  @override
  void initState() {
    super.initState();
    // Start a periodic timer to update the UI every 1 second.
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final uwbService = Provider.of<UWBService>(context);
    final coordinates = uwbService.coordinates;
    final beaconIDs = uwbService.connectedBeacons;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          "Sensors Info",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E2023),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            const Text(
              "Detected Beacons:",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            if (beaconIDs.isNotEmpty)
              ...beaconIDs.map((id) => Text(
                    "Beacon ID: $id",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ))
            else
              const Text(
                "No beacons detected",
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            const SizedBox(height: 20),
            const Divider(color: Colors.white),
            const SizedBox(height: 20),
            const Text(
              "User Coordinates:",
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 10),
            coordinates.isNotEmpty
                ? Text(
                    "X: ${coordinates['x']}, Y: ${coordinates['y']}",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  )
                : const Text(
                    "Coordinates not available",
                    style: TextStyle(fontSize: 18, color: Colors.white),
                  ),
          ],
        ),
      ),
    );
  }
}
