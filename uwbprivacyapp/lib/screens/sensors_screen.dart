import 'package:flutter/material.dart';
import '../models/sensor.dart';
import '../services/api_service.dart';

class SensorsScreen extends StatefulWidget {
  const SensorsScreen({super.key});

  @override
  State<SensorsScreen> createState() => _SensorsScreenState();
}

class _SensorsScreenState extends State<SensorsScreen> {
  late Future<List<Sensor>> _sensorsFuture;

  @override
  void initState() {
    super.initState();
    _sensorsFuture = APIService(context).fetchConnectedSensors();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connected Sensors'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Sensor>>(
        future: _sensorsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No sensors found'));
          } else {
            return ListView.builder(
              itemCount: snapshot.data!.length,
              itemBuilder: (context, index) {
                final sensor = snapshot.data![index];
                return ListTile(
                  leading: const Icon(Icons.sensors),
                  title: Text(sensor.name),
                  subtitle: Text('Type: ${sensor.type}'),
                  trailing: Text('ID: ${sensor.id}'),
                );
              },
            );
          }
        },
      ),
    );
  }
}
