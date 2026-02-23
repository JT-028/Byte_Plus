import 'package:flutter/foundation.dart' show debugPrint, kIsWeb;
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Requests permission and ensures location services are enabled
  static Future<bool> ensureLocationEnabled() async {
    // On web, use Geolocator's permission handling
    if (kIsWeb) {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        final result = await Geolocator.requestPermission();
        return result == LocationPermission.always ||
            result == LocationPermission.whileInUse;
      }
      return permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }

    // Mobile platforms: use permission_handler
    var permission = await Permission.location.request();

    if (permission.isDenied || permission.isPermanentlyDenied) {
      return false;
    }

    // Ensure location services are active
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    return true;
  }

  /// Get the current GPS position
  static Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint("⚠️ Error getting position: $e");
      return null;
    }
  }

  /// Returns distance in meters between two coordinates
  static double calculateDistance({
    required double startLat,
    required double startLng,
    required double endLat,
    required double endLng,
  }) {
    return Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
  }
}

