import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/uwb_service.dart';
import 'loading_screen.dart'; // Import the new loading screen.
import '../widgets/background_scaffold.dart'; // import the custom scaffold

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

    return BackgroundScaffold(
      appBar: AppBar(
        title: const Text(
          'SENSA',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        centerTitle: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: CircleAvatar(
              radius: 20,
              backgroundImage:
                  const AssetImage("assets/images/user_avatar.png"),
            ),
          ),
        ],
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Greeting texts can be added here as desired.
              const Text(
                "Good evening,",
                style: TextStyle(fontSize: 22, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8.0),
              const Text(
                "HI PRANUT JAIN !",
                style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 30),
              // Replace the sensor icon with an image asset.
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Image.asset(
                  'assets/images/sensor_logo.png',
                  width: 150,
                  height: 150,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 30),
              Text(
                _statusMessage,
                style: const TextStyle(fontSize: 18, color: Colors.white),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              if (!_isSearching && !uwbService.isConnected)
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      PageRouteBuilder(
                        pageBuilder: (context, animation, secondaryAnimation) =>
                            const LoadingScreen(),
                        transitionsBuilder:
                            (context, animation, secondaryAnimation, child) {
                          // Use a FadeTransition for smooth fading
                          return FadeTransition(
                            opacity: animation,
                            child: child,
                          );
                        },
                        transitionDuration: const Duration(milliseconds: 500),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF007AFF),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 40, vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
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
