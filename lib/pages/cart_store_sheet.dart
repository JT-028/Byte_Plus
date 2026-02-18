// lib/pages/cart_store_sheet.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class CartStoreSheet extends StatefulWidget {
  final String storeId;

  const CartStoreSheet({super.key, required this.storeId});

  @override
  State<CartStoreSheet> createState() => _CartStoreSheetState();
}

class _CartStoreSheetState extends State<CartStoreSheet> {
  static const Color kBrandBlue = Color(0xFF1F41BB);

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      minChildSize: 0.40,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),

              // ---- BLUE TOP BAR / DRAG HANDLE ----
              Container(
                width: 55,
                height: 5,
                decoration: BoxDecoration(
                  color: kBrandBlue,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
              const SizedBox(height: 12),

              // ------------ TITLE ---------------
              const Text(
                "Your Items",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
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
                      return const Center(child: CircularProgressIndicator());
                    }

                    final docs = snap.data!.docs;

                    if (docs.isEmpty) {
                      return const Center(
                        child: Text(
                          "No items in your cart.",
                          style: TextStyle(color: Colors.black54),
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.only(bottom: 20),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        return _cartRow(docs[i]);
                      },
                    );
                  },
                ),
              ),

              // ----------- CHECKOUT BAR -----------
              _checkoutBar(),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // CART ROW WIDGET
  // ============================================================
  Widget _cartRow(QueryDocumentSnapshot cartDoc) {
    final data = cartDoc.data() as Map<String, dynamic>;

    final name = data["productName"] ?? "";
    final img = data["imageUrl"] ?? "";
    final price = (data["lineTotal"] ?? 0).toDouble();

    final size = data["sizeName"] ?? "";
    final sugar = data["sugarLevel"] ?? "";
    final ice = data["iceLevel"] ?? "";

    String subtitle = "";
    if (size.isNotEmpty) subtitle = size;
    if (sugar.isNotEmpty) subtitle += subtitle.isEmpty ? sugar : " • $sugar";
    if (ice.isNotEmpty) subtitle += subtitle.isEmpty ? ice : " • $ice";

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8F8F8),
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
              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48),
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
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),

          // QTY CONTROLS
          _qtyController(cartDoc),

          const SizedBox(width: 12),

          Text(
            "₱ ${price.toStringAsFixed(0)}",
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // QUANTITY CONTROLLER
  // ============================================================
  Widget _qtyController(QueryDocumentSnapshot cartDoc) {
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
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.remove, size: 18),
            onPressed: () => changeQty(qty - 1),
          ),
          Text(qty.toString(), style: const TextStyle(fontSize: 14)),
          IconButton(
            icon: const Icon(Icons.add, size: 18),
            onPressed: () => changeQty(qty + 1),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHECKOUT BAR → jumps to real cart page (UserShell index 1)
  // ============================================================
  Widget _checkoutBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 18),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: () {
          Navigator.pop(context); // Close store cart
          Navigator.pop(context); // Close store page
          // Then go to main cart tab
          Navigator.pushNamed(context, "/cart_tab");
        },
        child: Container(
          height: 48,
          decoration: BoxDecoration(
            color: kBrandBlue,
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
