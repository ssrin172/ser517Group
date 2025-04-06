import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';
import 'sensors_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isSearching = false;
  String _statusMessage = 'Ready to scan for UWB beacons';

  @override
  Widget build(BuildContext context) {
    final uwbService = Provider.of<UWBService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('UWB Privacy App'),
        centerTitle: true,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.sensors, size: 100, color: Colors.blue),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_isSearching && !uwbService.isConnected)
                ElevatedButton(
                  onPressed: () async {
                    setState(() {
                      _isSearching = true;
                      _statusMessage = 'Searching for UWB beacons...';
                    });

                    try {
                      await uwbService.startScanning();

                      if (uwbService.isConnected) {
                        setState(() {
                          _statusMessage = 'Connected to beacons!';
                        });

                        Future.delayed(const Duration(seconds: 1), () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SensorsScreen(),
                            ),
                          );
                        });
                      }
                    } catch (e) {
                      setState(() {
                        _statusMessage = 'Error: ${e.toString()}';
                      });
                    } finally {
                      setState(() {
                        _isSearching = false;
                      });
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  child: const Text(
                    'START SCAN',
                    style: TextStyle(fontSize: 18),
                  ),
                ),
              if (_isSearching) const CircularProgressIndicator(),
              if (uwbService.isConnected)
                const Icon(Icons.check_circle, color: Colors.green, size: 50),
            ],
          ),
        ),
      ),
    );
  }
}
