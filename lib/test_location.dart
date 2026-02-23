import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class TestLocationPage extends StatefulWidget {
  const TestLocationPage({super.key});

  @override
  State<TestLocationPage> createState() => _TestLocationPageState();
}

class _TestLocationPageState extends State<TestLocationPage> {
  String _status = 'Checking...';

  @override
  void initState() {
    super.initState();
    _checkLocation();
  }

  Future<void> _checkLocation() async {
    try {
      // Step 1: check if location services are enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _status = '❌ Location services are disabled.');
        await Geolocator.openLocationSettings();
        return;
      }

      // Step 2: check and request permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() => _status = '🚫 Permission permanently denied.');
        await Geolocator.openAppSettings();
        return;
      }

      if (permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse) {
        // Step 3: get location
        Position pos = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.high);

        setState(() {
          _status =
              '✅ Location granted!\n\nLat: ${pos.latitude}\nLng: ${pos.longitude}\nAccuracy: ${pos.accuracy} m';
        });
      } else {
        setState(() => _status = '⚠️ Permission not granted.');
      }
    } catch (e) {
      setState(() => _status = '❗ Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Location Test')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Text(
            _status,
            style: const TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _checkLocation,
        child: const Icon(Icons.refresh),
      ),
    );
  }
}

