// lib/main.dart
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'firebase_options.dart';

// Screens
import 'pages/login_page.dart';
import 'pages/user_shell.dart';
import 'pages/admin_shell.dart';
import 'pages/merchant_shell.dart';

// Geofence
import 'services/location_guard.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // ignore: avoid_print
  print("🔔 BG: ${message.notification?.title} - ${message.notification?.body}");
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // FCM setup
  final messaging = FirebaseMessaging.instance;
  await messaging.requestPermission(alert: true, badge: true, sound: true);
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  void _initForegroundFCM() {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      // ignore: avoid_print
      print("🔔 FG: ${message.notification?.title} - ${message.notification?.body}");
    });
  }

  Future<void> _saveFcmTokenToUserDoc(User user) async {
    final token = await FirebaseMessaging.instance.getToken();
    if (token == null) return;

    await FirebaseFirestore.instance.collection("users").doc(user.uid).set(
      {"fcmToken": token},
      SetOptions(merge: true),
    );
  }

  @override
  void initState() {
    super.initState();
    _initForegroundFCM();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Byte Plus',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(primarySwatch: Colors.orange),

      // ✅ Auth changes drive the entire app
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, authSnap) {
          if (authSnap.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator(color: Colors.orange)),
            );
          }

          final user = authSnap.data;
          if (user == null) return const LoginPage();

          // ✅ Live role routing (updates if Firestore role changes)
          return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance.collection('users').doc(user.uid).snapshots(),
            builder: (context, userDocSnap) {
              if (userDocSnap.connectionState == ConnectionState.waiting) {
                return const Scaffold(
                  body: Center(child: CircularProgressIndicator(color: Colors.orange)),
                );
              }

              if (!userDocSnap.hasData || !userDocSnap.data!.exists) {
                return const Scaffold(
                  body: Center(child: Text("User profile doc not found in Firestore.")),
                );
              }

              final data = userDocSnap.data!.data() ?? {};
              final role = (data['role'] ?? 'student').toString().trim().toLowerCase();

              // ignore: avoid_print
              print("✅ ROUTING UID=${user.uid} role='$role' storeId='${data['storeId']}'");

              // Save token (safe even if repeated)
              _saveFcmTokenToUserDoc(user);

              Widget home;
              if (role == 'admin') {
                home = const AdminShell();
              } else if (role == 'staff') {
                home = const MerchantShell();
              } else {
                home = const UserShell();
              }

              return LocationGuard(
                useMock: true,
                mockLat: 15.1161836,
                mockLng: 120.6343,
                child: home,
              );
            },
          );
        },
      ),
    );
  }
}
