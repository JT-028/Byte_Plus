// debug_firestore.dart
// Run this with: dart run debug_firestore.dart
// Or use Firebase Admin SDK via Node.js if Dart doesn't work

import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'lib/firebase_options.dart';

Future<void> main() async {
  print('=== Firestore Debug Script ===\n');

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    print('✓ Firebase initialized\n');

    final firestore = FirebaseFirestore.instance;

    // 1. List all stores
    print('--- STORES ---');
    final storesSnap = await firestore.collection('stores').get();
    print('Total stores: ${storesSnap.docs.length}');
    for (final store in storesSnap.docs) {
      final data = store.data();
      print('  Store ID: "${store.id}"');
      print('    Name: ${data['name']}');
      print('    ---');
    }

    // 2. For each store, check menu items count
    print('\n--- MENU ITEMS PER STORE ---');
    for (final store in storesSnap.docs) {
      final menuSnap =
          await firestore
              .collection('stores')
              .doc(store.id)
              .collection('menu')
              .get();
      final catSnap =
          await firestore
              .collection('stores')
              .doc(store.id)
              .collection('categories')
              .get();
      print(
        '  Store "${store.id}": ${menuSnap.docs.length} menu items, ${catSnap.docs.length} categories',
      );

      if (menuSnap.docs.isNotEmpty) {
        print('    Sample items:');
        for (final item in menuSnap.docs.take(3)) {
          final data = item.data();
          print('      - ${data['name']} (₱${data['price']})');
        }
      }
    }

    // 3. List all staff users and their storeIds
    print('\n--- STAFF USERS ---');
    final usersSnap =
        await firestore
            .collection('users')
            .where('role', isEqualTo: 'staff')
            .get();
    print('Total staff users: ${usersSnap.docs.length}');
    for (final user in usersSnap.docs) {
      final data = user.data();
      print('  User ID: "${user.id}"');
      print('    Name: ${data['firstName']} ${data['lastName']}');
      print('    Email: ${data['email']}');
      print('    storeId: "${data['storeId']}"');
      print('    ---');
    }

    // 4. Check currently logged in user (if any)
    print('\n--- CURRENT AUTH USER ---');
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser != null) {
      print('  UID: ${currentUser.uid}');
      print('  Email: ${currentUser.email}');

      final userDoc =
          await firestore.collection('users').doc(currentUser.uid).get();
      if (userDoc.exists) {
        final data = userDoc.data()!;
        print('  Role: ${data['role']}');
        print('  storeId: "${data['storeId']}"');

        // Check if this storeId exists
        final storeId = data['storeId']?.toString();
        if (storeId != null && storeId.isNotEmpty) {
          final storeDoc =
              await firestore.collection('stores').doc(storeId).get();
          print('  Store exists: ${storeDoc.exists}');

          if (storeDoc.exists) {
            final menuCount =
                await firestore
                    .collection('stores')
                    .doc(storeId)
                    .collection('menu')
                    .get();
            print('  Menu items in this store: ${menuCount.docs.length}');
          }
        }
      }
    } else {
      print('  No user logged in');
    }

    print('\n=== Debug Complete ===');
  } catch (e, stack) {
    print('ERROR: $e');
    print(stack);
  }
}
