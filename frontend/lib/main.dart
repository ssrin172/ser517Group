import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Beacon Finder',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.dark,
        textTheme: TextTheme(
          titleLarge: TextStyle(fontSize: 36, fontWeight: FontWeight.bold, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 16, color: const Color.fromARGB(193, 245, 158, 28)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Color.fromARGB(255, 255, 165, 68),
            textStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      home: HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Beacon Finder")),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Find beacon devices around you",
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => BeaconListPage()),
                );
              },
              child: Text("Find"),
            ),
          ],
        ),
      ),
    );
  }
}

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
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            color: Colors.blueGrey[900],
            child: ListTile(
              leading: Icon(Icons.wifi_tethering, color: const Color.fromARGB(255, 255, 165, 68)),
              title: Text(beacons[index], style: Theme.of(context).textTheme.bodyMedium),
              contentPadding: EdgeInsets.all(16),
            ),
          );
        },
      ),
    );
  }
}
