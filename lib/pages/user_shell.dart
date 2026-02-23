// lib/pages/user_shell.dart
import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../services/order_service.dart';
import '../services/cart_service.dart';
import '../services/notification_service.dart';
import '../utils/responsive_utils.dart';
import '../widgets/app_modal_dialog.dart';
import '../widgets/pickup_time_picker.dart';
import 'store_page.dart';
import 'product_page.dart';
import 'profile_page.dart';
import 'order_page.dart';
import 'notifications_page.dart';
import 'login_page.dart';

class UserShell extends StatefulWidget {
  const UserShell({super.key});

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  int selectedNav = 0;
  int selectedCategory = 0;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  final List<String> categories = const [
    "All",
    "Drinks",
    "Burger",
    "Coffee",
    "Chicken",
    "Snacks",
    "Desserts",
  ];

  // Search
  final _searchController = TextEditingController();
  String _searchQuery = '';
  List<Map<String, dynamic>> _productResults = [];
  bool _isSearchingProducts = false;
  Timer? _debounceTimer;

  @override
  void dispose() {
    _searchController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  String _formatStoreTime(String? time) {
    if (time == null || !time.contains(':')) return '';
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  bool _isStoreOpen(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) {
      return true; // Open if no hours set
    }
    if (!openingTime.contains(':') || !closingTime.contains(':')) return true;

    try {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;

      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final openMinutes = openHour * 60 + openMinute;

      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      final closeMinutes = closeHour * 60 + closeMinute;

      // Handle case where closing time is past midnight
      if (closeMinutes < openMinutes) {
        // Store is open from opening time to midnight, or from midnight to closing time
        return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
      } else {
        // Normal case: store opens and closes on the same day
        return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      }
    } catch (e) {
      return true; // Default to open if parsing fails
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query.trim());
    _debounceTimer?.cancel();
    if (query.trim().isNotEmpty) {
      _debounceTimer = Timer(const Duration(milliseconds: 400), () {
        _searchProducts(query.trim());
      });
    } else {
      setState(() {
        _productResults = [];
        _isSearchingProducts = false;
      });
    }
  }

  Future<void> _searchProducts(String query) async {
    setState(() => _isSearchingProducts = true);
    try {
      final storesSnap =
          await FirebaseFirestore.instance.collection('stores').get();
      final results = <Map<String, dynamic>>[];
      final lowerQuery = query.toLowerCase();

      for (final storeDoc in storesSnap.docs) {
        final storeData = storeDoc.data();
        final menuSnap =
            await FirebaseFirestore.instance
                .collection('stores')
                .doc(storeDoc.id)
                .collection('menu')
                .get();

        for (final menuDoc in menuSnap.docs) {
          final menuData = menuDoc.data();
          final name = (menuData['name'] ?? '').toString().toLowerCase();
          if (name.contains(lowerQuery)) {
            results.add({
              'productId': menuDoc.id,
              'storeId': storeDoc.id,
              'storeName': storeData['name'] ?? '',
              'productName': menuData['name'] ?? '',
              'price': menuData['price'] ?? 0,
              'imageUrl': menuData['imageUrl'] ?? '',
            });
          }
        }
      }

      if (mounted) {
        setState(() {
          _productResults = results;
          _isSearchingProducts = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isSearchingProducts = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // required for AutomaticKeepAliveClientMixin
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;

        // If not on home tab, go back to home
        if (selectedNav != 0) {
          setState(() => selectedNav = 0);
          return;
        }

        // On home tab - show logout confirmation
        final ok = await AppModalDialog.confirm(
          context: context,
          title: 'Log Out?',
          message: 'Are you sure you want to log out?',
          confirmLabel: 'Yes, Log Out',
          cancelLabel: 'Cancel',
        );

        if (ok != true) return;

        // Show loading overlay
        showDialog(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black87,
          builder:
              (context) => PopScope(
                canPop: false,
                child: Center(
                  child: Material(
                    color: Colors.transparent,
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 40),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 28,
                      ),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 48,
                            height: 48,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Logging out',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                              color:
                                  isDark
                                      ? AppColors.textPrimaryDark
                                      : AppColors.textPrimary,
                              decoration: TextDecoration.none,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
        );

        await Future.delayed(const Duration(milliseconds: 800));
        await FirebaseAuth.instance.signOut();

        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
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
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // DASHBOARD UI
  // ---------------------------------------------------------------------------

  Widget _dashboardUI(bool isDark) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      behavior: HitTestBehavior.opaque,
      child: Stack(
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
      ),
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
                        color: Colors.white.withValues(alpha: 0.7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Notification bell
              StreamBuilder<int>(
                stream: NotificationService.getUnreadCount(uid),
                builder: (context, snapshot) {
                  final unreadCount = snapshot.data ?? 0;
                  return GestureDetector(
                    onTap:
                        () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const NotificationsPage(),
                          ),
                        ),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Icon(
                              Iconsax.notification,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          if (unreadCount > 0)
                            Positioned(
                              right: 6,
                              top: 6,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 16,
                                  minHeight: 16,
                                ),
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(width: 8),
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.3),
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
                          color: Colors.white.withValues(alpha: 0.2),
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
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                prefixIcon: Icon(
                  Iconsax.search_normal,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                suffixIcon:
                    _searchQuery.isNotEmpty
                        ? IconButton(
                          icon: Icon(
                            Icons.close,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                          onPressed: () {
                            _searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                        : null,
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
                            color: AppColors.primary.withValues(alpha: 0.3),
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
    // If searching, show search results instead
    if (_searchQuery.isNotEmpty) {
      return _searchResultsList(isDark);
    }

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

        final responsive = ResponsiveUtils.of(context);
        final isTabletOrLarger = !responsive.isMobile;

        if (isTabletOrLarger) {
          return GridView.builder(
            padding: EdgeInsets.symmetric(
              horizontal: responsive.horizontalPadding,
              vertical: 12,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: responsive.value(
                mobile: 1,
                tablet: 2,
                desktop: 3,
              ),
              crossAxisSpacing: 16,
              mainAxisSpacing: 14,
              childAspectRatio: 2.8,
            ),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final doc = docs[i];
              final data = doc.data() as Map<String, dynamic>;

              return _storeCard(
                storeId: doc.id,
                name: data["name"] ?? "",
                description: data["description"] ?? "",
                type: data["type"] ?? "",
                prepTime: data["prepTime"] ?? "",
                logoUrl: data["logoUrl"] ?? "",
                bannerUrl: data["bannerUrl"] ?? "",
                openingTime: data["openingTime"],
                closingTime: data["closingTime"],
                isDark: isDark,
                isGridItem: true,
              );
            },
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
              description: data["description"] ?? "",
              type: data["type"] ?? "",
              prepTime: data["prepTime"] ?? "",
              logoUrl: data["logoUrl"] ?? "",
              bannerUrl: data["bannerUrl"] ?? "",
              openingTime: data["openingTime"],
              closingTime: data["closingTime"],
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _searchResultsList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('stores').snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final lowerQuery = _searchQuery.toLowerCase();

        // Filter stores by name
        final matchedStores =
            snap.data!.docs.where((doc) {
              final data = doc.data() as Map<String, dynamic>;
              final name = (data['name'] ?? '').toString().toLowerCase();
              return name.contains(lowerQuery);
            }).toList();

        final hasStores = matchedStores.isNotEmpty;
        final hasProducts = _productResults.isNotEmpty;

        if (!hasStores && !hasProducts && !_isSearchingProducts) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.search_normal,
                  size: 64,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  'No results for "$_searchQuery"',
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

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          children: [
            if (hasStores) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(
                  'Stores',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ),
              ...matchedStores.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return _storeCard(
                  storeId: doc.id,
                  name: data['name'] ?? '',
                  description: data['description'] ?? '',
                  type: data['type'] ?? '',
                  prepTime: data['prepTime'] ?? '',
                  logoUrl: data['logoUrl'] ?? '',
                  bannerUrl: data['bannerUrl'] ?? '',
                  openingTime: data['openingTime'],
                  closingTime: data['closingTime'],
                  isDark: isDark,
                );
              }),
            ],
            if (_isSearchingProducts)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Center(
                  child: CircularProgressIndicator(
                    color: isDark ? AppColors.primaryLight : AppColors.primary,
                  ),
                ),
              ),
            if (hasProducts) ...[
              Padding(
                padding: const EdgeInsets.only(top: 10, bottom: 10),
                child: Text(
                  'Products',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ),
              ..._productResults.map((p) {
                return GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      backgroundColor: Colors.transparent,
                      isScrollControlled: true,
                      builder:
                          (_) => ProductPage(
                            storeId: p['storeId'],
                            productId: p['productId'],
                          ),
                    );
                  },
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.06,
                          ),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            p['imageUrl'] ?? '',
                            width: 50,
                            height: 50,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  width: 50,
                                  height: 50,
                                  color:
                                      isDark
                                          ? AppColors.surfaceVariantDark
                                          : Colors.grey.shade200,
                                  child: Icon(
                                    Iconsax.image,
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
                                p['productName'] ?? '',
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
                                p['storeName'] ?? '',
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
                        Text(
                          '\u20b1${p['price']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ],
          ],
        );
      },
    );
  }

  // ❤️ FAVORITE SYSTEM
  Widget _storeCard({
    required String storeId,
    required String name,
    required String description,
    required String type,
    required String prepTime,
    required String logoUrl,
    required String bannerUrl,
    required bool isDark,
    String? openingTime,
    String? closingTime,
    bool isGridItem = false,
  }) {
    // Check if store is currently open
    final isOpen = _isStoreOpen(openingTime, closingTime);

    // Build operating hours string
    String? hoursText;
    if (openingTime != null && closingTime != null) {
      hoursText =
          '${_formatStoreTime(openingTime)} – ${_formatStoreTime(closingTime)}';
    }

    return Semantics(
      label: '$name, $type, prep time $prepTime${isOpen ? '' : ', closed'}',
      hint: isOpen ? 'Double tap to view menu' : 'Store is currently closed',
      button: isOpen,
      child: GestureDetector(
        onTap:
            !isOpen
                ? null
                : () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder:
                          (_) => StorePage(
                            storeId: storeId,
                            name: name,
                            description: description,
                            type: type,
                            prepTime: prepTime,
                            logoUrl: logoUrl,
                            bannerUrl: bannerUrl,
                            openingTime: openingTime,
                            closingTime: closingTime,
                          ),
                    ),
                  );
                  // Handle go to cart signal from store page
                  if (result == 'goToCart' && mounted) {
                    setState(() => selectedNav = 1);
                  }
                },
        child: Opacity(
          opacity: isOpen ? 1.0 : 0.5,
          child: Container(
            margin:
                isGridItem
                    ? EdgeInsets.zero
                    : const EdgeInsets.only(bottom: 14),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color:
                  isOpen
                      ? (isDark ? AppColors.surfaceDark : Colors.white)
                      : (isDark
                          ? AppColors.surfaceVariantDark
                          : Colors.grey.shade100),
              borderRadius: BorderRadius.circular(16),
              border:
                  !isOpen
                      ? Border.all(
                        color:
                            isDark
                                ? AppColors.borderDark
                                : Colors.grey.shade300,
                        width: 1,
                      )
                      : null,
              boxShadow:
                  isOpen
                      ? [
                        BoxShadow(
                          color: Colors.black.withValues(
                            alpha: isDark ? 0.2 : 0.06,
                          ),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                      : null,
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        boxShadow:
                            isOpen
                                ? [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    blurRadius: 6,
                                    offset: const Offset(0, 2),
                                  ),
                                ]
                                : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: ColorFiltered(
                          colorFilter:
                              isOpen
                                  ? const ColorFilter.mode(
                                    Colors.transparent,
                                    BlendMode.multiply,
                                  )
                                  : ColorFilter.mode(
                                    Colors.grey.shade600,
                                    BlendMode.saturation,
                                  ),
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
                          if (description.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              description,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 12,
                                color:
                                    isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (!isOpen) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.error.withValues(
                                      alpha: 0.1,
                                    ),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Iconsax.clock,
                                        size: 12,
                                        color: AppColors.error,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'CLOSED',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.error,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (hoursText != null) ...[
                                Icon(
                                  Iconsax.clock,
                                  size: 14,
                                  color:
                                      isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiary,
                                ),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(
                                    hoursText,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color:
                                          isDark
                                              ? AppColors.textTertiaryDark
                                              : AppColors.textTertiary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ] else if (prepTime.isNotEmpty && isOpen) ...[
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
                                      ? AppColors.error.withValues(alpha: 0.1)
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
              ],
            ),
          ),
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
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06),
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _navItem(
            icon: Icons.restaurant_outlined,
            activeIcon: Icons.restaurant,
            index: 0,
            isDark: isDark,
          ),
          _navItem(
            icon: Icons.shopping_basket_outlined,
            activeIcon: Icons.shopping_basket,
            index: 1,
            isDark: isDark,
          ),
          _navItem(
            icon: Icons.receipt_long_outlined,
            activeIcon: Icons.receipt_long,
            index: 2,
            isDark: isDark,
          ),
          _navItem(
            icon: Icons.person_outline,
            activeIcon: Icons.person,
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
    required int index,
    required bool isDark,
  }) {
    bool active = selectedNav == index;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        setState(() => selectedNav = index);
      },
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          color:
              active
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          active ? activeIcon : icon,
          size: 26,
          color:
              active
                  ? Colors.white
                  : (isDark
                      ? AppColors.textTertiaryDark
                      : Colors.grey.shade600),
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

  // Per-store pickup settings
  final Map<String, bool> _pickupNowMap = {};
  final Map<String, DateTime?> _pickupTimeMap = {};

  // Store selection for checkout (which stores to place order for)
  final Map<String, bool> _selectedStores = {};

  // Cache for store info (fetched from Firestore when missing from cart items)
  final Map<String, Map<String, String>> _storeInfoCache = {};

  bool _getPickupNow(String storeId) => _pickupNowMap[storeId] ?? true;
  DateTime? _getPickupTime(String storeId) => _pickupTimeMap[storeId];

  void _setPickupNow(String storeId, bool value) {
    setState(() {
      _pickupNowMap[storeId] = value;
      if (value) _pickupTimeMap[storeId] = null;
    });
  }

  void _setPickupTime(String storeId, DateTime? time) {
    setState(() {
      _pickupTimeMap[storeId] = time;
      if (time != null) _pickupNowMap[storeId] = false;
    });
  }

  // Store selection methods (default to selected)
  bool _isStoreSelected(String storeId) => _selectedStores[storeId] ?? true;

  void _toggleStoreSelection(String storeId) {
    setState(() {
      _selectedStores[storeId] = !(_selectedStores[storeId] ?? true);
    });
  }

  // Check if store is currently open based on opening/closing times
  bool _isStoreOpen(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) return true;
    if (!openingTime.contains(':') || !closingTime.contains(':')) return true;

    try {
      final now = TimeOfDay.now();
      final nowMinutes = now.hour * 60 + now.minute;

      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final openMinutes = openHour * 60 + openMinute;

      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      final closeMinutes = closeHour * 60 + closeMinute;

      if (closeMinutes < openMinutes) {
        return nowMinutes >= openMinutes || nowMinutes < closeMinutes;
      } else {
        return nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      }
    } catch (e) {
      return true;
    }
  }

  // Fetch store info and cache it
  Future<Map<String, String>> _fetchStoreInfo(String storeId) async {
    if (_storeInfoCache.containsKey(storeId)) {
      return _storeInfoCache[storeId]!;
    }

    final storeDoc =
        await FirebaseFirestore.instance
            .collection("stores")
            .doc(storeId)
            .get();

    final data = storeDoc.data();
    final info = {
      'name': (data?['name'] ?? storeId).toString(),
      'logo': (data?['logoUrl'] ?? '').toString(),
    };

    _storeInfoCache[storeId] = info;
    return info;
  }

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

            // Group by store to calculate selected total
            final Map<String, List<QueryDocumentSnapshot>> storeGroups = {};
            for (var doc in docs) {
              final data = doc.data() as Map<String, dynamic>;
              final storeId = (data['storeId'] ?? '').toString();
              if (!storeGroups.containsKey(storeId)) {
                storeGroups[storeId] = [];
              }
              storeGroups[storeId]!.add(doc);
            }

            // Calculate total only for selected stores
            double selectedTotal = 0;
            for (var entry in storeGroups.entries) {
              if (_isStoreSelected(entry.key)) {
                for (var doc in entry.value) {
                  selectedTotal += (doc['lineTotal'] as num).toDouble();
                }
              }
            }

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
                        _orderDetailsSection(docs, isDark),
                      ],
                    ),
                  ),
                ),
                _bottomTotalBar(
                  total: selectedTotal,
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
                        ? AppColors.primaryLight.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
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

  Widget _pickupSection(String storeId, bool isDark) {
    final pickupNow = _getPickupNow(storeId);
    final pickupTime = _getPickupTime(storeId);

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
            onTap: () => _setPickupNow(storeId, true),
          ),
          const SizedBox(height: 10),
          _pickupOption(
            title: "Pick up later",
            subtitle:
                pickupTime == null
                    ? "Set your pick up time."
                    : "Scheduled: ${pickupTime.hour.toString().padLeft(2, '0')}:${pickupTime.minute.toString().padLeft(2, '0')}",
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
              final dt = await PickupTimePicker.show(
                context,
                initialTime:
                    pickupTime ??
                    DateTime.now().add(const Duration(minutes: 30)),
              );
              if (dt != null) {
                _setPickupTime(storeId, dt);
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
    // Group items by store
    final Map<String, List<QueryDocumentSnapshot>> storeGroups = {};
    final Map<String, String> storeNames = {};
    final Map<String, String> storeLogos = {};

    for (var doc in docs) {
      final data = doc.data() as Map<String, dynamic>;
      final storeId = (data['storeId'] ?? '').toString();
      final storeName = (data['storeName'] ?? storeId).toString();
      final storeLogo = (data['storeLogo'] ?? '').toString();

      if (!storeGroups.containsKey(storeId)) {
        storeGroups[storeId] = [];
        storeNames[storeId] = storeName;
        storeLogos[storeId] = storeLogo;
      }
      storeGroups[storeId]!.add(doc);
    }

    final storeIds = storeGroups.keys.toList();

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
                          ? AppColors.primaryLight.withValues(alpha: 0.1)
                          : AppColors.primary.withValues(alpha: 0.1),
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
        // Group items by store
        ...storeIds.map((storeId) {
          final cartStoreName = storeNames[storeId] ?? '';
          final cartStoreLogo = storeLogos[storeId] ?? '';
          final storeItems = storeGroups[storeId]!;

          // Calculate store subtotal
          double storeTotal = 0;
          for (var item in storeItems) {
            final d = item.data() as Map<String, dynamic>;
            final lt = d['lineTotal'];
            if (lt is num) storeTotal += lt.toDouble();
          }

          // Check if storeName is missing or looks like a store ID (20+ chars and alphanumeric)
          final needsFetch =
              cartStoreName.isEmpty ||
              cartStoreName == storeId ||
              (cartStoreName.length >= 20 &&
                  RegExp(r'^[a-zA-Z0-9]+$').hasMatch(cartStoreName));

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Store Header with FutureBuilder if name needs fetching
              needsFetch
                  ? FutureBuilder<Map<String, String>>(
                    future: _fetchStoreInfo(storeId),
                    builder: (context, snapshot) {
                      final storeName = snapshot.data?['name'] ?? storeId;
                      final storeLogo = snapshot.data?['logo'] ?? '';
                      return _buildStoreHeader(
                        storeId,
                        storeName,
                        storeLogo,
                        storeTotal,
                        isDark,
                      );
                    },
                  )
                  : _buildStoreHeader(
                    storeId,
                    cartStoreName,
                    cartStoreLogo,
                    storeTotal,
                    isDark,
                  ),
              // Pickup Time Section for this store
              _pickupSection(storeId, isDark),
              const SizedBox(height: 12),
              // Store Items Container
              Container(
                margin: const EdgeInsets.only(bottom: 24),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.surfaceDark : const Color(0xFFF7F7F7),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                  ),
                ),
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  children: storeItems.map((d) => _cartRow(d, isDark)).toList(),
                ),
              ),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildStoreHeader(
    String storeId,
    String storeName,
    String storeLogo,
    double storeTotal,
    bool isDark,
  ) {
    final isSelected = _isStoreSelected(storeId);

    return GestureDetector(
      onTap: () => _toggleStoreSelection(storeId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? (isDark
                      ? AppColors.primaryLight.withValues(alpha: 0.15)
                      : AppColors.primary.withValues(alpha: 0.1))
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color:
                isSelected
                    ? (isDark ? AppColors.primaryLight : AppColors.primary)
                    : Colors.transparent,
            width: isSelected ? 2 : 0,
          ),
        ),
        child: Row(
          children: [
            // Checkbox
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color:
                    isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color:
                      isSelected
                          ? (isDark
                              ? AppColors.primaryLight
                              : AppColors.primary)
                          : (isDark
                              ? AppColors.borderDark
                              : Colors.grey.shade400),
                  width: 2,
                ),
              ),
              child:
                  isSelected
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
            ),
            const SizedBox(width: 10),
            if (storeLogo.isNotEmpty)
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: Image.network(
                  storeLogo,
                  width: 24,
                  height: 24,
                  fit: BoxFit.cover,
                  errorBuilder:
                      (_, __, ___) => Icon(
                        Icons.store,
                        size: 20,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                      ),
                ),
              )
            else
              Icon(
                Icons.store,
                size: 20,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                storeName,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color:
                      isSelected
                          ? (isDark
                              ? AppColors.primaryLight
                              : AppColors.primary)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary),
                ),
              ),
            ),
            Text(
              "₱ ${storeTotal.toStringAsFixed(0)}",
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color:
                    isSelected
                        ? (isDark ? AppColors.primaryLight : AppColors.primary)
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _cartRow(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final productName = data['productName'] ?? '';
    final imageUrl = data['imageUrl'] ?? '';
    final qty = (data['quantity'] as num).toInt();
    final lineTotal = (data['lineTotal'] as num).toDouble();
    final storeId = (data['storeId'] ?? '').toString();
    final productId = (data['productId'] ?? '').toString();

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
      final sizeName = data['sizeName'] ?? '';
      if (sizeName.isNotEmpty) parts.add(sizeName);
    }

    if (selectedChoices.isNotEmpty) {
      for (var choice in selectedChoices) {
        final name = choice['name']?.toString() ?? '';
        if (name.isNotEmpty) parts.add(name);
      }
    } else {
      // Legacy: sugarLevel, iceLevel
      final sugar = data['sugarLevel'] ?? '';
      final ice = data['iceLevel'] ?? '';
      if (sugar.isNotEmpty) parts.add(sugar);
      if (ice.isNotEmpty) parts.add(ice);
    }

    final subtitle = parts.join(' • ');

    final unitPrice = qty > 0 ? (lineTotal / qty) : 0.0;

    return GestureDetector(
      onTap: () {
        // Navigate to product detail page
        if (storeId.isNotEmpty && productId.isNotEmpty) {
          showModalBottomSheet(
            context: context,
            backgroundColor: Colors.transparent,
            isScrollControlled: true,
            builder: (_) => ProductPage(storeId: storeId, productId: productId),
          );
        }
      },
      child: Container(
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
                      color:
                          isDark ? AppColors.borderDark : Colors.grey.shade200,
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
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
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
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
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
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
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
                  total > 0 ? "Total" : "Select stores",
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
                  total > 0
                      ? "\u20b1 ${total.toStringAsFixed(0)}"
                      : "Tap to select",
                  style: TextStyle(
                    fontSize: total > 0 ? 20 : 16,
                    fontWeight: FontWeight.w700,
                    color:
                        total > 0
                            ? (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary)
                            : (isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary),
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
                  disabledBackgroundColor:
                      isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                onPressed:
                    total <= 0
                        ? null
                        : () async {
                          try {
                            if (docs.isEmpty) {
                              throw Exception("Cart is empty");
                            }

                            // Group items by store (only selected stores)
                            final Map<String, List<Map<String, dynamic>>>
                            storeItemsMap = {};
                            final List<String> cartItemIdsToDelete = [];

                            for (var doc in docs) {
                              final data = doc.data() as Map<String, dynamic>;
                              final storeId =
                                  (data['storeId'] ?? '').toString();
                              if (storeId.isEmpty) continue;

                              // Only include selected stores
                              if (!_isStoreSelected(storeId)) continue;

                              if (!storeItemsMap.containsKey(storeId)) {
                                storeItemsMap[storeId] = [];
                              }
                              storeItemsMap[storeId]!.add(data);
                              cartItemIdsToDelete.add(doc.id);
                            }

                            if (storeItemsMap.isEmpty) {
                              throw Exception("No stores selected");
                            }

                            // Check all stores are open before placing any orders
                            for (final storeId in storeItemsMap.keys) {
                              final storeDoc =
                                  await FirebaseFirestore.instance
                                      .collection("stores")
                                      .doc(storeId)
                                      .get();

                              if (storeDoc.exists) {
                                final storeData =
                                    storeDoc.data() as Map<String, dynamic>;
                                final openingTime =
                                    storeData['openingTime']?.toString();
                                final closingTime =
                                    storeData['closingTime']?.toString();
                                final storeName =
                                    storeData['name']?.toString() ?? 'Store';

                                if (!_isStoreOpen(openingTime, closingTime)) {
                                  throw Exception(
                                    '$storeName is currently closed. Please try again during operating hours.',
                                  );
                                }
                              }
                            }

                            // Place order for each selected store
                            for (final entry in storeItemsMap.entries) {
                              final storeId = entry.key;
                              final items = entry.value;

                              // Calculate store total
                              final storeTotal = items.fold<double>(
                                0,
                                (acc, item) =>
                                    acc +
                                    ((item['lineTotal'] as num?)?.toDouble() ??
                                        0),
                              );

                              // Get store name from items or fetch from Firestore
                              String storeName =
                                  (items.first['storeName'] ?? '').toString();
                              if (storeName.isEmpty) {
                                final storeDoc =
                                    await FirebaseFirestore.instance
                                        .collection("stores")
                                        .doc(storeId)
                                        .get();
                                storeName =
                                    (storeDoc.data()?["name"] ??
                                            "Unknown Store")
                                        .toString();
                              }

                              // Get pickup settings for this store
                              final pickupNow = _getPickupNow(storeId);
                              final pickupTime = _getPickupTime(storeId);

                              // Place order for this store
                              await OrderService().placeOrder(
                                storeId: storeId,
                                storeName: storeName,
                                items: items,
                                total: storeTotal,
                                pickupNow: pickupNow,
                                pickupTime: pickupTime,
                              );
                            }

                            // Delete only the ordered cart items
                            for (final itemId in cartItemIdsToDelete) {
                              await CartService.deleteItem(itemId);
                            }

                            if (!mounted) return;
                            await AppModalDialog.success(
                              context: context,
                              title: 'Order Successful!',
                              message:
                                  storeItemsMap.length > 1
                                      ? '${storeItemsMap.length} orders have been placed successfully.'
                                      : 'Your order has been placed successfully.',
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
