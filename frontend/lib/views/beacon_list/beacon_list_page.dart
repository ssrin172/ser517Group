import 'package:flutter/material.dart';

class BeaconListPage extends StatelessWidget {
  final List<String> beacons = [
    "Beacon Device-1",
    "Beacon Device-2",
    "Beacon Device-3",
    "Beacon Device-4",
    "Beacon Device-5",
    "Beacon Device-6",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Nearby Beacons")),
      body: ListView.builder(
        itemCount: beacons.length,
        itemBuilder: (context, index) {
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: Colors.blueGrey[900],
            child: ListTile(
              leading: Icon(
                Icons.wifi_tethering,
                color: const Color.fromARGB(255, 255, 165, 68),
              ),
              title: Text(
                beacons[index],
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              contentPadding: EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }
}
