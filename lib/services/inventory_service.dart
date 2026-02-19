// lib/services/inventory_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service for managing product inventory and availability.
/// Provides methods to toggle availability and check stock status.
class InventoryService {
  static final _firestore = FirebaseFirestore.instance;

  /// Toggle product availability (in-stock / out-of-stock)
  static Future<void> toggleProductAvailability({
    required String storeId,
    required String productId,
    required bool isAvailable,
  }) async {
    await _firestore
        .collection('stores')
        .doc(storeId)
        .collection('menu')
        .doc(productId)
        .update({
          'isAvailable': isAvailable,
          'availabilityUpdatedAt': FieldValue.serverTimestamp(),
        });
  }

  /// Set all products in a category to unavailable
  static Future<void> setCategoryAvailability({
    required String storeId,
    required String category,
    required bool isAvailable,
  }) async {
    final batch = _firestore.batch();

    final products =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .where('category', arrayContains: category)
            .get();

    for (var doc in products.docs) {
      batch.update(doc.reference, {
        'isAvailable': isAvailable,
        'availabilityUpdatedAt': FieldValue.serverTimestamp(),
      });
    }

    await batch.commit();
  }

  /// Get availability status for a product
  static Future<bool> isProductAvailable({
    required String storeId,
    required String productId,
  }) async {
    final doc =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .doc(productId)
            .get();

    if (!doc.exists) return false;

    final data = doc.data() as Map<String, dynamic>;
    // Default to available if field doesn't exist
    return data['isAvailable'] ?? true;
  }

  /// Get count of available vs unavailable products for a store
  static Future<Map<String, int>> getInventorySummary(String storeId) async {
    final products =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .get();

    int available = 0;
    int unavailable = 0;

    for (var doc in products.docs) {
      final data = doc.data();
      final isAvailable = data['isAvailable'] ?? true;
      if (isAvailable) {
        available++;
      } else {
        unavailable++;
      }
    }

    return {
      'available': available,
      'unavailable': unavailable,
      'total': available + unavailable,
    };
  }

  /// Stream of products with availability filter
  static Stream<QuerySnapshot> streamProducts({
    required String storeId,
    bool? filterAvailable,
  }) {
    Query query = _firestore
        .collection('stores')
        .doc(storeId)
        .collection('menu');

    if (filterAvailable != null) {
      query = query.where('isAvailable', isEqualTo: filterAvailable);
    }

    return query.snapshots();
  }
}
