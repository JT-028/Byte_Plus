// lib/pages/user_shell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/order_service.dart';
import '../services/cart_service.dart';
import 'store_page.dart';
import 'profile_page.dart';
import 'order_page.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int selectedNav = 0;
  int selectedCategory = 0;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  static const Color kBrandBlue = Color(0xFF1F41BB);
  static const Color kPageBg = Color(0xFFF7F3FF);

  final List<String> categories = const [
    "All",
    "Drinks",
    "Burger",
    "Coffee",
    "Chicken",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBrandBlue,
      body: SafeArea(
        child: IndexedStack(
          index: selectedNav,
          children: [
            _dashboardUI(),
            CartPage(onBrowse: () => setState(() => selectedNav = 0)),
            OrdersPage(),
            ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD UI
  // ---------------------------------------------------------------------------

  Widget _dashboardUI() {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(color: kBrandBlue),
        ),
        Positioned.fill(
          top: 240,
          child: Container(
            decoration: const BoxDecoration(
              color: kPageBg,
              borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
            ),
            child: Column(
              children: [
                const SizedBox(height: 35),
                _categoriesBar(),
                const SizedBox(height: 14),
                Expanded(child: _storeList()),
              ],
            ),
          ),
        ),
        Positioned(top: 0, left: 0, right: 0, child: _topHeaderWithSearch()),
      ],
    );
  }

  Widget _topHeaderWithSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Welcome to Byte Plus",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      "What are you craving?",
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Image.network(
                  "https://res.cloudinary.com/ddhamh7cy/image/upload/v1763312250/spcf_logo_wgqxdg.jpg",
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: const TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Search",
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriesBar() {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          bool selected = selectedCategory == i;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = i),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
              decoration: BoxDecoration(
                color: selected ? kBrandBlue : Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: selected ? Colors.white : Colors.black87,
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _storeList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("stores").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: kBrandBlue),
          );
        }

        List docs = snap.data!.docs;

        if (selectedCategory != 0) {
          String selectedCat = categories[selectedCategory];
          docs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final cats = data["category"] ?? [];
                return cats.contains(selectedCat);
              }).toList();
        }

        if (docs.isEmpty) {
          return const Center(child: Text("No stores found."));
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data() as Map<String, dynamic>;

            return _storeCard(
              storeId: doc.id,
              name: data["name"] ?? "",
              type: data["type"] ?? "",
              prepTime: data["prepTime"] ?? "",
              logoUrl: data["logoUrl"] ?? "",
              bannerUrl: data["bannerUrl"] ?? "",
            );
          },
        );
      },
    );
  }

  // ❤️ FAVORITE SYSTEM
  Widget _storeCard({
    required String storeId,
    required String name,
    required String type,
    required String prepTime,
    required String logoUrl,
    required String bannerUrl,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (_) => StorePage(
                  storeId: storeId,
                  name: name,
                  type: type,
                  prepTime: prepTime,
                  logoUrl: logoUrl,
                  bannerUrl: bannerUrl,
                ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: const Color(0xFFE6E6E6)),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                logoUrl,
                width: 64,
                height: 64,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    type,
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prepTime,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            StreamBuilder<DocumentSnapshot>(
              stream:
                  FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("favorites")
                      .doc(storeId)
                      .snapshots(),
              builder: (_, favSnap) {
                bool isFav = favSnap.data?.exists ?? false;
                return GestureDetector(
                  onTap:
                      () => toggleFavorite(
                        storeId,
                        name,
                        type,
                        logoUrl,
                        bannerUrl,
                      ),
                  child: Icon(
                    isFav ? Icons.favorite : Icons.favorite_border,
                    color: isFav ? Colors.red : Colors.grey,
                    size: 26,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> toggleFavorite(
    String storeId,
    String name,
    String type,
    String logoUrl,
    String bannerUrl,
  ) async {
    final ref = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(storeId);

    if ((await ref.get()).exists) {
      await ref.delete();
    } else {
      await ref.set({
        "storeId": storeId,
        "name": name,
        "type": type,
        "logoUrl": logoUrl,
        "bannerUrl": bannerUrl,
        "addedAt": DateTime.now(),
      });
    }
  }

  Widget _bottomNav() {
    return Container(
      height: 70,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(icon: Icons.restaurant, index: 0),
          _navItem(icon: Icons.shopping_cart_outlined, index: 1),
          _navItem(icon: Icons.receipt_long, index: 2),
          _navItem(icon: Icons.person_outline, index: 3),
        ],
      ),
    );
  }

  Widget _navItem({required IconData icon, required int index}) {
    bool active = selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => selectedNav = index),
      child: Icon(icon, size: 24, color: active ? kBrandBlue : Colors.grey),
    );
  }
}

// ============================================================================
// CART PAGE
// ============================================================================

class CartPage extends StatefulWidget {
  final VoidCallback? onBrowse;

  const CartPage({super.key, this.onBrowse});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  static const Color kBrandBlue = Color(0xFF1F41BB);
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  bool pickupNow = true;
  DateTime? pickupTime;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: CartService.streamCart(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _emptyCart();
            }

            final docs = snap.data!.docs;

            final total = docs.fold<double>(
              0,
              (prev, d) => prev + (d['lineTotal'] as num).toDouble(),
            );

            // get storeName from first item
            final first = docs.first.data() as Map<String, dynamic>;

            return Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Your Cart",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 16),
                        _pickupSection(),
                        const SizedBox(height: 16),
                        _orderDetailsSection(docs),
                      ],
                    ),
                  ),
                ),
                _bottomTotalBar(total: total, firstItem: first, docs: docs),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyCart() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.shopping_bag_outlined,
              size: 90,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              "Hungry?",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              "Add items from your favorite campus vendors",
              style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Browse",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _pickupSection() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Choose pick up time",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          _pickupOption(
            title: "Pick up now",
            subtitle: "Estimated ready in 5–10 mins.",
            selected: pickupNow,
            onTap: () {
              setState(() {
                pickupNow = true;
                pickupTime = null;
              });
            },
          ),
          const SizedBox(height: 8),
          _pickupOption(
            title: "Pick up later",
            subtitle:
                pickupTime == null
                    ? "Set your pick up time."
                    : "Scheduled: ${pickupTime!.hour.toString().padLeft(2, '0')}:${pickupTime!.minute.toString().padLeft(2, '0')}",
            selected: !pickupNow,
            trailing: const Icon(Icons.chevron_right),
            onTap: () async {
              final now = DateTime.now();
              final timeOfDay = await showTimePicker(
                context: context,
                initialTime: TimeOfDay.fromDateTime(
                  now.add(const Duration(minutes: 30)),
                ),
              );
              if (timeOfDay != null) {
                final dt = DateTime(
                  now.year,
                  now.month,
                  now.day,
                  timeOfDay.hour,
                  timeOfDay.minute,
                );
                setState(() {
                  pickupNow = false;
                  pickupTime = dt;
                });
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _pickupOption({
    required String title,
    required String subtitle,
    required bool selected,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Colors.white : const Color(0xFFF5F5F5),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? kBrandBlue : Colors.grey.shade300,
            width: selected ? 1.4 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle : Icons.circle_outlined,
              size: 20,
              color: selected ? kBrandBlue : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: Colors.black54),
                  ),
                ],
              ),
            ),
            if (trailing != null) trailing,
          ],
        ),
      ),
    );
  }

  Widget _orderDetailsSection(List<QueryDocumentSnapshot> docs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              "Order Details",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onBrowse,
              child: const Text(
                "Add Items",
                style: TextStyle(
                  fontSize: 13,
                  color: kBrandBlue,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.grey.shade300),
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: docs.map((d) => _cartRow(d)).toList()),
        ),
      ],
    );
  }

  Widget _cartRow(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final productName = data['productName'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final sizeName = data['sizeName'] ?? '';
    final sugar = data['sugarLevel'] ?? '';
    final ice = data['iceLevel'] ?? '';
    final qty = (data['quantity'] as num).toInt();
    final lineTotal = (data['lineTotal'] as num).toDouble();

    String subtitle = '';
    if (sizeName.isNotEmpty) subtitle = sizeName;
    if (sugar.isNotEmpty) subtitle += subtitle.isEmpty ? sugar : ' • $sugar';
    if (ice.isNotEmpty) subtitle += subtitle.isEmpty ? ice : ' • $ice';

    final unitPrice = qty > 0 ? (lineTotal / qty) : 0.0;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 48,
              height: 48,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const Icon(Icons.image, size: 48),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
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
                        fontSize: 12,
                        color: Colors.black54,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // QUANTITY STEPPER
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.grey.shade300),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: const Icon(Icons.remove, size: 16),
                  onPressed:
                      () => CartService.updateQuantity(
                        itemId: doc.id,
                        newQuantity: qty - 1,
                        unitPrice: unitPrice,
                      ),
                ),
                Text(qty.toString(), style: const TextStyle(fontSize: 14)),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 30,
                    minHeight: 30,
                  ),
                  icon: const Icon(Icons.add, size: 16),
                  onPressed:
                      () => CartService.updateQuantity(
                        itemId: doc.id,
                        newQuantity: qty + 1,
                        unitPrice: unitPrice,
                      ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),
          Text(
            "₱ ${lineTotal.toStringAsFixed(0)}",
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // FINAL ORDER BUTTON
  Widget _bottomTotalBar({
    required double total,
    required Map<String, dynamic> firstItem,
    required List<QueryDocumentSnapshot> docs,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontSize: 13, color: Colors.black54),
                ),
                const SizedBox(height: 2),
                Text(
                  "₱ ${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SizedBox(
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: kBrandBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                onPressed: () async {
                  try {
                    if (docs.isEmpty) {
                      throw Exception("Cart is empty");
                    }

                    final first = docs.first.data() as Map<String, dynamic>;

                    // ---- SAFE STORE ID ----
                    final storeId = (first["storeId"] ?? "").toString();
                    if (storeId.isEmpty) {
                      throw Exception("Missing storeId in cart item!");
                    }

                    // ---- FETCH STORE NAME SAFELY ----
                    final storeDoc =
                        await FirebaseFirestore.instance
                            .collection("stores")
                            .doc(storeId)
                            .get();

                    final storeName =
                        (storeDoc.data()?["name"] ?? "Unknown Store")
                            .toString();

                    // ---- CONVERT ITEMS ----
                    final List<Map<String, dynamic>> items =
                        docs
                            .map((d) => (d.data() as Map<String, dynamic>))
                            .toList();

                    // ---- FINAL ORDER CALL ----
                    await OrderService().placeOrder(
                      storeId: storeId,
                      storeName: storeName,
                      items: items,
                      total: total,
                      pickupNow: pickupNow,
                      pickupTime: pickupTime,
                    );

                    // Clear cart after success
                    await CartService.clearCart();

                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Order placed successfully"),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Failed to place order: $e")),
                    );
                  }
                },

                child: const Text(
                  "Place Order",
                  style: TextStyle(fontSize: 15, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
