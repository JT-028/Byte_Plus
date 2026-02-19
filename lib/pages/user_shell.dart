// lib/pages/user_shell.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
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

  final List<String> categories = const [
    "All",
    "Drinks",
    "Burger",
    "Coffee",
    "Chicken",
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.primaryLight : AppColors.primary,
      body: SafeArea(
        child: IndexedStack(
          index: selectedNav,
          children: [
            _dashboardUI(isDark),
            CartPage(onBrowse: () => setState(() => selectedNav = 0)),
            const OrdersPage(),
            const ProfilePage(),
          ],
        ),
      ),
      bottomNavigationBar: _bottomNav(isDark),
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD UI
  // ---------------------------------------------------------------------------

  Widget _dashboardUI(bool isDark) {
    return Stack(
      children: [
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          height: 300,
          child: Container(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
        Positioned.fill(
          top: 240,
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.background,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              children: [
                const SizedBox(height: 35),
                _categoriesBar(isDark),
                const SizedBox(height: 14),
                Expanded(child: _storeList(isDark)),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _topHeaderWithSearch(isDark),
        ),
      ],
    );
  }

  Widget _topHeaderWithSearch(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
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
                    const SizedBox(height: 6),
                    Text(
                      "What are you craving?",
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 2,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Image.network(
                    "https://res.cloudinary.com/ddhamh7cy/image/upload/v1763312250/spcf_logo_wgqxdg.jpg",
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Container(
                          width: 48,
                          height: 48,
                          color: Colors.white.withOpacity(0.2),
                          child: const Icon(Iconsax.user, color: Colors.white),
                        ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                hintText: "Search stores or food...",
                hintStyle: TextStyle(
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                  fontSize: 14,
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
              style: TextStyle(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _categoriesBar(bool isDark) {
    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          bool selected = selectedCategory == i;

          return GestureDetector(
            onTap: () => setState(() => selectedCategory = i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color:
                    selected
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? AppColors.surfaceDark : Colors.white),
                borderRadius: BorderRadius.circular(12),
                boxShadow:
                    selected
                        ? [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                        : null,
              ),
              child: Text(
                categories[i],
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color:
                      selected
                          ? Colors.white
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _storeList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("stores").snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
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
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.shop,
                  size: 64,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  "No stores found",
                  style: TextStyle(
                    fontSize: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
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
              isDark: isDark,
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
    required bool isDark,
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
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
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                      ),
                ),
              ),
            ),
            const SizedBox(width: 14),

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
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Iconsax.clock,
                        size: 14,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        prepTime,
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
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
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isFav
                              ? AppColors.error.withOpacity(0.1)
                              : (isDark
                                  ? AppColors.surfaceVariantDark
                                  : Colors.grey.shade100),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isFav ? Iconsax.heart : Iconsax.heart,
                      color:
                          isFav
                              ? AppColors.error
                              : (isDark
                                  ? AppColors.textTertiaryDark
                                  : Colors.grey),
                      size: 22,
                    ),
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

  Widget _bottomNav(bool isDark) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _navItem(
            icon: Iconsax.home_2,
            activeIcon: Iconsax.home_2,
            label: "Home",
            index: 0,
            isDark: isDark,
          ),
          _navItem(
            icon: Iconsax.shopping_cart,
            activeIcon: Iconsax.shopping_cart,
            label: "Cart",
            index: 1,
            isDark: isDark,
          ),
          _navItem(
            icon: Iconsax.receipt_2,
            activeIcon: Iconsax.receipt_2,
            label: "Orders",
            index: 2,
            isDark: isDark,
          ),
          _navItem(
            icon: Iconsax.user,
            activeIcon: Iconsax.user,
            label: "Profile",
            index: 3,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _navItem({
    required IconData icon,
    required IconData activeIcon,
    required String label,
    required int index,
    required bool isDark,
  }) {
    bool active = selectedNav == index;
    return GestureDetector(
      onTap: () => setState(() => selectedNav = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color:
              active
                  ? (isDark
                      ? AppColors.primaryLight.withOpacity(0.2)
                      : AppColors.primary.withOpacity(0.1))
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              active ? activeIcon : icon,
              size: 24,
              color:
                  active
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.textTertiaryDark : Colors.grey),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color:
                    active
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark ? AppColors.textTertiaryDark : Colors.grey),
              ),
            ),
          ],
        ),
      ),
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
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  bool pickupNow = true;
  DateTime? pickupTime;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: StreamBuilder<QuerySnapshot>(
          stream: CartService.streamCart(),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(
                  color: isDark ? AppColors.primaryLight : AppColors.primary,
                ),
              );
            }

            if (!snap.hasData || snap.data!.docs.isEmpty) {
              return _emptyCart(isDark);
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
                        Text(
                          "Your Cart",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _pickupSection(isDark),
                        const SizedBox(height: 20),
                        _orderDetailsSection(docs, isDark),
                      ],
                    ),
                  ),
                ),
                _bottomTotalBar(
                  total: total,
                  firstItem: first,
                  docs: docs,
                  isDark: isDark,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _emptyCart(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.shopping_bag,
                size: 64,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Hungry?",
              style: TextStyle(
                fontSize: 24,
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
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton(
                onPressed: widget.onBrowse,
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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

  Widget _pickupSection(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F7F7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade300,
        ),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Iconsax.clock,
                size: 18,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
              const SizedBox(width: 8),
              Text(
                "Choose pick up time",
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _pickupOption(
            title: "Pick up now",
            subtitle: "Estimated ready in 5–10 mins.",
            selected: pickupNow,
            isDark: isDark,
            onTap: () {
              setState(() {
                pickupNow = true;
                pickupTime = null;
              });
            },
          ),
          const SizedBox(height: 10),
          _pickupOption(
            title: "Pick up later",
            subtitle:
                pickupTime == null
                    ? "Set your pick up time."
                    : "Scheduled: ${pickupTime!.hour.toString().padLeft(2, '0')}:${pickupTime!.minute.toString().padLeft(2, '0')}",
            selected: !pickupNow,
            isDark: isDark,
            trailing: Icon(
              Iconsax.arrow_right_3,
              size: 18,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
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
    required bool isDark,
    Widget? trailing,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color:
              selected
                  ? (isDark ? AppColors.surfaceDark : Colors.white)
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : const Color(0xFFF5F5F5)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color:
                selected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: selected ? 2 : 1,
          ),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        child: Row(
          children: [
            Icon(
              selected ? Iconsax.tick_circle : Iconsax.record,
              size: 22,
              color:
                  selected
                      ? (isDark ? AppColors.primaryLight : AppColors.primary)
                      : (isDark ? AppColors.textTertiaryDark : Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
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

  Widget _orderDetailsSection(List<QueryDocumentSnapshot> docs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Iconsax.receipt_item,
              size: 18,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            const SizedBox(width: 8),
            Text(
              "Order Details",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: widget.onBrowse,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark
                          ? AppColors.primaryLight.withOpacity(0.1)
                          : AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Iconsax.add,
                      size: 16,
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      "Add Items",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : const Color(0xFFF7F7F7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.borderDark : Colors.grey.shade300,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Column(
            children: docs.map((d) => _cartRow(d, isDark)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _cartRow(QueryDocumentSnapshot doc, bool isDark) {
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
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              imageUrl,
              width: 52,
              height: 52,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => Container(
                    width: 52,
                    height: 52,
                    color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                    child: Icon(
                      Iconsax.image,
                      size: 24,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
                  ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
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
                    padding: const EdgeInsets.only(top: 3),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
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
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Iconsax.minus,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  onPressed:
                      () => CartService.updateQuantity(
                        itemId: doc.id,
                        newQuantity: qty - 1,
                        unitPrice: unitPrice,
                      ),
                ),
                Text(
                  qty.toString(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                  icon: Icon(
                    Iconsax.add,
                    size: 16,
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
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
            "\u20b1 ${lineTotal.toStringAsFixed(0)}",
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
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
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Total",
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "\u20b1 ${total.toStringAsFixed(0)}",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: SizedBox(
              height: 50,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
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
                      SnackBar(
                        content: const Text("Order placed successfully!"),
                        backgroundColor: AppColors.success,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  } catch (e) {
                    if (!mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("Failed to place order: $e"),
                        backgroundColor: AppColors.error,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                  }
                },

                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Iconsax.shopping_bag,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      "Place Order",
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
