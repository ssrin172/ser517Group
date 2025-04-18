import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';
import 'sensors_screen.dart';

class LoadingScreen extends StatefulWidget {
  /// If true, immediately show the error state with this message
  final bool initialShowError;
  final String initialErrorMessage;

  const LoadingScreen({
    super.key,
    this.initialShowError = false,
    this.initialErrorMessage = '',
  });

  @override
  State<LoadingScreen> createState() => _LoadingScreenState();
}

class _LoadingScreenState extends State<LoadingScreen> {
  late final UWBService _uwbService;
  Timer? _timeoutTimer;
  bool _showError = false;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _uwbService = Provider.of<UWBService>(context, listen: false);

    // If we're not starting in error, kick off a scan + timeout
    if (!widget.initialShowError) {
      _uwbService.startScanning();
      _timeoutTimer = Timer(const Duration(seconds: 20), () {
        if (!_uwbService.isConnected) {
          setState(() {
            _showError = true;
            _errorMessage = 'Couldn’t scan';
          });
        }
      });
      _uwbService.addListener(_serviceListener);
    } else {
      // immediate error state
      _showError = true;
      _errorMessage = widget.initialErrorMessage;
    }
  }

  void _serviceListener() {
    if (_uwbService.isConnected) {
      _timeoutTimer?.cancel();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const SensorsScreen()),
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
        Text(
          widget.initialShowError ? _errorMessage : "Couldn't scan :)",
          style: const TextStyle(fontSize: 18, color: Colors.white),
          textAlign: TextAlign.center,
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
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
          ),
          child: const Text("Scan Again"),
        ),
      ],
    );
  }
}
