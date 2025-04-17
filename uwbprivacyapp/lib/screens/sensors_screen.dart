import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';

class SensorsScreen extends StatelessWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uwbService = context.watch<UWBService>();

    return Scaffold(
      appBar: AppBar(
        title:
            const Text("Sensors Info", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      backgroundColor: const Color(0xFF1E2023),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: uwbService.isConnected
            ? SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Show connected beacon IDs
                    const Text(
                      "Connected Beacons:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...uwbService.connectedBeacons.map((id) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            "Beacon ID: $id",
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                            ),
                          ),
                        )),
                    const SizedBox(height: 20),

                    // Show backend sensors
                    const Text(
                      "Devices Associated with Beacon Group:",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (uwbService.sensorsData.isEmpty)
                      const Text(
                        "No sensors found.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    ...uwbService.sensorsData.map((sensor) {
                      final coord =
                          sensor['coordinates'] as Map<String, dynamic>?;
                      return Card(
                        color: const Color(0xFF2A2D32),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sensor['sensorName'] ?? 'Unknown',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Type: ${sensor['sensorType'] ?? '—'}',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Coordinates: (${coord?['x'] ?? 0}, ${coord?['y'] ?? 0})',
                                style: const TextStyle(
                                  fontSize: 16,
                                  color: Colors.white70,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ],
                ),
              )
            : const Center(
                child: CircularProgressIndicator(),
              ),
      ),
    );
  }
}