import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import 'store_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const Color kBrandBlue = Color(0xFF1F41BB);
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("favorites")
              .orderBy("name", descending: false)
              .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingSkeleton();
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(color: Colors.red.shade400),
                ),
              );
            }

            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;

            // ⭐ EMPTY STATE — show browse button
            if (docs.isEmpty) {
              return _emptyFavoritesUI();
            }

            // NORMAL FAVORITES LIST
            return Column(
              children: [
                _header(),
                Expanded(
                  child: ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _favoriteCard(data);
                    },
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  // -------------------------------
  // HEADER
  // -------------------------------
  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: const Icon(Icons.arrow_back, size: 26),
          ),
          const SizedBox(width: 10),
          const Text(
            "Favourites",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // SHIMMER-STYLE LOADING SKELETON
  // -------------------------------
  Widget _loadingSkeleton() {
    // Simple animated opacity shimmer over grey cards
    return Column(
      children: [
        _header(),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: 4,
            itemBuilder: (_, __) {
              return _skeletonCard();
            },
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard() {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // EMPTY UI (LIKE YOUR CART EMPTY UI)
  // -------------------------------
  Widget _emptyFavoritesUI() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.favorite_border,
              size: 90,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 24),
            const Text(
              "No favourites yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add items from your favorite campus vendors",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 28),

            // ⭐ Same Browse button style as CartPage
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // back to profile / dashboard
                },
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
            )
          ],
        ),
      ),
    );
  }

  // -------------------------------
  // FAVORITE CARD + SWIPE TO REMOVE
  // -------------------------------
  Widget _favoriteCard(Map<String, dynamic> data) {
    final storeId = data["storeId"];
    final name = data["name"] ?? "";
    final type = data["type"] ?? "";
    final logoUrl = data["logoUrl"] ?? "";
    final bannerUrl = data["bannerUrl"] ?? "";

    return Dismissible(
      key: ValueKey(storeId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        decoration: BoxDecoration(
          color: Colors.red.shade400,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      onDismissed: (_) async {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .collection("favorites")
            .doc(storeId)
            .delete();
      },
      child: GestureDetector(
        onTap: () => _openStore(
          storeId: storeId,
          name: name,
          type: type,
          logoUrl: logoUrl,
          bannerUrl: bannerUrl,
        ),
        child: Container(
          margin: const EdgeInsets.only(bottom: 14),
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
                  errorBuilder: (_, __, ___) => Container(
                    width: 64,
                    height: 64,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.store, size: 34),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // text area
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),

              // tap-to-unfavourite icon
              GestureDetector(
                onTap: () async {
                  await FirebaseFirestore.instance
                      .collection("users")
                      .doc(uid)
                      .collection("favorites")
                      .doc(storeId)
                      .delete();
                },
                child: const Icon(Icons.favorite, color: Colors.red, size: 26),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // -------------------------------
  // SMOOTH TRANSITION TO STORE PAGE
  // -------------------------------
  void _openStore({
    required String storeId,
    required String name,
    required String type,
    required String logoUrl,
    required String bannerUrl,
  }) {
    Navigator.of(context).push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 260),
        pageBuilder: (_, animation, secondaryAnimation) {
          return StorePage(
            storeId: storeId,
            name: name,
            type: type,
            prepTime: "", // not stored in favorites
            logoUrl: logoUrl,
            bannerUrl: bannerUrl,
          );
        },
        transitionsBuilder: (_, animation, __, child) {
          final offsetAnimation = Tween<Offset>(
            begin: const Offset(1, 0),
            end: Offset.zero,
          ).animate(
            CurvedAnimation(
              parent: animation,
              curve: Curves.easeOutCubic,
            ),
          );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}
