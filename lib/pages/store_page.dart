// lib/pages/store_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'product_page.dart';
import 'cart_store_sheet.dart';

class StorePage extends StatefulWidget {
  final String storeId;
  final String name;
  final String type;
  final String prepTime;
  final String logoUrl;
  final String bannerUrl;

  const StorePage({
    super.key,
    required this.storeId,
    required this.name,
    required this.type,
    required this.prepTime,
    required this.logoUrl,
    required this.bannerUrl,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  static const Color kBrandBlue = Color(0xFF1F41BB);

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  List<String> categories = ["Popular"];
  String selectedCategory = "Popular";

  final ScrollController scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {};

  @override
  void initState() {
    super.initState();
    loadCategories();
  }

  Future<void> loadCategories() async {
    final snap = await FirebaseFirestore.instance
        .collection("stores")
        .doc(widget.storeId)
        .collection("menu")
        .get();

    final set = <String>{"Popular"};

    for (var doc in snap.docs) {
      List items = doc["category"] ?? [];
      for (var c in items) {
        set.add(c.toString());
      }
    }

    categories = set.toList();
    for (var c in categories) {
      sectionKeys[c] = GlobalKey();
    }

    setState(() {});
  }

  void scrollToCategory(String cat) {
    final key = sectionKeys[cat];
    if (key == null) return;

    final ctx = key.currentContext;
    if (ctx == null) return;

    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      alignment: 0,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader()),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyCategoryBar(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    onSelected: (cat) {
                      setState(() => selectedCategory = cat);
                      scrollToCategory(cat);
                    },
                  ),
                ),
                _buildMenuSections(),
                const SliverToBoxAdapter(child: SizedBox(height: 200)),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _storeCartBar(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(32),
          ),
          child: Image.network(
            widget.bannerUrl,
            width: double.infinity,
            height: 200,
            fit: BoxFit.cover,
          ),
        ),

        Positioned(
          top: 16,
          left: 16,
          child: _circleBtn(Icons.arrow_back, () => Navigator.pop(context)),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection("favorites")
                .doc(widget.storeId)
                .snapshots(),
            builder: (_, snap) {
              final isFav = snap.data?.exists ?? false;
              return _circleBtn(
                isFav ? Icons.favorite : Icons.favorite_border,
                _toggleFavorite,
                color: isFav ? Colors.red : Colors.white,
              );
            },
          ),
        ),

        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _storeInfoCard(),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap, {Color color = Colors.black}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.white,
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color),
      ),
    );
  }

  Widget _storeInfoCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 10, offset: Offset(0, 4))
        ],
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              widget.logoUrl,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 14),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.name,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Text(widget.type, style: const TextStyle(color: Colors.grey)),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14),
                  const SizedBox(width: 4),
                  Text(widget.prepTime),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSections() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("stores")
          .doc(widget.storeId)
          .collection("menu")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const SliverToBoxAdapter(
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final docs = snap.data!.docs;

        return SliverList(
          delegate: SliverChildListDelegate(
            categories.map((cat) {
              final items = docs.where((d) {
                final list = List<String>.from(d["category"] ?? []);
                return cat == "Popular" || list.contains(cat);
              }).toList();

              if (items.isEmpty && cat != "Popular") return const SizedBox();

              return Padding(
                key: sectionKeys[cat],
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(cat,
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 14),

                    if (cat == "Popular")
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: items.length,
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.72,
                        ),
                        itemBuilder: (_, i) => _gridItem(items[i]),
                      )
                    else
                      Column(
                        children: items.map((doc) => _listItem(doc)).toList(),
                      ),
                  ],
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  Widget _gridItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cartItems")
          .where("productId", isEqualTo: doc.id)
          .snapshots(),
      builder: (_, snap) {
        int qty = 0;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          qty = ((snap.data!.docs.first["quantity"] ?? 0) as num).toInt();
        }

        return GestureDetector(
          onTap: () => _openProduct(doc.id),
          child: Stack(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(color: Colors.black12, blurRadius: 6),
                  ],
                ),
                child: Column(
                  children: [
                    Expanded(
                      child: Image.network(
                        data["imageUrl"],
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      data["name"],
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "₱${data["price"]}",
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),

              if (qty > 0)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: kBrandBlue,
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      qty.toString(),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _listItem(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cartItems")
          .where("productId", isEqualTo: doc.id)
          .snapshots(),
      builder: (_, snap) {
        int qty = 0;
        if (snap.hasData && snap.data!.docs.isNotEmpty) {
          qty = ((snap.data!.docs.first["quantity"] ?? 0) as num).toInt();
        }

        return GestureDetector(
          onTap: () => _openProduct(doc.id),
          child: Container(
            margin: const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: const [
                BoxShadow(color: Colors.black12, blurRadius: 6)
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Image.network(
                      data["imageUrl"],
                      width: 70,
                      height: 70,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        data["name"],
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Text(
                      "₱${data["price"]}",
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (qty > 0)
                  Positioned(
                    top: 0,
                    right: 0,
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        color: kBrandBlue,
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        qty.toString(),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openProduct(String productId) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => ProductPage(
        storeId: widget.storeId,
        productId: productId,
      ),
    );
  }

  // ⭐⭐⭐ ADDING LOGO + BANNER URL WHEN FAVORITING ⭐⭐⭐
  Future<void> _toggleFavorite() async {
    final userRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("favorites")
        .doc(widget.storeId);

    final favSnap = await userRef.get();

    if (favSnap.exists) {
      await userRef.delete();
    } else {
      // SAVE EVERYTHING NEEDED FOR FAVORITES PAGE
      await userRef.set({
        "storeId": widget.storeId,
        "name": widget.name,
        "type": widget.type,
        "logoUrl": widget.logoUrl,
        "bannerUrl": widget.bannerUrl,
        "addedAt": DateTime.now(),
      });
    }
  }

  Widget _storeCartBar() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("cartItems")
          .where("storeId", isEqualTo: widget.storeId)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const SizedBox();
        }

        final docs = snap.data!.docs;

        final total = docs.fold<double>(
          0,
          (sum, d) => sum + ((d["lineTotal"] ?? 0) as num).toDouble(),
        );

        final itemCount = docs.fold<int>(
          0,
          (sum, d) => sum + ((d["quantity"] ?? 0) as num).toInt(),
        );

        return Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 20),
          decoration: const BoxDecoration(
            color: kBrandBlue,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder: (_) => CartStoreSheet(storeId: widget.storeId),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.25),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 20),
                const Text(
                  "View Your Cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "₱${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StickyCategoryBar extends SliverPersistentHeaderDelegate {
  final List<String> categories;
  final String selectedCategory;
  final Function(String) onSelected;

  _StickyCategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      color: Colors.white,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: categories.map((c) {
            final bool selected = c == selectedCategory;
            return GestureDetector(
              onTap: () => onSelected(c),
              child: Container(
                margin: const EdgeInsets.only(right: 10),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                decoration: BoxDecoration(
                  color: selected ? Colors.blue : Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                    color: selected ? Colors.blue : Colors.grey.shade300,
                  ),
                ),
                child: Text(
                  c,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  double get maxExtent => 56;

  @override
  double get minExtent => 56;

  @override
  bool shouldRebuild(_) => true;
}
