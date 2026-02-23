# BytePlus Notification System

## Overview

The notification system enables real-time push notifications and in-app notifications for:

- **Students**: Order status updates (preparing, ready, completed, cancelled)
- **Merchants**: New order alerts

## Architecture

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│   Flutter App   │────▶│    Firestore    │────▶│ Cloud Function  │
│ (Client-side)   │     │  /notifications │     │ (Push delivery) │
└─────────────────┘     └─────────────────┘     └─────────────────┘
         │                                               │
         │                                               ▼
         │                                      ┌─────────────────┐
         │                                      │       FCM       │
         │                                      │ (Push Service)  │
         │                                      └─────────────────┘
         │                                               │
         └─────────────────◀───────────── Push ─────────┘
```

## Components

### 1. NotificationService (`lib/services/notification_service.dart`)

- Initializes FCM and local notifications
- Saves FCM tokens to user documents
- Creates notification documents in Firestore
- Handles foreground message display
- Provides streams for in-app notification UI

### 2. NotificationsPage (`lib/pages/notifications_page.dart`)

- Displays user's notifications
- Mark as read functionality
- Visual distinction for unread notifications

### 3. Cloud Function (`functions/index.js`)

- Triggers on new notification documents
- Retrieves user's FCM token
- Sends push notification via FCM
- Handles token invalidation

## Notification Flow

### New Order (Student → Merchant)

1. Student places order via `OrderService.placeOrder()`
2. `NotificationService.sendNewOrderNotification()` is called
3. Creates documents in:
   - `/users/{merchantId}/notifications` (in-app)
   - `/notifications` (for Cloud Function to process)
4. Cloud Function triggers and sends push to merchant

### Order Status Update (Merchant → Student)

1. Merchant updates order status
2. `NotificationService.sendOrderStatusNotification()` is called
3. Creates documents in:
   - `/users/{customerId}/notifications` (in-app)
   - `/notifications` (for Cloud Function to process)
4. Cloud Function triggers and sends push to student

## Setup Instructions

### 1. Deploy Cloud Functions

```bash
cd functions
npm install
firebase deploy --only functions
```

### 2. Firestore Security Rules

Add these rules to allow notification access:

```
match /users/{userId}/notifications/{notificationId} {
  allow read, write: if request.auth != null && request.auth.uid == userId;
}

match /notifications/{notificationId} {
  allow create: if request.auth != null;
  allow read: if request.auth != null && resource.data.userId == request.auth.uid;
}
```

### 3. Android Configuration

Ensure `android/app/src/main/AndroidManifest.xml` includes:

```xml
<uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
<uses-permission android:name="android.permission.RECEIVE_BOOT_COMPLETED"/>
```

### 4. iOS Configuration

Ensure push notification capabilities are enabled in Xcode:

1. Open `ios/Runner.xcworkspace`
2. Select Runner target
3. Go to Signing & Capabilities
4. Add "Push Notifications" capability
5. Add "Background Modes" and enable "Remote notifications"

## Testing

### Test In-App Notifications

1. As a student, place an order
2. Merchant should see notification bell badge update
3. Merchant taps bell to see notification list

### Test Push Notifications

1. Ensure FCM token is saved (check user document in Firestore)
2. Place an order or update order status
3. Check Cloud Functions logs: `firebase functions:log`
4. Verify push arrives on device (may need app in background)

## Troubleshooting

### Push not arriving

1. Check if FCM token exists in user document
2. Check Cloud Functions logs for errors
3. Ensure app has notification permissions
4. For iOS, check APNs configuration in Firebase Console

### In-app notifications not showing

1. Check Firestore rules allow reading from `/users/{uid}/notifications`
2. Verify notification documents are being created
3. Check NotificationService is initialized in main.dart

### Badge count not updating

1. Ensure `getUnreadCount()` stream is properly connected
2. Check Firestore query for `read == false`
