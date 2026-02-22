/**
 * BytePlus Firebase Cloud Functions
 * 
 * This Cloud Function listens for new notification documents and sends
 * push notifications to users via Firebase Cloud Messaging (FCM).
 * 
 * SETUP INSTRUCTIONS:
 * 1. Install Firebase CLI: npm install -g firebase-tools
 * 2. Login to Firebase: firebase login
 * 3. Initialize functions: firebase init functions (select your project)
 * 4. Copy this file to functions/index.js
 * 5. Install dependencies: cd functions && npm install
 * 6. Deploy: firebase deploy --only functions
 */

const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

/**
 * Trigger: When a new notification document is created in /notifications
 * Action: Send push notification to the user via FCM
 */
exports.sendPushNotification = functions.firestore
  .document('notifications/{notificationId}')
  .onCreate(async (snap, context) => {
    const notification = snap.data();
    const notificationId = context.params.notificationId;

    // Skip if already sent
    if (notification.sent) {
      console.log(`Notification ${notificationId} already sent, skipping.`);
      return null;
    }

    const userId = notification.userId;
    if (!userId) {
      console.error('No userId in notification document');
      return null;
    }

    try {
      // Get user's FCM token
      const userDoc = await db.collection('users').doc(userId).get();
      
      if (!userDoc.exists) {
        console.error(`User ${userId} not found`);
        return null;
      }

      const userData = userDoc.data();
      const fcmToken = userData.fcmToken;

      if (!fcmToken) {
        console.log(`User ${userId} has no FCM token, skipping push.`);
        // Mark as sent to avoid retrying
        await snap.ref.update({ sent: true, sentAt: admin.firestore.FieldValue.serverTimestamp() });
        return null;
      }

      // Build the FCM message
      const message = {
        token: fcmToken,
        notification: {
          title: notification.title || 'BytePlus',
          body: notification.body || 'You have a new notification',
        },
        data: {
          type: notification.type || 'general',
          orderId: notification.orderId || '',
          storeId: notification.storeId || '',
          click_action: 'FLUTTER_NOTIFICATION_CLICK',
        },
        android: {
          priority: 'high',
          notification: {
            channelId: 'byteplus_orders',
            priority: 'high',
            defaultSound: true,
          },
        },
        apns: {
          payload: {
            aps: {
              sound: 'default',
              badge: 1,
            },
          },
        },
      };

      // Send the push notification
      const response = await messaging.send(message);
      console.log(`Successfully sent notification to ${userId}:`, response);

      // Mark as sent
      await snap.ref.update({
        sent: true,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        fcmResponse: response,
      });

      return response;

    } catch (error) {
      console.error(`Error sending notification to ${userId}:`, error);
      
      // If token is invalid, remove it from user document
      if (error.code === 'messaging/invalid-registration-token' ||
          error.code === 'messaging/registration-token-not-registered') {
        console.log(`Removing invalid FCM token for user ${userId}`);
        await db.collection('users').doc(userId).update({
          fcmToken: admin.firestore.FieldValue.delete(),
        });
      }

      // Mark as failed
      await snap.ref.update({
        sent: false,
        error: error.message,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return null;
    }
  });

/**
 * Optional: Clean up old notifications (older than 30 days)
 * Runs daily at midnight
 */
exports.cleanupOldNotifications = functions.pubsub
  .schedule('0 0 * * *')
  .timeZone('Asia/Manila')
  .onRun(async (context) => {
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

    const query = db.collection('notifications')
      .where('createdAt', '<', thirtyDaysAgo)
      .limit(500);

    const snapshot = await query.get();

    if (snapshot.empty) {
      console.log('No old notifications to clean up.');
      return null;
    }

    const batch = db.batch();
    snapshot.docs.forEach(doc => {
      batch.delete(doc.ref);
    });

    await batch.commit();
    console.log(`Deleted ${snapshot.docs.length} old notifications.`);

    return null;
  });

/**
 * Optional: Update badge count when notifications are read
 * This can be called from client side to sync badge count
 */
exports.syncBadgeCount = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in');
  }

  const userId = context.auth.uid;

  const unreadQuery = await db.collection('users')
    .doc(userId)
    .collection('notifications')
    .where('read', '==', false)
    .get();

  return { unreadCount: unreadQuery.docs.length };
});
