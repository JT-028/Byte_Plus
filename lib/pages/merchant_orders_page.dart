// lib/pages/merchant_orders_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';
import '../widgets/app_modal_dialog.dart';

class MerchantOrdersPage extends StatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> {
  int tabIndex = 0;
  String? storeName;
  String? storeLogo;

  String get merchantUid => FirebaseAuth.instance.currentUser!.uid;

  final List<_MerchantTab> tabs = const [
    _MerchantTab(label: "New", status: "to-do"),
    _MerchantTab(label: "Preparing", status: "in-progress"),
    _MerchantTab(label: "Ready", status: "ready"),
    _MerchantTab(label: "Completed", status: "done"),
    _MerchantTab(label: "Canceled", status: "cancelled"),
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection("users")
              .doc(merchantUid)
              .get(),
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!userSnap.hasData || !userSnap.data!.exists) {
              return const Center(child: Text("Merchant profile not found."));
            }

            final userData = userSnap.data!.data() as Map<String, dynamic>;
            final storeId = (userData["storeId"] ?? "").toString();

            if (storeId.isEmpty) {
              return const Center(
                child: Text("No storeId found in your user document."),
              );
            }

            return _loadStoreAndBuildPage(storeId, isDark);
          },
        ),
      ),
    );
  }

  Widget _loadStoreAndBuildPage(String storeId, bool isDark) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection("stores").doc(storeId).get(),
      builder: (context, storeSnap) {
        if (storeSnap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (storeSnap.hasData && storeSnap.data!.exists) {
          final storeData = storeSnap.data!.data() as Map<String, dynamic>;
          storeName = storeData["name"]?.toString();
          storeLogo = storeData["logoUrl"]?.toString();
        }

        return _page(storeId, isDark);
      },
    );
  }

  Widget _page(String storeId, bool isDark) {
    return Column(
      children: [
        _topHeader(isDark, storeId),
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                _ordersTitle(storeId, isDark),
                const SizedBox(height: 12),
                _tabsRow(isDark),
                const SizedBox(height: 8),
                Expanded(child: _ordersList(storeId, isDark)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _topHeader(bool isDark, String storeId) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      decoration: const BoxDecoration(
        color: AppColors.primary,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Expanded(
            child: Text(
              "BytePlus",
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          // Store logo
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: storeLogo != null && storeLogo!.isNotEmpty
                  ? Image.network(
                      storeLogo!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _defaultLogo(),
                    )
                  : _defaultLogo(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _defaultLogo() {
    return Container(
      color: Colors.grey.shade200,
      child: const Center(
        child: Icon(Icons.store, color: Colors.grey, size: 24),
      ),
    );
  }

  Widget _ordersTitle(String storeId, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("stores")
          .doc(storeId)
          .collection("orders")
          .snapshots(),
      builder: (context, snap) {
        final count = snap.data?.docs.length ?? 0;
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: RichText(
            text: TextSpan(
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              children: [
                const TextSpan(text: "Orders "),
                TextSpan(
                  text: "($count)",
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _tabsRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: List.generate(tabs.length, (i) {
          final active = tabIndex == i;
          return GestureDetector(
            onTap: () => setState(() => tabIndex = i),
            child: Container(
              padding: const EdgeInsets.only(right: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tabs[i].label,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                      color: active
                          ? (isDark ? AppColors.textPrimaryDark : AppColors.textPrimary)
                          : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2,
                    width: 40,
                    color: active ? AppColors.primary : Colors.transparent,
                  ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _ordersList(String storeId, bool isDark) {
    final selectedStatus = tabs[tabIndex].status;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("stores")
          .doc(storeId)
          .collection("orders")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allDocs = snap.data!.docs;
        final filtered = allDocs.where((d) {
          final data = d.data() as Map<String, dynamic>;
          return (data["status"] ?? "").toString() == selectedStatus;
        }).toList();

        if (allDocs.isEmpty) {
          return _emptyState("No Orders Yet", isDark);
        }

        if (filtered.isEmpty) {
          return _emptyState("No ${tabs[tabIndex].label} Orders", isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          itemCount: filtered.length,
          itemBuilder: (_, i) {
            final doc = filtered[i];
            final data = doc.data() as Map<String, dynamic>;
            return _orderCard(
              storeId: storeId,
              orderId: (data["orderId"] ?? doc.id).toString(),
              userId: (data["userId"] ?? "").toString(),
              data: data,
              isDark: isDark,
            );
          },
        );
      },
    );
  }

  Widget _emptyState(String title, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _orderCard({
    required String storeId,
    required String orderId,
    required String userId,
    required Map<String, dynamic> data,
    required bool isDark,
  }) {
    final status = (data["status"] ?? "").toString();
    final total = (data["total"] as num? ?? 0).toDouble();
    final items = (data["items"] is List) ? (data["items"] as List) : <dynamic>[];
    final note = (data["note"] ?? "").toString();
    
    // Pickup time
    final pickupNow = (data["pickupNow"] ?? true) == true;
    final pickupTime = data["pickupTime"];
    final formattedTime = pickupNow ? null : _formatPickupTime(pickupTime);

    // Generate pickup number from orderId (last 3 chars uppercase with A prefix)
    final pickupNumber = "A${orderId.length > 2 ? orderId.substring(orderId.length - 2).toUpperCase() : orderId.toUpperCase()}";

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
        boxShadow: isDark
            ? []
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Order number + Pickup time
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "#$pickupNumber",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                ),
              ),
              if (formattedTime != null || pickupNow)
                Text(
                  pickupNow ? "Pickup: Now" : "Pickup by: $formattedTime",
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Items list
          ...items.map((item) => _itemRow(item, total, isDark)).toList(),

          // Note
          if (note.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              "Note: $note",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
              ),
            ),
          ] else ...[
            const SizedBox(height: 8),
            Text(
              "Note:",
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
              ),
            ),
          ],

          const SizedBox(height: 16),

          // Actions
          _actionsRow(
            status: status,
            onAccept: () => _handleAccept(storeId, orderId, userId),
            onReject: () => _handleReject(storeId, orderId, userId),
            onMarkReady: () => _handleMarkReady(storeId, orderId, userId),
            onPickedUp: () => _handlePickedUp(storeId, orderId, userId),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _itemRow(dynamic item, double total, bool isDark) {
    final itemMap = item as Map<String, dynamic>;
    final name = (itemMap["productName"] ?? "").toString();
    final qty = (itemMap["quantity"] as num? ?? 1).toInt();
    final lineTotal = (itemMap["lineTotal"] as num? ?? 0).toDouble();
    
    // Get variations/customizations
    final selectedVariation = itemMap["selectedVariation"];
    final selectedChoices = itemMap["selectedChoices"];
    
    List<String> variations = [];
    if (selectedVariation != null && selectedVariation is Map) {
      variations.add(selectedVariation["name"]?.toString() ?? "");
    }
    if (selectedChoices != null && selectedChoices is Map) {
      selectedChoices.forEach((groupName, choices) {
        if (choices is List) {
          for (var choice in choices) {
            if (choice is Map && choice["name"] != null) {
              variations.add(choice["name"].toString());
            }
          }
        }
      });
    }
    variations = variations.where((v) => v.isNotEmpty).toList();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  "${qty}x $name",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
                  ),
                ),
              ),
              Text(
                "₱ ${lineTotal.toStringAsFixed(2)}",
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (variations.isNotEmpty) ...[
            const SizedBox(height: 4),
            ...variations.map((v) => Padding(
              padding: const EdgeInsets.only(left: 8, top: 2),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    v,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            )).toList(),
          ],
        ],
      ),
    );
  }

  Widget _actionsRow({
    required String status,
    required VoidCallback onAccept,
    required VoidCallback onReject,
    required VoidCallback onMarkReady,
    required VoidCallback onPickedUp,
    required bool isDark,
  }) {
    if (status == "to-do") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onAccept,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Accept",
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: onReject,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              child: const Text(
                "Reject",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      );
    }

    if (status == "in-progress") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onMarkReady,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "Mark as Ready",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    if (status == "ready") {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: onPickedUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14),
          ),
          child: const Text(
            "Picked Up",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    }

    // Completed and Canceled: no actions
    return const SizedBox.shrink();
  }

  // Action handlers
  Future<void> _handleAccept(String storeId, String orderId, String userId) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Accept Order?',
      message: 'This will move the order to Preparing.',
      confirmLabel: 'Accept',
      cancelLabel: 'Cancel',
    );

    if (ok == true) {
      await _updateOrderStatusEverywhere(
        storeId: storeId,
        orderId: orderId,
        userId: userId,
        newStatus: "in-progress",
        extra: {
          "acceptedAt": FieldValue.serverTimestamp(),
          "acceptedBy": merchantUid,
        },
      );

      if (!mounted) return;
      await AppModalDialog.success(
        context: context,
        title: 'Order Accepted',
        message: 'The order is now being prepared.',
      );
    }
  }

  Future<void> _handleReject(String storeId, String orderId, String userId) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Reject Order?',
      message: 'This will cancel the order.',
      confirmLabel: 'Reject',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      await _updateOrderStatusEverywhere(
        storeId: storeId,
        orderId: orderId,
        userId: userId,
        newStatus: "cancelled",
        extra: {
          "cancelledAt": FieldValue.serverTimestamp(),
          "cancelledBy": merchantUid,
          "cancelledByRole": "staff",
        },
      );

      if (!mounted) return;
      await AppModalDialog.info(
        context: context,
        title: 'Order Rejected',
        message: 'The order has been cancelled.',
      );
    }
  }

  Future<void> _handleMarkReady(String storeId, String orderId, String userId) async {
    await _updateOrderStatusEverywhere(
      storeId: storeId,
      orderId: orderId,
      userId: userId,
      newStatus: "ready",
      extra: {
        "readyAt": FieldValue.serverTimestamp(),
        "readyBy": merchantUid,
      },
    );

    if (!mounted) return;
    await AppModalDialog.success(
      context: context,
      title: 'Order Ready',
      message: 'The order is now ready for pickup.',
    );
  }

  Future<void> _handlePickedUp(String storeId, String orderId, String userId) async {
    await _updateOrderStatusEverywhere(
      storeId: storeId,
      orderId: orderId,
      userId: userId,
      newStatus: "done",
      extra: {
        "completedAt": FieldValue.serverTimestamp(),
        "completedBy": merchantUid,
      },
    );

    if (!mounted) return;
    await AppModalDialog.success(
      context: context,
      title: 'Order Completed',
      message: 'The order has been picked up.',
    );
  }

  String? _formatPickupTime(dynamic pickupTime) {
    if (pickupTime == null) return null;

    DateTime? dt;
    if (pickupTime is String) {
      dt = DateTime.tryParse(pickupTime);
    } else if (pickupTime is Timestamp) {
      dt = pickupTime.toDate();
    }

    if (dt == null) return null;

    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final minute = dt.minute.toString().padLeft(2, '0');
    final ampm = dt.hour >= 12 ? "PM" : "AM";
    return "$hour:$minute $ampm";
  }

  Future<void> _updateOrderStatusEverywhere({
    required String storeId,
    required String orderId,
    required String userId,
    required String newStatus,
    Map<String, dynamic>? extra,
  }) async {
    if (userId.isEmpty) {
      throw Exception("Missing userId on order. Cannot update everywhere.");
    }

    final db = FirebaseFirestore.instance;

    final payload = <String, dynamic>{
      "status": newStatus,
      "statusUpdatedAt": FieldValue.serverTimestamp(),
      ...?extra,
    };

    final storeRef = db
        .collection("stores")
        .doc(storeId)
        .collection("orders")
        .doc(orderId);
    final userRef = db
        .collection("users")
        .doc(userId)
        .collection("orders")
        .doc(orderId);
    final globalRef = db.collection("orders").doc(orderId);

    // Update store + user (required)
    final batch = db.batch();
    batch.update(storeRef, payload);
    batch.update(userRef, payload);
    await batch.commit();

    // Update global if it exists
    try {
      await globalRef.update(payload);
    } catch (e) {
      debugPrint("⚠️ Global /orders/$orderId missing. Skipping.");
    }

    // Send push notification
    try {
      await NotificationService.sendOrderStatusNotification(
        orderId: orderId,
        storeId: storeId,
        customerId: userId,
        status: newStatus,
        storeName: storeName ?? 'Your store',
        pickupNumber: null,
      );
    } catch (e) {
      debugPrint("⚠️ Failed to send notification: $e");
    }
  }
}

class _MerchantTab {
  final String label;
  final String status;
  const _MerchantTab({required this.label, required this.status});
}
