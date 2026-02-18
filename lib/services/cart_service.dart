// lib/services/cart_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CartService {
  static final _firestore = FirebaseFirestore.instance;

  /// Returns the `/users/{uid}/cartItems` collection
  static CollectionReference get _cartRef {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return _firestore.collection('users').doc(uid).collection('cartItems');
  }

  // ----------------------------------------------------------
  // ADD ITEM TO CART  (UPDATED WITH storeName + storeLogo)
  // ----------------------------------------------------------
  static Future<void> addToCart({
    required String storeId,
    required String storeName,      // ✅ NEW
    required String storeLogo,      // ✅ NEW

    required String productId,
    required String productName,
    required String imageUrl,
    required double basePrice,
    required String sizeName,
    required double sizePrice,
    required String sugarLevel,
    required String iceLevel,
    required List<Map<String, dynamic>> toppings,
    required double toppingsTotal,
    required String note,
    required int quantity,
    required double lineTotal,
  }) async {
    try {
      await _cartRef.add({
        "storeId": storeId,
        "storeName": storeName,     // ✅ STORED NOW
        "storeLogo": storeLogo,     // ✅ STORED NOW

        "productId": productId,
        "productName": productName,
        "imageUrl": imageUrl,

        "basePrice": basePrice,
        "sizeName": sizeName,
        "sizePrice": sizePrice,

        "sugarLevel": sugarLevel,
        "iceLevel": iceLevel,

        "toppings": toppings,
        "toppingsTotal": toppingsTotal,

        "note": note,
        "quantity": quantity,
        "lineTotal": lineTotal,

        "createdAt": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception("Failed to add item to cart: $e");
    }
  }

  // ----------------------------------------------------------
  // UPDATE QUANTITY
  // ----------------------------------------------------------
  static Future<void> updateQuantity({
    required String itemId,
    required int newQuantity,
    required double unitPrice,
  }) async {
    final ref = _cartRef.doc(itemId);

    if (newQuantity <= 0) {
      await ref.delete();
      return;
    }

    await ref.update({
      "quantity": newQuantity,
      "lineTotal": newQuantity * unitPrice,
    });
  }

  // ----------------------------------------------------------
  // DELETE 1 ITEM
  // ----------------------------------------------------------
  static Future<void> deleteItem(String itemId) async {
    await _cartRef.doc(itemId).delete();
  }

  // ----------------------------------------------------------
  // CLEAR ENTIRE CART
  // ----------------------------------------------------------
  static Future<void> clearCart() async {
    final snap = await _cartRef.get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }

  // ----------------------------------------------------------
  // STREAM CART ITEMS
  // ----------------------------------------------------------
  static Stream<QuerySnapshot> streamCart() {
    return _cartRef.orderBy("createdAt", descending: false).snapshots();
  }

  // ----------------------------------------------------------
  // STREAM CART FOR SPECIFIC STORE
  // ----------------------------------------------------------
  static Stream<QuerySnapshot> streamCartForStore(String storeId) {
    return _cartRef
        .where("storeId", isEqualTo: storeId)
        .orderBy("createdAt", descending: false)
        .snapshots();
  }
}
