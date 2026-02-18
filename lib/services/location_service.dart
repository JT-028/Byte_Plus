import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

class LocationService {
  /// Requests permission and ensures location services are enabled
  static Future<bool> ensureLocationEnabled() async {
    // Ask for permission
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
      print("⚠️ Error getting position: $e");
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
