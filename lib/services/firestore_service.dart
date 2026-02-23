import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getGeofenceSettings() async {
    try {
      final DocumentSnapshot snapshot =
          await _firestore.collection('geofence').doc('campus').get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        debugPrint("⚠️ Firestore document 'geofence/campus' not found.");
        return null;
      }
    } catch (e) {
      debugPrint("🔥 Firestore error: $e");
      return null;
    }
  }
}

