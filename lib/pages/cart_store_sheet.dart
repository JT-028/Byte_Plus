// lib/pages/cart_store_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

class CartStoreSheet extends StatefulWidget {
  final String storeId;
  final VoidCallback? onGoToCheckout;

  const CartStoreSheet({super.key, required this.storeId, this.onGoToCheckout});

  @override
  State<CartStoreSheet> createState() => _CartStoreSheetState();
}

class _CartStoreSheetState extends State<CartStoreSheet> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.40,
      builder: (_, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ---- BLUE TOP BAR / DRAG HANDLE ----
              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),

              // ------------ TITLE ---------------
              Text(
                "Your Items",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream:
                      FirebaseFirestore.instance
                          .collection("users")
                          .doc(uid)
                          .collection("cartItems")
                          .where("storeId", isEqualTo: widget.storeId)
                          .snapshots(),
                  builder: (_, snap) {
                    if (!snap.hasData) {
                      return Center(
                        child: CircularProgressIndicator(
                          color: AppColors.primary,
                        ),
                      );
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return Center(
                        child: Text(
                          "No items in your cart.",
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        return _cartRow(docs[i], isDark);
                      },
                    );
                  },
                ),
              ),

              // ----------- CHECKOUT BAR -----------
              _checkoutBar(isDark),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CART ROW WIDGET
  // ============================================================
  Widget _cartRow(QueryDocumentSnapshot cartDoc, bool isDark) {
    final data = cartDoc.data() as Map<String, dynamic>;

    final name = data["productName"] ?? "";
    final img = data["imageUrl"] ?? "";
    final price = (data["lineTotal"] ?? 0).toDouble();

    // Build subtitle supporting both new and legacy cart item structures
    final parts = <String>[];

    // New structure: variationName + selectedChoices
    final variationName = data['variationName'] ?? '';
    final selectedChoices = List<Map<String, dynamic>>.from(
      data['selectedChoices'] ?? [],
    );

    if (variationName.isNotEmpty) {
      parts.add(variationName);
    } else {
      // Legacy: sizeName
      final size = data["sizeName"] ?? "";
      if (size.isNotEmpty) parts.add(size);
    }

    if (selectedChoices.isNotEmpty) {
      for (var choice in selectedChoices) {
        final choiceName = choice['name']?.toString() ?? '';
        if (choiceName.isNotEmpty) parts.add(choiceName);
      }
    } else {
      // Legacy: sugarLevel, iceLevel
      final sugar = data["sugarLevel"] ?? "";
      final ice = data["iceLevel"] ?? "";
      if (sugar.isNotEmpty) parts.add(sugar);
      if (ice.isNotEmpty) parts.add(ice);
    }

    final subtitle = parts.join(' • ');

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : const Color(0xFFF8F8F8),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          // IMAGE
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              img,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Icon(
                    Icons.image,
                    size: 48,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
            ),
          ),

          const SizedBox(width: 12),

          // PRODUCT DETAILS
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // QTY CONTROLS
          _qtyController(cartDoc, isDark),

          const SizedBox(width: 12),

          Text(
            "₱ ${price.toStringAsFixed(0)}",
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY CONTROLLER
  // ============================================================
  Widget _qtyController(QueryDocumentSnapshot cartDoc, bool isDark) {
    final data = cartDoc.data() as Map<String, dynamic>;
    final qty = (data["quantity"] ?? 1).toInt();
    final lineTotal = (data["lineTotal"] ?? 0).toDouble();
    final unitPrice = qty == 0 ? 0 : lineTotal / qty;

    Future<void> changeQty(int newQty) async {
      if (newQty <= 0) {
        await cartDoc.reference.delete();
      } else {
        await cartDoc.reference.update({
          "quantity": newQty,
          "lineTotal": unitPrice * newQty,
        });
      }
    }

    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(
              Icons.remove,
              size: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () => changeQty(qty - 1),
          ),
          Text(
            qty.toString(),
            style: TextStyle(
              fontSize: 14,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          IconButton(
            icon: Icon(
              Icons.add,
              size: 18,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onPressed: () => changeQty(qty + 1),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKOUT BAR → jumps to real cart page (UserShell index 1)
  // ============================================================
  Widget _checkoutBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 6,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close store cart
          // Signal to go to checkout via callback
          widget.onGoToCheckout?.call();
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(14),
          ),
          alignment: Alignment.center,
          child: const Text(
            "Go to Checkout",
            style: TextStyle(
              color: Colors.white,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ),
    );
  }
}
