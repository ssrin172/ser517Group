mport 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'dart:math';
import 'dart:async';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWB Scanner',
      theme: ThemeData(
        primarySwatch: Colors.indigo,
        scaffoldBackgroundColor: Colors.grey[100],
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.indigo,
          foregroundColor: Colors.white,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.indigo,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
        ),
        textTheme: const TextTheme(
          bodyMedium: TextStyle(color: Colors.black87),
        ),
      ),
      debugShowCheckedModeBanner: false,
      home: const PermissionPage(),
    );
  }
}

class PermissionPage extends StatefulWidget {
  const PermissionPage({super.key});

  @override
  State<PermissionPage> createState() => _PermissionPageState();
}

class _PermissionPageState extends State<PermissionPage> {
  String _status = 'Checking permissions...';
  bool _permissionGranted = false;

  Future<void> _requestPermissions() async {
    final whenInUseStatus = await Permission.locationWhenInUse.request();

    if (whenInUseStatus.isGranted) {
      final alwaysStatus = await Permission.locationAlways.request();

      if (alwaysStatus.isGranted) {
        setState(() {
          _permissionGranted = true;
          _status = 'Location Always permission granted ✅';
        });
      } else {
        setState(() {
          _permissionGranted = true;
          _status = 'Location Always permission is recommended but not required.';
        });
      }
    } else {
      setState(() {
        _status = 'Location permission is required.';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UWB Permissions')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                _status,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 30),
              ElevatedButton.icon(
                icon: const Icon(Icons.sensors),
                label: const Text('Scan for Beacons'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const BeaconListPage()),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BeaconListPage extends StatefulWidget {
  const BeaconListPage({super.key});

  @override
  State<BeaconListPage> createState() => _BeaconListPageState();
}

class _BeaconListPageState extends State<BeaconListPage> {
  List<Map<String, dynamic>> beacons = [];
  late Timer _timer;

  void _startSimulatedScanning() {
    _timer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      setState(() {
        beacons = List.generate(3, (index) {
          return {
            'id': 'Beacon ${String.fromCharCode(65 + index)}',
            'distance': (1.0 + Random().nextDouble() * 3).toStringAsFixed(2),
            'azimuth': Random().nextDouble() * 360,
            'elevation': Random().nextDouble() * 90 - 45,
          };
        });
      });
    });
  }

  @override
  void initState() {
    super.initState();
    _startSimulatedScanning();
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Nearby Beacons')),
      body: ListView.builder(
        itemCount: beacons.length,
        itemBuilder: (context, index) {
          final beacon = beacons[index];
          return ListTile(
            title: Text(beacon['id']),
            subtitle: Text('Distance: ${beacon['distance']} m'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BeaconDetailsPage(beacon: beacon),
              ),
            ),
          );
        },
      ),
    );
  }
}

class BeaconDetailsPage extends StatelessWidget {
  final Map<String, dynamic> beacon;
  const BeaconDetailsPage({super.key, required this.beacon});

  @override
  Widget build(BuildContext context) {
    final double distance = double.tryParse(beacon['distance'].toString()) ?? 0.0;
    final double azimuth = beacon['azimuth'];
    final double elevation = beacon['elevation'];

    return Scaffold(
      appBar: AppBar(title: Text('${beacon['id']} Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Distance: ${distance.toStringAsFixed(2)} m', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Azimuth: ${azimuth.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Elevation: ${elevation.toStringAsFixed(1)}°', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            const Text('Visualization:', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Center(
              child: CustomPaint(
                size: const Size(200, 200),
                painter: BeaconVisualizer(azimuth: azimuth, elevation: elevation),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class BeaconVisualizer extends CustomPainter {
  final double azimuth;
  final double elevation;

  BeaconVisualizer({required this.azimuth, required this.elevation});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint axisPaint = Paint()
      ..color = Colors.grey
      ..strokeWidth = 2;

    final Paint arrowPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 4
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    canvas.drawLine(Offset(center.dx, 0), Offset(center.dx, size.height), axisPaint);
    canvas.drawLine(Offset(0, center.dy), Offset(size.width, center.dy), axisPaint);

    final double radians = azimuth * pi / 180;
    final arrowLength = 70.0;
    final arrowTip = Offset(
      center.dx + arrowLength * cos(radians),
      center.dy - arrowLength * sin(radians),
    );

    canvas.drawLine(center, arrowTip, arrowPaint);
    canvas.drawCircle(arrowTip, 5, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
