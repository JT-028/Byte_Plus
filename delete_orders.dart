// delete_orders.dart
// Run with: dart run delete_orders.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  print('Initializing Firebase...');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final firestore = FirebaseFirestore.instance;

  try {
    print('\nSearching for orders with pickup numbers AQ9 and AQK...');

    // Get all stores to find coco store
    final storesSnapshot = await firestore.collection('stores').get();
    String? cocoStoreId;

    for (var storeDoc in storesSnapshot.docs) {
      final storeName =
          (storeDoc.data()['name'] ?? '').toString().toLowerCase();
      if (storeName.contains('coco')) {
        cocoStoreId = storeDoc.id;
        print('Found coco store: $cocoStoreId (${storeDoc.data()['name']})');
        break;
      }
    }

    if (cocoStoreId == null) {
      print('Error: Could not find coco store');
      return;
    }

    // Search for orders in store collection
    final storeOrdersSnapshot =
        await firestore
            .collection('stores')
            .doc(cocoStoreId)
            .collection('orders')
            .get();

    List<Map<String, dynamic>> ordersToDelete = [];

    for (var orderDoc in storeOrdersSnapshot.docs) {
      final orderId = orderDoc.id;
      // Generate pickup number from orderId (same logic as app)
      final pickupNumber =
          "A${orderId.length > 2 ? orderId.substring(orderId.length - 2).toUpperCase() : orderId.toUpperCase()}";

      if (pickupNumber == 'AQ9' || pickupNumber == 'AQK') {
        final orderData = orderDoc.data();
        ordersToDelete.add({
          'orderId': orderId,
          'pickupNumber': pickupNumber,
          'userId': orderData['userId'],
          'storeId': cocoStoreId,
          'status': orderData['status'],
          'total': orderData['total'],
        });
      }
    }

    if (ordersToDelete.isEmpty) {
      print('\nNo orders found with pickup numbers AQ9 or AQK');
      return;
    }

    print('\nFound ${ordersToDelete.length} order(s) to delete:');
    for (var order in ordersToDelete) {
      print('  - Pickup #${order['pickupNumber']} (ID: ${order['orderId']})');
      print('    Status: ${order['status']}, Total: ${order['total']}');
    }

    print('\nDeleting orders from all locations...');

    for (var order in ordersToDelete) {
      final orderId = order['orderId'];
      final userId = order['userId'];
      final storeId = order['storeId'];

      print('\nDeleting order $orderId (Pickup #${order['pickupNumber']})...');

      // Delete from store orders
      try {
        await firestore
            .collection('stores')
            .doc(storeId)
            .collection('orders')
            .doc(orderId)
            .delete();
        print('  ✓ Deleted from stores/$storeId/orders/$orderId');
      } catch (e) {
        print('  ✗ Failed to delete from store orders: $e');
      }

      // Delete from user orders
      if (userId != null && userId.toString().isNotEmpty) {
        try {
          await firestore
              .collection('users')
              .doc(userId)
              .collection('orders')
              .doc(orderId)
              .delete();
          print('  ✓ Deleted from users/$userId/orders/$orderId');
        } catch (e) {
          print('  ✗ Failed to delete from user orders: $e');
        }
      }

      // Delete from global orders
      try {
        await firestore.collection('orders').doc(orderId).delete();
        print('  ✓ Deleted from orders/$orderId');
      } catch (e) {
        print('  ✗ Failed to delete from global orders: $e');
      }
    }

    print('\n✅ Deletion complete!');
    print('Deleted ${ordersToDelete.length} order(s)');
  } catch (e) {
    print('❌ Error: $e');
  }
}
