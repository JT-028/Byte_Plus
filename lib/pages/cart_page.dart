// lib/pages/cart_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

import '../theme/app_theme.dart';
import '../services/order_service.dart';
import '../widgets/app_modal_dialog.dart';
import 'product_page.dart';

class CartPage extends StatefulWidget {
  const CartPage({super.key});

  @override
  State<CartPage> createState() => _CartPageState();
}

class _CartPageState extends State<CartPage> {
  bool _placing = false;

  // temporary defaults (keep compatible with your future pickup UI)
  final bool _pickupNow = true;
  DateTime? _pickupTime;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          "Your Cart",
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        centerTitle: true,
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream:
            FirebaseFirestore.instance
                .collection("users")
                .doc(uid)
                .collection("cartItems")
                .orderBy("createdAt", descending: false)
                .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snap.data!.docs.isEmpty) {
            return const Center(child: Text("Your cart is empty."));
          }

          final docs = snap.data!.docs;

          double total = 0;
          for (var d in docs) {
            final lt = d.get('lineTotal');
            if (lt is num) total += lt.toDouble();
          }

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
            children: [
              Expanded(
                child: ListView.builder(
                  itemCount: storeIds.length,
                  itemBuilder: (context, storeIndex) {
                    final storeId = storeIds[storeIndex];
                    final storeName = storeNames[storeId] ?? storeId;
                    final storeLogo = storeLogos[storeId] ?? '';
                    final storeItems = storeGroups[storeId]!;

                    // Calculate store subtotal
                    double storeTotal = 0;
                    for (var item in storeItems) {
                      final d = item.data() as Map<String, dynamic>;
                      final lt = d['lineTotal'];
                      if (lt is num) storeTotal += lt.toDouble();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Store Header
                        Container(
                          margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.primaryLight.withOpacity(0.15)
                                    : AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              if (storeLogo.isNotEmpty)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(6),
                                  child: Image.network(
                                    storeLogo,
                                    width: 28,
                                    height: 28,
                                    fit: BoxFit.cover,
                                    errorBuilder:
                                        (_, __, ___) => Icon(
                                          Icons.store,
                                          size: 24,
                                          color:
                                              isDark
                                                  ? AppColors.primaryLight
                                                  : AppColors.primary,
                                        ),
                                  ),
                                )
                              else
                                Icon(
                                  Icons.store,
                                  size: 24,
                                  color:
                                      isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  storeName,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color:
                                        isDark
                                            ? AppColors.primaryLight
                                            : AppColors.primary,
                                  ),
                                ),
                              ),
                              Text(
                                "₱ ${storeTotal.toStringAsFixed(0)}",
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isDark
                                          ? AppColors.primaryLight
                                          : AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Store Items
                        ...storeItems.map((doc) {
                          final data = doc.data() as Map<String, dynamic>;
                          final id = doc.id;
                          final productId =
                              (data['productId'] ?? '').toString();

                          return GestureDetector(
                            onTap: () {
                              // Navigate to product detail page
                              if (storeId.isNotEmpty && productId.isNotEmpty) {
                                showModalBottomSheet(
                                  context: context,
                                  backgroundColor: Colors.transparent,
                                  isScrollControlled: true,
                                  builder:
                                      (_) => ProductPage(
                                        storeId: storeId,
                                        productId: productId,
                                      ),
                                );
                              }
                            },
                            child: Container(
                              margin: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 6,
                              ),
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.surfaceDark
                                        : Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(
                                      isDark ? 0.2 : 0.06,
                                    ),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Image.network(
                                      (data['imageUrl'] ?? '').toString(),
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      errorBuilder:
                                          (_, __, ___) => const Icon(
                                            Icons.image_not_supported,
                                          ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          (data['productName'] ?? '')
                                              .toString(),
                                          style: TextStyle(
                                            fontWeight: FontWeight.w600,
                                            color:
                                                isDark
                                                    ? AppColors.textPrimaryDark
                                                    : AppColors.textPrimary,
                                          ),
                                        ),
                                        // Price - use variationPrice if available, fallback to sizePrice
                                        Builder(
                                          builder: (context) {
                                            final variationPrice =
                                                (data['variationPrice'] as num?)
                                                    ?.toDouble() ??
                                                0;
                                            final sizePrice =
                                                (data['sizePrice'] as num?)
                                                    ?.toDouble() ??
                                                0;
                                            final price =
                                                variationPrice > 0
                                                    ? variationPrice
                                                    : sizePrice;
                                            return Text(
                                              "₱ ${price.toStringAsFixed(0)}",
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                        // Variation/Size - new structure first, fallback to legacy
                                        Builder(
                                          builder: (context) {
                                            final variationName =
                                                (data['variationName'] ?? '')
                                                    .toString();
                                            final sizeName =
                                                (data['sizeName'] ?? '')
                                                    .toString();
                                            final displayName =
                                                variationName.isNotEmpty
                                                    ? variationName
                                                    : sizeName;
                                            if (displayName.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return Text(
                                              displayName,
                                              style: TextStyle(
                                                color:
                                                    isDark
                                                        ? AppColors
                                                            .textSecondaryDark
                                                        : AppColors
                                                            .textSecondary,
                                              ),
                                            );
                                          },
                                        ),
                                        // Selected choices (new structure)
                                        Builder(
                                          builder: (context) {
                                            final selectedChoices =
                                                List<Map<String, dynamic>>.from(
                                                  data['selectedChoices'] ?? [],
                                                );
                                            if (selectedChoices.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            final names = selectedChoices
                                                .map(
                                                  (c) =>
                                                      c['name']?.toString() ??
                                                      '',
                                                )
                                                .where((n) => n.isNotEmpty)
                                                .join(', ');
                                            if (names.isEmpty) {
                                              return const SizedBox.shrink();
                                            }
                                            return Text(
                                              names,
                                              style: TextStyle(
                                                fontSize: 12,
                                                color:
                                                    isDark
                                                        ? AppColors
                                                            .textTertiaryDark
                                                        : AppColors
                                                            .textTertiary,
                                              ),
                                            );
                                          },
                                        ),
                                        Text(
                                          "Qty: ${(data['quantity'] ?? 1).toString()}",
                                          style: TextStyle(
                                            color:
                                                isDark
                                                    ? AppColors
                                                        .textSecondaryDark
                                                    : AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      Icons.delete,
                                      color:
                                          isDark
                                              ? AppColors.textSecondaryDark
                                              : AppColors.textSecondary,
                                    ),
                                    onPressed: () async {
                                      await FirebaseFirestore.instance
                                          .collection("users")
                                          .doc(uid)
                                          .collection("cartItems")
                                          .doc(id)
                                          .delete();
                                    },
                                  ),
                                ],
                              ),
                            ),
                          );
                        }),
                        if (storeIndex < storeIds.length - 1)
                          Divider(
                            height: 24,
                            indent: 16,
                            endIndent: 16,
                            color:
                                isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade300,
                          ),
                      ],
                    );
                  },
                ),
              ),

              // -------- BOTTOM TOTAL BAR ----------
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(20),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Total",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          "₱ ${total.toStringAsFixed(0)}",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed:
                          _placing
                              ? null
                              : () async {
                                await _placeOrder(
                                  uid: uid,
                                  cartDocs: docs,
                                  total: total,
                                );
                              },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        minimumSize: const Size(double.infinity, 48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child:
                          _placing
                              ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                              : const Text(
                                "Place Order",
                                style: TextStyle(color: Colors.white),
                              ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  bool _isStoreOpen(String? openingTime, String? closingTime) {
    // If hours aren't set, consider store open (merchant hasn't configured hours)
    if (openingTime == null ||
        closingTime == null ||
        openingTime.isEmpty ||
        closingTime.isEmpty) {
      debugPrint('Store hours not set - defaulting to open');
      return true;
    }
    if (!openingTime.contains(':') || !closingTime.contains(':')) {
      debugPrint('Invalid store hours format');
      return true;
    }

    try {
      final now = DateTime.now();
      final nowMinutes = now.hour * 60 + now.minute;

      final openParts = openingTime.split(':');
      final openHour = int.parse(openParts[0]);
      final openMinute = int.parse(openParts[1]);
      final openMinutes = openHour * 60 + openMinute;

      final closeParts = closingTime.split(':');
      final closeHour = int.parse(closeParts[0]);
      final closeMinute = int.parse(closeParts[1]);
      final closeMinutes = closeHour * 60 + closeMinute;

      debugPrint(
        'Now: $nowMinutes min, Open: $openMinutes min, Close: $closeMinutes min',
      );

      // Handle overnight hours (e.g., 22:00 - 02:00)
      if (closeMinutes <= openMinutes) {
        final isOpen = nowMinutes >= openMinutes || nowMinutes < closeMinutes;
        debugPrint('Overnight hours - isOpen: $isOpen');
        return isOpen;
      }

      final isOpen = nowMinutes >= openMinutes && nowMinutes < closeMinutes;
      debugPrint('Normal hours - isOpen: $isOpen');
      return isOpen;
    } catch (e) {
      debugPrint('Error parsing store hours: $e');
      return true; // Default to open if parsing fails
    }
  }

  /// Check if user is within the store's geofence (if configured)
  /// Returns true if allowed to order, false if blocked
  Future<bool> _checkStoreGeofence(
    Map<String, dynamic> storeData,
    String storeName,
  ) async {
    // Get store geofence settings
    final double? storeLat = (storeData['latitude'] as num?)?.toDouble();
    final double? storeLng = (storeData['longitude'] as num?)?.toDouble();
    final double storeRadius =
        (storeData['geofenceRadius'] as num?)?.toDouble() ?? 0;

    // If no geofence configured for this store, allow ordering
    if (storeLat == null || storeLng == null || storeRadius <= 0) {
      debugPrint('[StoreGeofence] No geofence configured for $storeName');
      return true;
    }

    try {
      // Get user's current location
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      // Calculate distance from store
      final distance = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        storeLat,
        storeLng,
      );

      debugPrint(
        '[StoreGeofence] User at (${position.latitude}, ${position.longitude})',
      );
      debugPrint(
        '[StoreGeofence] Store at ($storeLat, $storeLng), radius: ${storeRadius}m',
      );
      debugPrint('[StoreGeofence] Distance: ${distance.toStringAsFixed(2)}m');

      if (distance > storeRadius) {
        // User is outside store's geofence
        if (!mounted) return false;
        await AppModalDialog.error(
          context: context,
          title: 'Out of Range',
          message:
              'You are ${distance.toInt()}m away from $storeName. '
              'Please move within ${storeRadius.toInt()}m of the store to place an order.',
        );
        return false;
      }

      return true; // User is within geofence
    } catch (e) {
      debugPrint('[StoreGeofence] Error checking location: $e');
      // If we can't get location, show error but don't block
      if (!mounted) return false;
      await AppModalDialog.error(
        context: context,
        title: 'Location Error',
        message:
            'Unable to verify your location. Please ensure location services are enabled.',
      );
      return false;
    }
  }

  Future<void> _placeOrder({
    required String uid,
    required List<QueryDocumentSnapshot> cartDocs,
    required double total,
  }) async {
    setState(() => _placing = true);

    try {
      final items =
          cartDocs.map((d) => (d.data() as Map<String, dynamic>)).toList();
      final first = items.isNotEmpty ? items.first : <String, dynamic>{};

      final storeId = (first['storeId'] ?? "").toString();
      final storeName = (first['storeName'] ?? storeId).toString();

      if (storeId.isEmpty) {
        throw Exception("Missing storeId in cart items.");
      }

      // Check if store is currently open
      final storeDoc =
          await FirebaseFirestore.instance
              .collection('stores')
              .doc(storeId)
              .get();

      if (!storeDoc.exists) {
        if (!mounted) return;
        setState(() => _placing = false);
        await AppModalDialog.error(
          context: context,
          title: 'Store Not Found',
          message: 'This store no longer exists.',
        );
        return;
      }

      final storeData = storeDoc.data() as Map<String, dynamic>;
      final openingTime = storeData['openingTime']?.toString();
      final closingTime = storeData['closingTime']?.toString();

      debugPrint(
        'Store hours check - Opening: $openingTime, Closing: $closingTime',
      );
      debugPrint(
        'Current time: ${TimeOfDay.now().hour}:${TimeOfDay.now().minute}',
      );
      debugPrint('Is store open: ${_isStoreOpen(openingTime, closingTime)}');

      if (!_isStoreOpen(openingTime, closingTime)) {
        if (!mounted) return;
        setState(() => _placing = false);
        await AppModalDialog.error(
          context: context,
          title: 'Store Closed',
          message:
              '$storeName is currently closed. Please try again during operating hours.',
        );
        return;
      }

      // Check if user is within store's geofence (if configured)
      final storeGeofenceCheck = await _checkStoreGeofence(
        storeData,
        storeName,
      );
      if (!storeGeofenceCheck) {
        if (!mounted) return;
        setState(() => _placing = false);
        return; // Dialog already shown in _checkStoreGeofence
      }

      final orderId = await OrderService().placeOrder(
        storeId: storeId,
        storeName: storeName,
        items: items,
        total: total,
        pickupNow: _pickupNow,
        pickupTime: _pickupTime,
      );

      // Clear cart after success
      final batch = FirebaseFirestore.instance.batch();
      for (final d in cartDocs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      if (!mounted) return;
      await AppModalDialog.success(
        context: context,
        title: 'Order Successful!',
        message: 'Your order #$orderId has been placed.',
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
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }
}
