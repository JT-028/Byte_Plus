// lib/pages/order_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

class OrdersPage extends StatefulWidget {
  const OrdersPage({super.key});

  @override
  State<OrdersPage> createState() => _OrdersPageState();
}

class _OrdersPageState extends State<OrdersPage> {
  int tabIndex = 0;
  String get uid => FirebaseAuth.instance.currentUser!.uid;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            Text(
              "My Orders",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 20),

            _tabBar(isDark),

            const SizedBox(height: 12),

            Expanded(child: _ordersList(isDark)),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP TAB BAR (Active / History)
  // -------------------------------------------------------------
  Widget _tabBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabButton("Active", 0, isDark),
        const SizedBox(width: 18),
        _tabButton("History", 1, isDark),
      ],
    );
  }

  Widget _tabButton(String label, int index, bool isDark) {
    bool active = tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color:
              active
                  ? (isDark ? AppColors.primaryLight : AppColors.primary)
                  : (isDark
                      ? AppColors.surfaceVariantDark
                      : Colors.grey.shade200),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color:
                active
                    ? Colors.white
                    : (isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ORDERS LIST
  // -------------------------------------------------------------
  Widget _ordersList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection("users")
              .doc(uid)
              .collection("orders")
              .orderBy("timestamp", descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
          );
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return Center(
            child: Text(
              "No orders yet.",
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          );
        }

        final active =
            docs.where((d) {
              final s = d["status"];
              return s != "done" && s != "cancelled";
            }).toList();

        final history =
            docs.where((d) {
              final s = d["status"];
              return s == "done" || s == "cancelled";
            }).toList();

        final showList = tabIndex == 0 ? active : history;

        if (showList.isEmpty) {
          return Center(
            child: Text(
              tabIndex == 0 ? "No active orders." : "No past orders.",
              style: TextStyle(
                fontSize: 15,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: showList.length,
          itemBuilder: (_, i) {
            final data = showList[i].data() as Map<String, dynamic>;
            return _orderCard(data, isDark);
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // ORDER CARD SUMMARY
  // -------------------------------------------------------------
  Widget _orderCard(Map<String, dynamic> data, bool isDark) {
    final storeName = data["storeName"];
    final total = data["total"];
    final status = data["status"];
    final items = List<Map<String, dynamic>>.from(data["items"]);

    return GestureDetector(
      onTap: () => _openOrderDetails(data, isDark),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? AppColors.borderDark : Colors.grey.shade300,
          ),
          boxShadow:
              isDark
                  ? []
                  : [
                    BoxShadow(
                      color: Colors.grey.shade200,
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
        ),
        child: Row(
          children: [
            Icon(
              Icons.receipt_long,
              size: 36,
              color: isDark ? AppColors.primaryLight : AppColors.primary,
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    storeName ?? '',
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
                    "${items.length} item(s)",
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

            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _statusBadge(status),
                const SizedBox(height: 6),
                Text(
                  "₱ $total",
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // STATUS BADGE
  // -------------------------------------------------------------
  Widget _statusBadge(String status) {
    Color bg;
    Color textColor;
    String label;

    switch (status) {
      case "to-do":
        bg = AppColors.warningLight;
        textColor = AppColors.warning;
        label = "Preparing";
        break;
      case "in-progress":
        bg = AppColors.infoLight;
        textColor = AppColors.info;
        label = "In Progress";
        break;
      case "ready":
        bg = AppColors.successLight;
        textColor = AppColors.success;
        label = "Ready";
        break;
      case "done":
        bg = AppColors.success;
        textColor = Colors.white;
        label = "Completed";
        break;
      case "cancelled":
        bg = AppColors.errorLight;
        textColor = AppColors.error;
        label = "Cancelled";
        break;
      default:
        bg = Colors.grey.shade400;
        textColor = Colors.white;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // OPEN ORDER DETAILS SHEET (Slide-up)
  // -------------------------------------------------------------
  void _openOrderDetails(Map<String, dynamic> data, bool isDark) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return DraggableScrollableSheet(
          initialChildSize: 0.70,
          maxChildSize: 0.90,
          minChildSize: 0.55,
          builder: (_, controller) {
            return _orderDetailsSheet(data, controller, isDark);
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // FULL ORDER DETAIL SHEET UI
  // -------------------------------------------------------------
  Widget _orderDetailsSheet(
    Map<String, dynamic> data,
    ScrollController controller,
    bool isDark,
  ) {
    final items = List<Map<String, dynamic>>.from(data["items"]);
    final status = data["status"];
    final orderId = data["orderId"];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // drag handle
          Center(
            child: Container(
              width: 55,
              height: 5,
              decoration: BoxDecoration(
                color: isDark ? AppColors.borderDark : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            data["storeName"],
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),

          const SizedBox(height: 6),

          Text(
            "Order #$orderId",
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),

          const SizedBox(height: 14),

          _statusProgress(status, isDark),

          const SizedBox(height: 20),

          Text(
            "Items",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: Image.network(
                    item["imageUrl"],
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                  ),
                  title: Text(
                    item["productName"],
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  subtitle: Text(
                    "Qty: ${item['quantity']}",
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                  trailing: Text(
                    "₱ ${item['lineTotal']}",
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              },
            ),
          ),

          if (status == "to-do") ...[
            const SizedBox(height: 16),
            _cancelButton(orderId),
          ],
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PROGRESS FLOW (Preparing → In Progress → Ready → Done)
  // -------------------------------------------------------------
  Widget _statusProgress(String status, bool isDark) {
    List<String> steps = ["to-do", "in-progress", "ready", "done"];

    int index = steps.indexOf(status);
    if (index < 0) index = 0;

    List<String> labels = ["Preparing", "In Progress", "Ready", "Completed"];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(4, (i) {
        bool active = i <= index;

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color:
                    active
                        ? AppColors.success
                        : (isDark
                            ? AppColors.surfaceVariantDark
                            : Colors.grey.shade300),
                shape: BoxShape.circle,
              ),
              child: Icon(
                i == 0
                    ? Icons.receipt_long
                    : i == 1
                    ? Icons.local_fire_department
                    : i == 2
                    ? Icons.notifications_active
                    : Icons.done_all,
                color: Colors.white,
                size: 16,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              labels[i],
              style: TextStyle(
                fontSize: 11,
                color:
                    active
                        ? (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary)
                        : (isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary),
              ),
            ),
          ],
        );
      }),
    );
  }

  // -------------------------------------------------------------
  // CANCEL BUTTON
  // -------------------------------------------------------------
  Widget _cancelButton(String orderId) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _confirmCancel(orderId),
        child: const Text(
          "Cancel Order",
          style: TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // CONFIRMATION DIALOG
  void _confirmCancel(String orderId) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Cancel Order?',
      message:
          'Are you sure you want to cancel this order? This cannot be undone.',
      confirmLabel: 'Yes, Cancel',
      cancelLabel: 'No',
      isDanger: true,
    );

    if (ok == true) {
      _cancelOrderEverywhere(orderId);
    }
  }

  // -------------------------------------------------------------
  // FIRESTORE UPDATE (User → Global → Store)
  // -------------------------------------------------------------
  Future<void> _cancelOrderEverywhere(String orderId) async {
    final batch = FirebaseFirestore.instance.batch();

    // global
    batch.update(FirebaseFirestore.instance.collection("orders").doc(orderId), {
      "status": "cancelled",
      "cancelledAt": FieldValue.serverTimestamp(),
      "cancelledBy": uid,
    });

    // user
    batch.update(
      FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("orders")
          .doc(orderId),
      {"status": "cancelled"},
    );

    // store
    // We don't know storeId here, but order contains it
    final storeSnapshot =
        await FirebaseFirestore.instance
            .collection("orders")
            .doc(orderId)
            .get();

    if (storeSnapshot.exists) {
      final storeId = storeSnapshot["storeId"];
      batch.update(
        FirebaseFirestore.instance
            .collection("stores")
            .doc(storeId)
            .collection("orders")
            .doc(orderId),
        {"status": "cancelled"},
      );
    }

    await batch.commit();
  }
}
