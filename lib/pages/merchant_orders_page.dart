// lib/pages/merchant_orders_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class MerchantOrdersPage extends StatefulWidget {
  const MerchantOrdersPage({super.key});

  @override
  State<MerchantOrdersPage> createState() => _MerchantOrdersPageState();
}

class _MerchantOrdersPageState extends State<MerchantOrdersPage> {
  int tabIndex = 0;

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
          future:
              FirebaseFirestore.instance
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

            return _page(storeId, isDark);
          },
        ),
      ),
    );
  }

  Widget _page(String storeId, bool isDark) {
    return Column(
      children: [
        _topHeader(isDark),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18),
          child: _tabsRow(isDark),
        ),
        const SizedBox(height: 14),
        Expanded(child: _ordersList(storeId, isDark)),
      ],
    );
  }

  Widget _topHeader(bool isDark) {
    return Container(
      height: 120,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Expanded(
            child: Text(
              "BytePlus",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              "https://res.cloudinary.com/ddhamh7cy/image/upload/v1763312250/spcf_logo_wgqxdg.jpg",
              width: 38,
              height: 38,
              fit: BoxFit.cover,
              errorBuilder:
                  (_, __, ___) => const Icon(Icons.school, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // UI-like text tabs row (New Preparing Ready Completed Canceled)
  Widget _tabsRow(bool isDark) {
    return Row(
      children: List.generate(tabs.length, (i) {
        final active = tabIndex == i;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => tabIndex = i),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              alignment: Alignment.center,
              child: Column(
                children: [
                  Text(
                    tabs[i].label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: active ? FontWeight.w800 : FontWeight.w600,
                      color:
                          active
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    height: 2.2,
                    width: 34,
                    decoration: BoxDecoration(
                      color: active ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }),
    );
  }

  Widget _ordersList(String storeId, bool isDark) {
    final selectedStatus = tabs[tabIndex].status;

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
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

        // filter by status
        final filtered =
            allDocs.where((d) {
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
          padding: const EdgeInsets.fromLTRB(18, 4, 18, 18),
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
              Icons.receipt_long,
              size: 78,
              color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Orders will appear here once customers place them.",
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
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
    final storeName = (data["storeName"] ?? storeId).toString();
    final total = (data["total"] as num? ?? 0).toDouble();

    final items =
        (data["items"] is List) ? (data["items"] as List) : <dynamic>[];
    final firstItemName =
        items.isNotEmpty ? (items.first["productName"] ?? "").toString() : "";

    final pickupNow = (data["pickupNow"] ?? true) == true;
    final pickupTime = data["pickupTime"];

    // Supports future queue fields (optional)
    final queueNo =
        (data["queueNo"] ?? data["pickupNo"] ?? data["queue"] ?? "").toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? AppColors.borderDark : const Color(0xFFE6E6E6),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      storeName,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      firstItemName.isEmpty ? "Order" : firstItemName,
                      style: TextStyle(
                        fontSize: 12.5,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (queueNo.isNotEmpty)
                      Text(
                        "#$queueNo",
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
              ),
              _merchantStatusBadge(status),
            ],
          ),

          const SizedBox(height: 12),

          // Pickup time strip
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color:
                  isDark
                      ? AppColors.surfaceVariantDark
                      : const Color(0xFFF2F4FA),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: const Icon(
                    Icons.access_time,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Pickup time",
                        style: TextStyle(
                          fontSize: 12,
                          color:
                              isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        pickupNow
                            ? "Pick up now"
                            : (_formatPickupTime(pickupTime) ?? "Scheduled"),
                        style: TextStyle(
                          fontSize: 13.5,
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
              ],
            ),
          ),

          const SizedBox(height: 12),

          // Total row
          Row(
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
              const Spacer(),
              Text(
                "₱ ${total.toStringAsFixed(0)}",
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Actions
          _actionsRow(
            status: status,
            onAccept:
                () => _confirmAction(
                  title: "Accept this order?",
                  message: "This will move the order to Preparing.",
                  confirmText: "Accept",
                  confirmColor: AppColors.primary,
                  onConfirm: () async {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order accepted.")),
                    );
                  },
                ),
            onReject:
                () => _confirmAction(
                  title: "Reject / Cancel this order?",
                  message: "This will move the order to Canceled.",
                  confirmText: "Reject",
                  confirmColor: Colors.red,
                  onConfirm: () async {
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Order cancelled.")),
                    );
                  },
                ),
            onMarkReady: () async {
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
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text("Marked as ready.")));
            },
            onPickedUp: () async {
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
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Completed (Picked up).")),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _actionsRow({
    required String status,
    required Future<void> Function() onMarkReady,
    required Future<void> Function() onPickedUp,
    required VoidCallback onAccept,
    required VoidCallback onReject,
  }) {
    if (status == "to-do") {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onReject,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Reject",
                style: TextStyle(
                  color: Colors.black87,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ElevatedButton(
              onPressed: onAccept,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "Accept",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
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
        height: 44,
        child: ElevatedButton(
          onPressed: onMarkReady,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Mark as Ready",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    if (status == "ready") {
      return SizedBox(
        width: double.infinity,
        height: 44,
        child: ElevatedButton(
          onPressed: onPickedUp,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: const Text(
            "Picked Up",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
          ),
        ),
      );
    }

    return const SizedBox(height: 0);
  }

  Widget _merchantStatusBadge(String status) {
    Color bg;
    Color fg;
    String label;

    switch (status) {
      case "to-do":
        bg = AppColors.warningLight;
        fg = AppColors.warning;
        label = "New";
        break;
      case "in-progress":
        bg = const Color(0xFFE9EDFF);
        fg = AppColors.primary;
        label = "Preparing";
        break;
      case "ready":
        bg = AppColors.primary;
        fg = Colors.white;
        label = "Ready";
        break;
      case "done":
        bg = AppColors.successLight;
        fg = AppColors.success;
        label = "Completed";
        break;
      case "cancelled":
      default:
        bg = AppColors.errorLight;
        fg = AppColors.error;
        label = "Canceled";
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
          color: fg,
        ),
      ),
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

  Future<void> _confirmAction({
    required String title,
    required String message,
    required String confirmText,
    required Color confirmColor,
    required Future<void> Function() onConfirm,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("No"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: confirmColor),
              onPressed: () => Navigator.pop(context, true),
              child: Text(
                confirmText,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );

    if (ok == true) {
      await onConfirm();
    }
  }

  /// ✅ SAFE UPDATE:
  /// - Update store + user copies in ONE batch (these should exist)
  /// - Then try updating /orders/{orderId}; if missing, skip without crashing.
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

    // 1) Update store + user (required)
    final batch = db.batch();
    batch.update(storeRef, payload);
    batch.update(userRef, payload);
    await batch.commit();

    // 2) Update global if it exists (don’t break if missing)
    try {
      await globalRef.update(payload);
    } catch (e) {
      // ignore: avoid_print
      print(
        "⚠️ Global /orders/$orderId missing or blocked. Skipping. Error: $e",
      );
    }
    // 3) Send push notification to customer
    try {
      await NotificationService.sendOrderStatusNotification(
        orderId: orderId,
        storeId: storeId,
        customerId: userId,
        status: newStatus,
        storeName: 'Your store',
        pickupNumber: null,
      );
    } catch (e) {
      // ignore: avoid_print
      print("⚠️ Failed to send notification: $e");
    }
  }
}

class _MerchantTab {
  final String label;
  final String status;
  const _MerchantTab({required this.label, required this.status});
}
