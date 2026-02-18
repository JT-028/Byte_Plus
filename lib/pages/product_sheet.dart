import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class ProductSheet extends StatefulWidget {
  final String storeId;
  final String productId;
  final Map<String, dynamic> productData;

  const ProductSheet({
    super.key,
    required this.storeId,
    required this.productId,
    required this.productData,
  });

  @override
  State<ProductSheet> createState() => _ProductSheetState();
}

class _ProductSheetState extends State<ProductSheet> {
  String selectedSize = "Regular";
  String selectedSugar = "Normal";
  String selectedIce = "Normal";
  int quantity = 1;

  bool isSaving = false;

  @override
  Widget build(BuildContext context) {
    final data = widget.productData;

    return SafeArea(
      child: Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  data["name"] ?? "Item",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),

            const SizedBox(height: 12),

            /// PRICE
            Text(
              "₱ ${data["price"]}",
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),

            const SizedBox(height: 16),

            /// OPTIONS
            _buildSectionTitle("Size"),
            _buildOptionSelector(["Regular", "Large"], selectedSize, (val) {
              setState(() => selectedSize = val);
            }),

            const SizedBox(height: 12),
            _buildSectionTitle("Sugar"),
            _buildOptionSelector(["Normal", "Less Sugar", "Extra Sugar"], selectedSugar, (val) {
              setState(() => selectedSugar = val);
            }),

            const SizedBox(height: 12),
            _buildSectionTitle("Ice"),
            _buildOptionSelector(["Normal", "Less Ice", "More Ice"], selectedIce, (val) {
              setState(() => selectedIce = val);
            }),

            const SizedBox(height: 20),

            /// QUANTITY
            _buildSectionTitle("Quantity"),
            Row(
              children: [
                _smallCircleButton(Icons.remove, () {
                  if (quantity > 1) {
                    setState(() => quantity--);
                  }
                }),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    quantity.toString(),
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                _smallCircleButton(Icons.add, () {
                  setState(() => quantity++);
                }),
              ],
            ),

            const SizedBox(height: 24),

            /// ADD BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isSaving ? null : _addToCart,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isSaving
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Add to Cart",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
              ),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // CART MERGE LOGIC
  // ---------------------------------------------------------------------------
  Future<void> _addToCart() async {
    setState(() => isSaving = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final cartRef = FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("cartItems");

    final String mergeKey =
        "${widget.productId}-$selectedSize-$selectedSugar-$selectedIce";

    try {
      /// Check if same combination already exists
      final existing = await cartRef.where("mergeKey", isEqualTo: mergeKey).get();

      if (existing.docs.isNotEmpty) {
        /// MERGE
        final doc = existing.docs.first;
        await cartRef.doc(doc.id).update({
          "quantity": FieldValue.increment(quantity),
          "lineTotal": (doc["price"] * (doc["quantity"] + quantity)),
        });
      } else {
        /// ADD NEW ITEM
        await cartRef.add({
          "productId": widget.productId,
          "storeId": widget.storeId,
          "name": widget.productData["name"],
          "imageUrl": widget.productData["imageUrl"],
          "price": widget.productData["price"],
          "quantity": quantity,
          "size": selectedSize,
          "sugar": selectedSugar,
          "ice": selectedIce,
          "mergeKey": mergeKey,
          "lineTotal": widget.productData["price"] * quantity,
          "createdAt": FieldValue.serverTimestamp(),
        });
      }

      if (mounted) Navigator.pop(context);

    } catch (e) {
      print("CART ERROR: $e");
    }

    if (mounted) setState(() => isSaving = false);
  }

  // ---------------------------------------------------------------------------
  // UI HELPERS
  // ---------------------------------------------------------------------------

  Widget _buildSectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
    );
  }

  Widget _buildOptionSelector(List<String> options, String selected, Function(String) onSelect) {
    return Wrap(
      spacing: 10,
      children: options.map((opt) {
        final bool isActive = (opt == selected);
        return ChoiceChip(
          label: Text(opt),
          selected: isActive,
          selectedColor: Colors.blue,
          labelStyle: TextStyle(
            color: isActive ? Colors.white : Colors.black,
          ),
          onSelected: (_) => onSelect(opt),
        );
      }).toList(),
    );
  }

  Widget _smallCircleButton(IconData icon, VoidCallback action) {
    return InkWell(
      onTap: action,
      child: Container(
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xfff1f1f1),
        ),
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18),
      ),
    );
  }
}
