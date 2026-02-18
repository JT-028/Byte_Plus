import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getGeofenceData() async {
    try {
      final DocumentSnapshot snapshot =
          await _firestore.collection('geofence').doc('school').get();

      if (snapshot.exists) {
        return snapshot.data() as Map<String, dynamic>;
      } else {
        print("⚠️ Firestore document 'geofence/school' not found.");
        return null;
      }
    } catch (e) {
      print("🔥 Firestore error: $e");
      return null;
    }
  }
}
