import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'UWB Check',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const UwbCheckPage(),
    );
  }
}

class UwbCheckPage extends StatefulWidget {
  const UwbCheckPage({Key? key}) : super(key: key);

  @override
  _UwbCheckPageState createState() => _UwbCheckPageState();
}

class _UwbCheckPageState extends State<UwbCheckPage> {
  static const platform = MethodChannel('com.example.uwb/channel');
  String _uwbStatus = 'Unknown';

  Future<void> _checkUwbSupport() async {
    try {
      final String result = await platform.invokeMethod('checkUWB');
      setState(() {
        _uwbStatus = result;
      });
    } catch (e) {
      setState(() {
        _uwbStatus = 'Failed to get UWB status: ${e.toString()}';
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _checkUwbSupport();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('UWB Support Checker')),
      body: Center(child: Text('UWB Status: $_uwbStatus')),
    );
  }
}
