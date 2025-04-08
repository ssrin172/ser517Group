import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';
import 'sensors_screen.dart';

class LoadingScreen extends StatefulWidget {
  const LoadingScreen({super.key});

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    final uwbService = Provider.of<UWBService>(context, listen: false);

    // Start scanning for UWB beacons.
    uwbService.startScanning().catchError((e) {
      print("Scanning error: $e");
    });

    // Wait 3 seconds before checking connectivity.
    Future.delayed(const Duration(seconds: 3), () {
      if (uwbService.isConnected && uwbService.connectedBeacons.length >= 2) {
        // If two beacons are connected, navigate to the sensors screen.
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const SensorsScreen()),
        );
      } else {
        // Otherwise, show the error state.
        setState(() {
          _showError = true;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E2023),
      body: Center(
        child: _showError ? _buildErrorContent() : _buildLoadingContent(),
      ),
    );
  }

  Widget _buildLoadingContent() {
    return Image.asset(
      'assets/images/loading.gif',
      width: 150,
      height: 150,
      fit: BoxFit.contain,
    );
  }

  Widget _buildErrorContent() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Image.asset(
          'assets/images/error.png',
          width: 150,
          height: 150,
          fit: BoxFit.contain,
        ),
        const SizedBox(height: 20),
        const Text(
          "Couldn't scan :)",
          style: TextStyle(fontSize: 18, color: Colors.white),
        ),
        const SizedBox(height: 10),
        ElevatedButton(
          onPressed: () {
            // Navigate back to the HomeScreen to retry scanning.
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF007AFF),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          child: const Text("Scan Again"),
        ),
      ],
    );
  }
}
