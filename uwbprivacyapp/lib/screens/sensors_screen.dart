import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({Key? key}) : super(key: key);

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  // The EventChannel used for receiving coordinate updates from native code.
  static const EventChannel _eventChannel =
      EventChannel("com.example.uwbprivacyapp/updates");

  @override
  Widget build(BuildContext context) {
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
        child: StreamBuilder<dynamic>(
          stream: _eventChannel.receiveBroadcastStream(),
          builder: (context, AsyncSnapshot<dynamic> snapshot) {
            if (snapshot.hasData) {
              // Expecting a Map with keys "beacons" and "coordinates"
              final data = snapshot.data as Map<dynamic, dynamic>;
              final beaconData = data['beacons'] as List<dynamic>;
              final coordinates = data['coordinates'] as Map<dynamic, dynamic>;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                  // Iterate over each beacon and show its details.
                  ...beaconData.map((beacon) => Text(
                        "Beacon ID: ${beacon['id']} - Distance: ${beacon['distance']} m",
                        style:
                            const TextStyle(fontSize: 18, color: Colors.white),
                      )),
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
                  Text(
                    "X: ${coordinates['x']}, Y: ${coordinates['y']}",
                    style: const TextStyle(fontSize: 18, color: Colors.white),
                  ),
                ],
              );
            } else if (snapshot.hasError) {
              return const Center(
                  child: Text("Error receiving updates",
                      style: TextStyle(color: Colors.white)));
            } else {
              return const Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}
