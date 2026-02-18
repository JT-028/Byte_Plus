// lib/services/order_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class OrderService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// A01..A99..B01..Z99..AA01.. etc
  String _indexToLetters(int index) {
    String result = "";
    while (index >= 0) {
      final remainder = index % 26;
      result = String.fromCharCode(65 + remainder) + result;
      index = (index ~/ 26) - 1;
    }
    return result;
  }

  /// Reads/updates config/orderCounter in a transaction and returns queueNo.
  Future<String> _nextQueueNo() async {
    final ref = _db.collection("config").doc("orderCounter");

    return _db.runTransaction((tx) async {
      final snap = await tx.get(ref);

      int number = 1;
      int seq = 0; // 0=A, 1=B, ... 25=Z, 26=AA...

      if (snap.exists) {
        final data = snap.data() as Map<String, dynamic>;
        number = (data["number"] is int) ? data["number"] as int : 1;
        seq = (data["seq"] is int) ? data["seq"] as int : 0;
      }

      // current
      final prefix = _indexToLetters(seq);
      final queueNo = "$prefix${number.toString().padLeft(2, '0')}";

      // next
      int nextNumber = number + 1;
      int nextSeq = seq;

      if (nextNumber > 99) {
        nextNumber = 1;
        nextSeq = seq + 1;
      }

      tx.set(ref, {
        "number": nextNumber,
        "seq": nextSeq,
        "prefix": _indexToLetters(nextSeq), // optional convenience
      }, SetOptions(merge: true));

      return queueNo;
    });
  }

  Future<String> placeOrder({
    required String storeId,
    required String storeName,
    required List<Map<String, dynamic>> items,
    required double total,
    required bool pickupNow,
    DateTime? pickupTime,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception("Not logged in");

    final uid = user.uid;

    // ✅ Generate queueNo safely
    final queueNo = await _nextQueueNo();

    // ✅ Use ONE firestore doc id everywhere
    final globalRef = _db.collection("orders").doc();
    final orderDocId = globalRef.id;

    final orderData = <String, dynamic>{
      "orderId":
          orderDocId, // keep for compatibility (but docId is the real id)
      "queueNo": queueNo, // ✅ the A01 / B02 / AA01 value shown in UI
      "userId": uid,
      "userName": user.displayName ?? "",
      "userEmail": user.email ?? "",
      "storeId": storeId,
      "storeName": storeName,
      "items": items,
      "total": total,
      "status": "to-do",
      "pickupNow": pickupNow,
      "pickupTime": pickupTime?.toIso8601String(),
      "timestamp": FieldValue.serverTimestamp(),
    };

    final batch = _db.batch();

    batch.set(globalRef, orderData);
    batch.set(
      _db.collection("users").doc(uid).collection("orders").doc(orderDocId),
      orderData,
    );
    batch.set(
      _db
          .collection("stores")
          .doc(storeId)
          .collection("orders")
          .doc(orderDocId),
      orderData,
    );

    await batch.commit();

    return queueNo;
  }
}
