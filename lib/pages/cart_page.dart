// lib/pages/cart_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/order_service.dart';
import '../widgets/app_modal_dialog.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _placing = false;

  // temporary defaults (keep compatible with your future pickup UI)
  final bool _pickupNow = true;
  DateTime? _pickupTime;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          "Your Cart",
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection("cartItems")
                .orderBy("createdAt", descending: false)
                .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("Your cart is empty."));
          }

          final docs = snap.data!.docs;

          double total = 0;
          for (var d in docs) {
            final lt = d.get('lineTotal');
            if (lt is num) total += lt.toDouble();
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final data = docs[i].data() as Map<String, dynamic>;
                    final id = docs[i].id;

                    return Container(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(
                              isDark ? 0.2 : 0.06,
                            ),
                            blurRadius: 6,
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Image.network(
                            (data['imageUrl'] ?? '').toString(),
                            width: 60,
                            height: 60,
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) =>
                                    const Icon(Icons.image_not_supported),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  (data['productName'] ?? '').toString(),
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                Text(
                                  "₱ ${(data['sizePrice'] ?? 0).toString()}",
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                  ),
                                ),
                                if (((data['sizeName'] ?? "").toString())
                                    .isNotEmpty)
                                  Text(
                                    "Size: ${data['sizeName']}",
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                    ),
                                  ),
                                Text(
                                  "Qty: ${(data['quantity'] ?? 1).toString()}",
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.delete,
                              color:
                                  isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary,
                            ),
                            onPressed: () async {
                              await FirebaseFirestore.instance
                                  .collection("users")
                                  .doc(uid)
                                  .collection("cartItems")
                                  .doc(id)
                                  .delete();
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // -------- BOTTOM TOTAL BAR ----------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "₱ ${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _placing
                              ? null
                              : () async {
                                await _placeOrder(
                                  uid: uid,
                                  cartDocs: docs,
                                  total: total,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _placing
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Place Order",
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _placeOrder({
    required String uid,
    required List<QueryDocumentSnapshot> cartDocs,
    required double total,
  }) async {
    setState(() => _placing = true);

    try {
      final items =
          cartDocs.map((d) => (d.data() as Map<String, dynamic>)).toList();
      final first = items.isNotEmpty ? items.first : <String, dynamic>{};

      final storeId = (first['storeId'] ?? "").toString();
      final storeName = (first['storeName'] ?? storeId).toString();

      if (storeId.isEmpty) {
        throw Exception("Missing storeId in cart items.");
      }

      final orderId = await OrderService().placeOrder(
        storeId: storeId,
        storeName: storeName,
        items: items,
        total: total,
        pickupNow: _pickupNow,
        pickupTime: _pickupTime,
      );

      // Clear cart after success
      final batch = FirebaseFirestore.instance.batch();
      for (final d in cartDocs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      if (!mounted) return;
      await AppModalDialog.success(
        context: context,
        title: 'Order Successful!',
        message: 'Your order #$orderId has been placed.',
        primaryLabel: 'OK',
        onPrimaryPressed: () {
          Navigator.pop(context);
        },
      );
    } catch (e) {
      if (!mounted) return;
      await AppModalDialog.error(
        context: context,
        title: 'Order Failed',
        message: 'Failed to place order: $e',
      );
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}
