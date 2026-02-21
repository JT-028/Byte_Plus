// lib/services/order_archival_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to archive completed and cancelled orders daily
/// Archived orders are moved to a separate collection for analytics while
/// clearing the active orders list for each new day
class OrderArchivalService {
  static final OrderArchivalService _instance =
      OrderArchivalService._internal();
  factory OrderArchivalService() => _instance;
  OrderArchivalService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Check and archive yesterday's completed/cancelled orders for a store
  /// Should be called when the merchant opens the app
  Future<void> checkAndArchiveOrders(String storeId) async {
    try {
      // Get the last archival date
      final storeDoc = await _firestore.collection('stores').doc(storeId).get();
      final storeData = storeDoc.data() ?? {};
      final lastArchivalTimestamp =
          storeData['lastOrderArchival'] as Timestamp?;

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);

      // Check if we already archived today
      if (lastArchivalTimestamp != null) {
        final lastArchival = lastArchivalTimestamp.toDate();
        final lastArchivalDay = DateTime(
          lastArchival.year,
          lastArchival.month,
          lastArchival.day,
        );
        if (!lastArchivalDay.isBefore(todayStart)) {
          debugPrint('[OrderArchival] Already archived today');
          return;
        }
      }

      // Archive orders from before today
      await archiveOrdersBeforeDate(storeId, todayStart);

      // Update last archival date
      await _firestore.collection('stores').doc(storeId).update({
        'lastOrderArchival': Timestamp.now(),
      });

      debugPrint(
        '[OrderArchival] Successfully archived orders for store: $storeId',
      );
    } catch (e) {
      debugPrint('[OrderArchival] Error: $e');
    }
  }

  /// Archive all completed and cancelled orders before a given date
  Future<int> archiveOrdersBeforeDate(
    String storeId,
    DateTime beforeDate,
  ) async {
    int archivedCount = 0;

    try {
      final ordersRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders');

      final archivedRef = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('archivedOrders');

      // Get orders to archive (completed or cancelled, before today)
      final ordersToArchive =
          await ordersRef
              .where('timestamp', isLessThan: beforeDate)
              .where('status', whereIn: ['done', 'cancelled'])
              .get();

      if (ordersToArchive.docs.isEmpty) {
        debugPrint('[OrderArchival] No orders to archive');
        return 0;
      }

      // Use batch write for efficiency
      final batch = _firestore.batch();

      for (final doc in ordersToArchive.docs) {
        final data = doc.data();

        // Add to archived collection with archival metadata
        final archivedDocRef = archivedRef.doc(doc.id);
        batch.set(archivedDocRef, {
          ...data,
          'archivedAt': Timestamp.now(),
          'originalDocId': doc.id,
        });

        // Delete from active orders
        batch.delete(doc.reference);

        archivedCount++;
      }

      await batch.commit();
      debugPrint('[OrderArchival] Archived $archivedCount orders');
    } catch (e) {
      debugPrint('[OrderArchival] Error archiving orders: $e');
    }

    return archivedCount;
  }

  /// Get all orders (active + archived) for analytics within a date range
  Future<List<Map<String, dynamic>>> getAllOrdersForAnalytics(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final List<Map<String, dynamic>> allOrders = [];

    try {
      // Query active orders
      Query activeQuery = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('orders');

      if (startDate != null) {
        activeQuery = activeQuery.where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        activeQuery = activeQuery.where('timestamp', isLessThan: endDate);
      }

      final activeOrders = await activeQuery.get();
      for (final doc in activeOrders.docs) {
        allOrders.add({...doc.data() as Map<String, dynamic>, 'docId': doc.id});
      }

      // Query archived orders
      Query archivedQuery = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('archivedOrders');

      if (startDate != null) {
        archivedQuery = archivedQuery.where(
          'timestamp',
          isGreaterThanOrEqualTo: startDate,
        );
      }
      if (endDate != null) {
        archivedQuery = archivedQuery.where('timestamp', isLessThan: endDate);
      }

      final archivedOrders = await archivedQuery.get();
      for (final doc in archivedOrders.docs) {
        allOrders.add({
          ...doc.data() as Map<String, dynamic>,
          'docId': doc.id,
          'isArchived': true,
        });
      }
    } catch (e) {
      debugPrint('[OrderArchival] Error getting orders for analytics: $e');
    }

    return allOrders;
  }

  /// Get archived orders only (for historical reports)
  Future<List<Map<String, dynamic>>> getArchivedOrders(
    String storeId, {
    DateTime? startDate,
    DateTime? endDate,
    String? status,
  }) async {
    final List<Map<String, dynamic>> orders = [];

    try {
      Query query = _firestore
          .collection('stores')
          .doc(storeId)
          .collection('archivedOrders');

      if (startDate != null) {
        query = query.where('timestamp', isGreaterThanOrEqualTo: startDate);
      }
      if (endDate != null) {
        query = query.where('timestamp', isLessThan: endDate);
      }
      if (status != null) {
        query = query.where('status', isEqualTo: status);
      }

      final snapshot = await query.get();
      for (final doc in snapshot.docs) {
        orders.add({...doc.data() as Map<String, dynamic>, 'docId': doc.id});
      }
    } catch (e) {
      debugPrint('[OrderArchival] Error getting archived orders: $e');
    }

    return orders;
  }
}
