import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Debug page to inspect Firestore data directly
/// Navigate here to troubleshoot menu/store issues
class DebugFirestorePage extends StatefulWidget {
  const DebugFirestorePage({super.key});

  @override
  State<DebugFirestorePage> createState() => _DebugFirestorePageState();
}

class _DebugFirestorePageState extends State<DebugFirestorePage> {
  final List<String> _logs = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _runDebug();
  }

  void _log(String msg) {
    setState(() {
      _logs.add(msg);
    });
    debugPrint('[DEBUG] $msg');
  }

  Future<void> _runDebug() async {
    setState(() {
      _loading = true;
      _logs.clear();
    });

    final firestore = FirebaseFirestore.instance;

    try {
      _log('=== FIRESTORE DEBUG ===\n');

      // 1. Current user
      final currentUser = FirebaseAuth.instance.currentUser;
      _log('--- CURRENT USER ---');
      if (currentUser != null) {
        _log('UID: ${currentUser.uid}');
        _log('Email: ${currentUser.email}');

        final userDoc =
            await firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final data = userDoc.data()!;
          _log('Role: ${data['role']}');
          _log('storeId: "${data['storeId']}"');
          _log('firstName: ${data['firstName']}');
        } else {
          _log('⚠️ User document NOT FOUND in Firestore!');
        }
      } else {
        _log('⚠️ No user logged in');
      }

      // 2. All stores
      _log('\n--- ALL STORES ---');
      final storesSnap = await firestore.collection('stores').get();
      _log('Total stores: ${storesSnap.docs.length}');
      for (final store in storesSnap.docs) {
        final data = store.data();
        _log('  Store ID: "${store.id}" | Name: ${data['name']}');
      }

      // 3. Menu items for each store
      _log('\n--- MENU ITEMS PER STORE ---');
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

        _log(
          'Store "${store.id}": ${menuSnap.docs.length} items, ${catSnap.docs.length} categories',
        );

        if (menuSnap.docs.isNotEmpty) {
          for (final item in menuSnap.docs.take(3)) {
            final data = item.data();
            _log(
              '    - ${data['name']} (₱${data['price']}) cat: ${data['category']}',
            );
          }
          if (menuSnap.docs.length > 3) {
            _log('    ... and ${menuSnap.docs.length - 3} more');
          }
        }

        if (catSnap.docs.isNotEmpty) {
          _log(
            '  Categories: ${catSnap.docs.map((d) => d.data()['name']).join(', ')}',
          );
        }
      }

      // 4. Check current user's store specifically
      if (currentUser != null) {
        final userDoc =
            await firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          final storeId = userDoc.data()?['storeId']?.toString();
          if (storeId != null && storeId.isNotEmpty) {
            _log('\n--- CHECKING USER\'S STORE: "$storeId" ---');

            // Check if store exists
            final storeDoc =
                await firestore.collection('stores').doc(storeId).get();
            if (storeDoc.exists) {
              _log('✓ Store document exists');
              _log('  Store name: ${storeDoc.data()?['name']}');
            } else {
              _log('⚠️ Store document "$storeId" DOES NOT EXIST!');
              _log('  This is likely a case-sensitivity issue.');
              _log(
                '  Available store IDs: ${storesSnap.docs.map((d) => '"${d.id}"').join(', ')}',
              );
            }

            // Check menu for this exact storeId
            final menuSnap =
                await firestore
                    .collection('stores')
                    .doc(storeId)
                    .collection('menu')
                    .get();
            _log('  Menu items found: ${menuSnap.docs.length}');

            final catSnap =
                await firestore
                    .collection('stores')
                    .doc(storeId)
                    .collection('categories')
                    .get();
            _log('  Categories found: ${catSnap.docs.length}');
          } else {
            _log('\n⚠️ User has no storeId set!');
          }
        }
      }

      // 5. Staff users
      _log('\n--- STAFF USERS ---');
      final staffSnap =
          await firestore
              .collection('users')
              .where('role', isEqualTo: 'staff')
              .get();
      _log('Total staff: ${staffSnap.docs.length}');
      for (final staff in staffSnap.docs) {
        final data = staff.data();
        _log('  ${data['email']} -> storeId: "${data['storeId']}"');
      }

      _log('\n=== DEBUG COMPLETE ===');
    } catch (e, stack) {
      _log('\n❌ ERROR: $e');
      _log('Stack: $stack');
    }

    setState(() {
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Firestore Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loading ? null : _runDebug,
          ),
        ],
      ),
      body:
          _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  Color? color;
                  if (log.contains('⚠️')) color = Colors.orange;
                  if (log.contains('❌')) color = Colors.red;
                  if (log.contains('✓')) color = Colors.green;
                  if (log.startsWith('---')) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        log,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return Text(
                    log,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      color: color,
                    ),
                  );
                },
              ),
    );
  }
}
