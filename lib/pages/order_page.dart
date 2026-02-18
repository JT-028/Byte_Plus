// lib/pages/order_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

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
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            const Text(
              "My Orders",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            _tabBar(),

            const SizedBox(height: 12),

            Expanded(child: _ordersList()),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // TOP TAB BAR (Active / History)
  // -------------------------------------------------------------
  Widget _tabBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _tabButton("Active", 0),
        const SizedBox(width: 18),
        _tabButton("History", 1),
      ],
    );
  }

  Widget _tabButton(String label, int index) {
    bool active = tabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => tabIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF1F41BB) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  // -------------------------------------------------------------
  // ORDERS LIST
  // -------------------------------------------------------------
  Widget _ordersList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("orders")
          .orderBy("timestamp", descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;

        if (docs.isEmpty) {
          return const Center(child: Text("No orders yet."));
        }

        final active = docs.where((d) {
          final s = d["status"];
          return s != "done" && s != "cancelled";
        }).toList();

        final history = docs.where((d) {
          final s = d["status"];
          return s == "done" || s == "cancelled";
        }).toList();

        final showList = tabIndex == 0 ? active : history;

        if (showList.isEmpty) {
          return Center(
            child: Text(
              tabIndex == 0 ? "No active orders." : "No past orders.",
              style: const TextStyle(fontSize: 15),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: showList.length,
          itemBuilder: (_, i) {
            final data = showList[i].data() as Map<String, dynamic>;
            return _orderCard(data);
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // ORDER CARD SUMMARY
  // -------------------------------------------------------------
  Widget _orderCard(Map<String, dynamic> data) {
    final storeName = data["storeName"];
    final total = data["total"];
    final status = data["status"];
    final items = List<Map<String, dynamic>>.from(data["items"]);

    return GestureDetector(
      onTap: () => _openOrderDetails(data),
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            )
          ],
        ),
        child: Row(
          children: [
            const Icon(Icons.receipt_long, size: 36, color: Color(0xFF1F41BB)),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(storeName,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),

                  const SizedBox(height: 4),

                  Text(
                    "${items.length} item(s)",
                    style: const TextStyle(fontSize: 13, color: Colors.black54),
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
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                )
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
    String label;

    switch (status) {
      case "to-do":
        bg = Colors.orange.shade200;
        label = "Preparing";
        break;
      case "in-progress":
        bg = Colors.blue.shade200;
        label = "In Progress";
        break;
      case "ready":
        bg = Colors.green.shade300;
        label = "Ready";
        break;
      case "done":
        bg = Colors.green;
        label = "Completed";
        break;
      case "cancelled":
        bg = Colors.red.shade300;
        label = "Cancelled";
        break;
      default:
        bg = Colors.grey.shade400;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
    );
  }

  // -------------------------------------------------------------
  // OPEN ORDER DETAILS SHEET (Slide-up)
  // -------------------------------------------------------------
  void _openOrderDetails(Map<String, dynamic> data) {
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
            return _orderDetailsSheet(data, controller);
          },
        );
      },
    );
  }

  // -------------------------------------------------------------
  // FULL ORDER DETAIL SHEET UI
  // -------------------------------------------------------------
  Widget _orderDetailsSheet(
      Map<String, dynamic> data, ScrollController controller) {
    final items = List<Map<String, dynamic>>.from(data["items"]);
    final status = data["status"];
    final orderId = data["orderId"];

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
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
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),

          const SizedBox(height: 16),

          Text(
            data["storeName"],
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),

          const SizedBox(height: 6),

          Text(
            "Order #$orderId",
            style: TextStyle(color: Colors.grey.shade600),
          ),

          const SizedBox(height: 14),

          _statusProgress(status),

          const SizedBox(height: 20),

          const Text("Items",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),

          Expanded(
            child: ListView.builder(
              controller: controller,
              itemCount: items.length,
              itemBuilder: (_, i) {
                final item = items[i];
                return ListTile(
                  leading: Image.network(item["imageUrl"],
                      width: 48, height: 48, fit: BoxFit.cover),
                  title: Text(item["productName"]),
                  subtitle: Text("Qty: ${item['quantity']}"),
                  trailing: Text("₱ ${item['lineTotal']}"),
                );
              },
            ),
          ),

          if (status == "to-do") ...[
            const SizedBox(height: 16),
            _cancelButton(orderId),
          ]
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // PROGRESS FLOW (Preparing → In Progress → Ready → Done)
  // -------------------------------------------------------------
  Widget _statusProgress(String status) {
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
                color: active ? Colors.green : Colors.grey.shade300,
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
                color: active ? Colors.black : Colors.grey,
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
          backgroundColor: Colors.redAccent,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: const EdgeInsets.symmetric(vertical: 14),
        ),
        onPressed: () => _confirmCancel(orderId),
        child: const Text("Cancel Order",
            style: TextStyle(color: Colors.white, fontSize: 15)),
      ),
    );
  }

  // CONFIRMATION DIALOG
  void _confirmCancel(String orderId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Cancel Order?"),
        content: const Text(
            "Are you sure you want to cancel this order? This cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("No"),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _cancelOrderEverywhere(orderId);
            },
            child: const Text(
              "Yes, Cancel",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
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
        await FirebaseFirestore.instance.collection("orders").doc(orderId).get();

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
