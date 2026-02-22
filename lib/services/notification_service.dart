// lib/services/notification_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service for handling push notifications.
/// Manages FCM tokens, local notifications, and order status alerts.
class NotificationService {
  static final _firestore = FirebaseFirestore.instance;
  static final _messaging = FirebaseMessaging.instance;
  static FlutterLocalNotificationsPlugin? _localNotifications;

  /// Initialize notification service
  static Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(alert: true, badge: true, sound: true);

    // Initialize local notifications for foreground
    _localNotifications = FlutterLocalNotificationsPlugin();

    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications?.initialize(settings);

    // Handle foreground messages
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);
  }

  /// Handle foreground message by showing local notification
  static Future<void> _handleForegroundMessage(RemoteMessage message) async {
    final notification = message.notification;
    if (notification == null) return;

    const androidDetails = AndroidNotificationDetails(
      'byteplus_orders',
      'Order Updates',
      channelDescription: 'Notifications for order status updates',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications?.show(
      message.hashCode,
      notification.title,
      notification.body,
      details,
    );
  }

  /// Save FCM token to user document
  static Future<void> saveFcmToken(String userId) async {
    try {
      final token = await _messaging.getToken();
      if (token != null) {
        await _firestore.collection('users').doc(userId).update({
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      }

      // Listen for token refresh
      _messaging.onTokenRefresh.listen((newToken) {
        _firestore.collection('users').doc(userId).update({
          'fcmToken': newToken,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      debugPrint('Error saving FCM token: $e');
    }
  }

  /// Create a notification document for Cloud Function to process
  /// This allows server-side push notification sending
  static Future<void> sendOrderStatusNotification({
    required String orderId,
    required String storeId,
    required String customerId,
    required String status,
    required String storeName,
    String? pickupNumber,
    String? cancelReason,
  }) async {
    final title = _getNotificationTitle(status);
    final body = _getNotificationBody(
      status,
      storeName,
      pickupNumber,
      cancelReason,
    );

    // Store notification request for Cloud Function to process
    await _firestore.collection('notifications').add({
      'type': 'order_status',
      'orderId': orderId,
      'storeId': storeId,
      'userId': customerId,
      'status': status,
      'title': title,
      'body': body,
      'read': false,
      'sent': false,
      'createdAt': FieldValue.serverTimestamp(),
    });

    // Also store in user's notifications subcollection for in-app display
    await _firestore
        .collection('users')
        .doc(customerId)
        .collection('notifications')
        .add({
          'type': 'order_status',
          'orderId': orderId,
          'title': title,
          'body': body,
          'read': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
  }

  static String _getNotificationTitle(String status) {
    switch (status) {
      case 'in-progress':
        return '🍳 Order Being Prepared';
      case 'ready':
        return '✅ Order Ready for Pickup!';
      case 'done':
        return '🎉 Order Completed';
      case 'cancelled':
        return '❌ Order Cancelled';
      default:
        return '📋 Order Update';
    }
  }

  static String _getNotificationBody(
    String status,
    String storeName,
    String? pickupNumber, [
    String? cancelReason,
  ]) {
    switch (status) {
      case 'in-progress':
        return 'Your order at $storeName is now being prepared.';
      case 'ready':
        final pickup = pickupNumber != null ? ' Pickup #$pickupNumber' : '';
        return 'Your order at $storeName is ready!$pickup';
      case 'done':
        return 'Thank you for ordering at $storeName!';
      case 'cancelled':
        final reason =
            cancelReason != null && cancelReason.isNotEmpty
                ? ' Reason: $cancelReason'
                : '';
        return 'Your order at $storeName has been cancelled.$reason';
      default:
        return 'Your order status has been updated.';
    }
  }

  /// Get unread notification count for badge
  static Stream<int> getUnreadCount(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .snapshots()
        .map((snap) => snap.docs.length);
  }

  /// Mark notification as read
  static Future<void> markAsRead(String userId, String notificationId) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .update({'read': true});
  }

  /// Mark all notifications as read
  static Future<void> markAllAsRead(String userId) async {
    final batch = _firestore.batch();

    final unread =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('read', isEqualTo: false)
            .get();

    for (var doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }

    await batch.commit();
  }

  /// Delete a single notification
  static Future<void> deleteNotification(
    String userId,
    String notificationId,
  ) async {
    await _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .doc(notificationId)
        .delete();
  }

  /// Delete all read notifications
  static Future<int> deleteAllReadNotifications(String userId) async {
    final batch = _firestore.batch();

    final readNotifications =
        await _firestore
            .collection('users')
            .doc(userId)
            .collection('notifications')
            .where('read', isEqualTo: true)
            .get();

    for (var doc in readNotifications.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();
    return readNotifications.docs.length;
  }

  /// Send notification to merchant when a new order is placed
  static Future<void> sendNewOrderNotification({
    required String storeId,
    required String storeName,
    required String orderId,
    required String queueNo,
    required double total,
    required String customerName,
  }) async {
    try {
      // Find the merchant(s) associated with this store
      final merchantsQuery =
          await _firestore
              .collection('users')
              .where('storeId', isEqualTo: storeId)
              .where('role', isEqualTo: 'staff')
              .get();

      if (merchantsQuery.docs.isEmpty) {
        debugPrint('No merchants found for store: $storeId');
        return;
      }

      final title = '🛒 New Order #$queueNo';
      final body =
          'New order from ${customerName.isNotEmpty ? customerName : 'Customer'} - ₱${total.toStringAsFixed(2)}';

      // Send notification to each merchant
      for (final merchantDoc in merchantsQuery.docs) {
        final merchantId = merchantDoc.id;

        // Store in user's notifications subcollection for in-app display
        await _firestore
            .collection('users')
            .doc(merchantId)
            .collection('notifications')
            .add({
              'type': 'new_order',
              'orderId': orderId,
              'storeId': storeId,
              'queueNo': queueNo,
              'title': title,
              'body': body,
              'read': false,
              'createdAt': FieldValue.serverTimestamp(),
            });

        // Store notification request for Cloud Function to process push
        await _firestore.collection('notifications').add({
          'type': 'new_order',
          'orderId': orderId,
          'storeId': storeId,
          'userId': merchantId,
          'queueNo': queueNo,
          'title': title,
          'body': body,
          'read': false,
          'sent': false,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint('Error sending new order notification: $e');
    }
  }

  /// Get notifications stream for in-app notifications list
  static Stream<QuerySnapshot> getNotificationsStream(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('notifications')
        .orderBy('createdAt', descending: true)
        .limit(50)
        .snapshots();
  }
}
