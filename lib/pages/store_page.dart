// lib/pages/store_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import 'product_page.dart';
import 'cart_store_sheet.dart';

class StorePage extends StatefulWidget {
  final String storeId;
  final String name;
  final String description;
  final String type;
  final String prepTime;
  final String logoUrl;
  final String bannerUrl;
  final String? openingTime;
  final String? closingTime;

  const StorePage({
    super.key,
    required this.storeId,
    required this.name,
    this.description = '',
    required this.type,
    required this.prepTime,
    required this.logoUrl,
    required this.bannerUrl,
    this.openingTime,
    this.closingTime,
  });

  @override
  State<StorePage> createState() => _StorePageState();
}

class _StorePageState extends State<StorePage> {
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  List<String> categories = ["Popular"];
  String selectedCategory = "Popular";

  final ScrollController scrollController = ScrollController();
  final Map<String, GlobalKey> sectionKeys = {};
  bool _showScrollToTop = false;

  @override
  void initState() {
    super.initState();
    loadCategories();
    scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    scrollController.removeListener(_onScroll);
    scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final show = scrollController.offset > 300;
    if (show != _showScrollToTop) {
      setState(() => _showScrollToTop = show);
    }
  }

  Future<void> loadCategories() async {
    final snap =
        await FirebaseFirestore.instance
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

    // Find the render object and calculate position relative to scroll view
    final renderBox = ctx.findRenderObject() as RenderBox?;
    if (renderBox == null) return;

    final scrollableState = Scrollable.of(ctx);
    final scrollPosition = scrollableState.position;
    final viewport = RenderAbstractViewport.of(renderBox);
    final targetOffset = viewport.getOffsetToReveal(renderBox, 0.0).offset;

    // Subtract sticky header height (60) + a small padding
    final adjustedOffset = (targetOffset - 68).clamp(
      0.0,
      scrollPosition.maxScrollExtent,
    );

    scrollController.animateTo(
      adjustedOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            CustomScrollView(
              controller: scrollController,
              slivers: [
                SliverToBoxAdapter(child: _buildHeader(isDark)),
                SliverPersistentHeader(
                  pinned: true,
                  delegate: _StickyCategoryBar(
                    categories: categories,
                    selectedCategory: selectedCategory,
                    isDark: isDark,
                    onSelected: (cat) {
                      setState(() => selectedCategory = cat);
                      scrollToCategory(cat);
                    },
                  ),
                ),
                _buildMenuSections(isDark),
                const SliverToBoxAdapter(child: SizedBox(height: 200)),
              ],
            ),

            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: _storeCartBar(isDark),
            ),

            // Floating scroll-to-top button
            Positioned(
              right: 16,
              bottom: 100,
              child: AnimatedOpacity(
                opacity: _showScrollToTop ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 250),
                child: IgnorePointer(
                  ignoring: !_showScrollToTop,
                  child: GestureDetector(
                    onTap: () {
                      scrollController.animateTo(
                        0,
                        duration: const Duration(milliseconds: 400),
                        curve: Curves.easeOut,
                      );
                    },
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.keyboard_arrow_up_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
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
            errorBuilder:
                (_, __, ___) => Container(
                  height: 200,
                  color:
                      isDark
                          ? AppColors.surfaceVariantDark
                          : Colors.grey.shade300,
                  child: Icon(
                    Iconsax.image,
                    size: 48,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
          ),
        ),

        Positioned(
          top: 16,
          left: 16,
          child: _circleBtn(
            Iconsax.arrow_left,
            () => Navigator.pop(context),
            isDark: isDark,
          ),
        ),

        Positioned(
          top: 16,
          right: 16,
          child: StreamBuilder<DocumentSnapshot>(
            stream:
                FirebaseFirestore.instance
                    .collection("users")
                    .doc(uid)
                    .collection("favorites")
                    .doc(widget.storeId)
                    .snapshots(),
            builder: (_, snap) {
              final isFav = snap.data?.exists ?? false;
              return _circleBtn(
                isFav ? Iconsax.heart : Iconsax.heart,
                _toggleFavorite,
                isDark: isDark,
                color: isFav ? AppColors.error : Colors.white,
              );
            },
          ),
        ),

        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: _storeInfoCard(isDark),
        ),
      ],
    );
  }

  Widget _circleBtn(
    IconData icon,
    VoidCallback onTap, {
    required bool isDark,
    Color color = Colors.black,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color:
              isDark
                  ? AppColors.surfaceDark.withOpacity(0.9)
                  : Colors.white.withOpacity(0.95),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Icon(icon, color: color, size: 22),
      ),
    );
  }

  Widget _storeInfoCard(bool isDark) {
    // Format operating hours
    String? hoursText;
    if (widget.openingTime != null && widget.closingTime != null) {
      hoursText =
          '${_formatTime(widget.openingTime!)} – ${_formatTime(widget.closingTime!)}';
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.12),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Image.network(
                widget.logoUrl,
                width: 60,
                height: 60,
                fit: BoxFit.cover,
                errorBuilder:
                    (_, __, ___) => Container(
                      width: 60,
                      height: 60,
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
                  widget.name,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                if (widget.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ],
                const SizedBox(height: 6),
                if (hoursText != null)
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
                      Flexible(
                        child: Text(
                          hoursText,
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  )
                else
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
                        widget.prepTime,
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String time) {
    if (!time.contains(':')) return time;
    final parts = time.split(':');
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final t = TimeOfDay(hour: hour, minute: minute);
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final p = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $p';
  }

  Widget _buildMenuSections(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection("stores")
              .doc(widget.storeId)
              .collection("menu")
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return SliverToBoxAdapter(
            child: Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
          );
        }

        final docs = snap.data!.docs;

        return SliverList(
          delegate: SliverChildListDelegate(
            categories.map((cat) {
              final items =
                  docs.where((d) {
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
                    Text(
                      cat,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
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
                        itemBuilder: (_, i) => _gridItem(items[i], isDark),
                      )
                    else
                      Column(
                        children:
                            items.map((doc) => _listItem(doc, isDark)).toList(),
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

  Widget _gridItem(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final isAvailable = data['isAvailable'] ?? true;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
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
          onTap: isAvailable ? () => _openProduct(doc.id) : null,
          child: Stack(
            children: [
              Opacity(
                opacity: isAvailable ? 1.0 : 0.5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data["imageUrl"] ?? '',
                            fit: BoxFit.contain,
                            errorBuilder:
                                (_, __, ___) => Container(
                                  color:
                                      isDark
                                          ? AppColors.surfaceVariantDark
                                          : Colors.grey.shade100,
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
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data["name"] ?? '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\u20b1${data["price"]}",
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color:
                              isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Out of Stock badge
              if (!isAvailable)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.error,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              if (qty > 0 && isAvailable)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color:
                          isDark ? AppColors.primaryLight : AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      qty.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _listItem(QueryDocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
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
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceDark : Colors.white,
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Stack(
              children: [
                Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        data["imageUrl"] ?? '',
                        width: 70,
                        height: 70,
                        fit: BoxFit.cover,
                        errorBuilder:
                            (_, __, ___) => Container(
                              width: 70,
                              height: 70,
                              color:
                                  isDark
                                      ? AppColors.surfaceVariantDark
                                      : Colors.grey.shade100,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        data["name"] ?? '',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      "\u20b1${data["price"]}",
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
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
                        color:
                            isDark ? AppColors.primaryLight : AppColors.primary,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withOpacity(0.3),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        qty.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
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
      builder:
          (_) => ProductPage(storeId: widget.storeId, productId: productId),
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

  Widget _storeCartBar(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
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
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withOpacity(0.3),
                blurRadius: 16,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: GestureDetector(
            onTap: () {
              showModalBottomSheet(
                context: context,
                backgroundColor: Colors.transparent,
                isScrollControlled: true,
                builder:
                    (_) => CartStoreSheet(
                      storeId: widget.storeId,
                      onGoToCheckout: () {
                        // Pop store page and return 'goToCart' signal
                        Navigator.pop(context, 'goToCart');
                      },
                    ),
              );
            },
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    itemCount.toString(),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 14),
                const Text(
                  "View Cart",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  "\u20b1${total.toStringAsFixed(0)}",
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(
                  Iconsax.arrow_right_3,
                  color: Colors.white,
                  size: 18,
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
  final bool isDark;

  _StickyCategoryBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
    required this.isDark,
  });

  @override
  Widget build(context, shrinkOffset, overlapsContent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.backgroundDark : Colors.white,
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children:
              categories.map((c) {
                final bool selected = c == selectedCategory;
                return GestureDetector(
                  onTap: () => onSelected(c),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    margin: const EdgeInsets.only(right: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          selected
                              ? (isDark
                                  ? AppColors.primaryLight
                                  : AppColors.primary)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            selected
                                ? (isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary)
                                : (isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade300),
                        width: selected ? 2 : 1,
                      ),
                      boxShadow:
                          selected
                              ? [
                                BoxShadow(
                                  color: AppColors.primary.withOpacity(0.25),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                              : null,
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        color:
                            selected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.w500,
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
  double get maxExtent => 60;

  @override
  double get minExtent => 60;

  @override
  bool shouldRebuild(_) => true;
}
