import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import 'store_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .collection("favorites")
                  .orderBy("name", descending: false)
                  .snapshots(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _loadingSkeleton(isDark);
            }

            if (snap.hasError) {
              return Center(
                child: Text(
                  "Something went wrong",
                  style: TextStyle(
                    color: isDark ? AppColors.errorLight : AppColors.error,
                  ),
                ),
              );
            }

            if (!snap.hasData) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              );
            }

            final docs = snap.data!.docs;

            // ⭐ EMPTY STATE — show browse button
            if (docs.isEmpty) {
              return _emptyFavoritesUI(isDark);
            }

            // NORMAL FAVORITES LIST
            return Column(
              children: [
                _header(isDark),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                    itemCount: docs.length,
                    itemBuilder: (_, i) {
                      final data = docs[i].data() as Map<String, dynamic>;
                      return _favoriteCard(data, isDark);
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
  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Icon(
              Iconsax.arrow_left,
              size: 26,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            "Favourites",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  // -------------------------------
  // SHIMMER-STYLE LOADING SKELETON
  // -------------------------------
  Widget _loadingSkeleton(bool isDark) {
    // Simple animated opacity shimmer over grey cards
    return Column(
      children: [
        _header(isDark),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            itemCount: 4,
            itemBuilder: (_, __) {
              return _skeletonCard(isDark);
            },
          ),
        ),
      ],
    );
  }

  Widget _skeletonCard(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.grey.shade300,
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
                    color:
                        isDark ? AppColors.surfaceDark : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 12,
                  width: 80,
                  decoration: BoxDecoration(
                    color:
                        isDark ? AppColors.surfaceDark : Colors.grey.shade300,
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
  Widget _emptyFavoritesUI(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Iconsax.heart,
              size: 90,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 24),
            Text(
              "No favourites yet",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Add items from your favorite campus vendors",
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
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
                  backgroundColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
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

  // -------------------------------
  // FAVORITE CARD + SWIPE TO REMOVE
  // -------------------------------
  Widget _favoriteCard(Map<String, dynamic> data, bool isDark) {
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
          color: AppColors.error,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerRight,
        child: const Icon(Iconsax.trash, color: Colors.white),
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
        onTap:
            () => _openStore(
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
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? AppColors.borderDark : const Color(0xFFE6E6E6),
            ),
            boxShadow:
                isDark
                    ? null
                    : [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
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
                  errorBuilder:
                      (_, __, ___) => Container(
                        width: 64,
                        height: 64,
                        color:
                            isDark
                                ? AppColors.surfaceVariantDark
                                : Colors.grey.shade200,
                        child: Icon(
                          Iconsax.shop,
                          size: 34,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
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
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      type,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
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
                child: Icon(Iconsax.heart, color: AppColors.error, size: 26),
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
            CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
          );
          return SlideTransition(position: offsetAnimation, child: child);
        },
      ),
    );
  }
}

