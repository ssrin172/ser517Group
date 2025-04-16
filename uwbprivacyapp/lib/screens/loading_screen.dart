import 'dart:async';
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
  late final UWBService _uwbService;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _uwbService = Provider.of<UWBService>(context, listen: false);

    // Start scanning immediately.
    _uwbService.startScanning();

    // Set a longer timeout (for example, 20 seconds) before showing error.
    _timeoutTimer = Timer(const Duration(seconds: 20), () {
      // If even after 20 seconds there is no valid connection, then show error.
      if (!_uwbService.isConnected) {
        setState(() {
          _showError = true;
        });
      }
    });

    // Listen for changes in the UWBService.
    _uwbService.addListener(_serviceListener);
  }

  void _serviceListener() {
    if (_uwbService.isConnected) {
      // Only checking _isConnected is sufficient now
      _timeoutTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const SensorsScreen()),
      );
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _uwbService.removeListener(_serviceListener);
    super.dispose();
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
