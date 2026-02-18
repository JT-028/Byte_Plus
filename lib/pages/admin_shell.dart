// lib/pages/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../pages/login_page.dart';
import '../pages/manage_menu_page.dart';

class AdminShell extends StatefulWidget {
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _selected = 0; // 0 = Orders, 1 = Manage Menu
  final _auth = FirebaseAuth.instance;
  User get _user => _auth.currentUser!;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.orange.shade50,
      appBar: AppBar(
        title: const Text('Byte Plus Admin',
            style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.orange,
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: _buildDrawer(context),
      body: _selected == 0 ? _buildOrdersDashboard() : const ManageMenuPage(),
    );
  }

  Drawer _buildDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(_user.uid)
                  .get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                return UserAccountsDrawerHeader(
                  decoration: const BoxDecoration(color: Colors.orange),
                  accountName: Text(data['name'] ?? 'Admin'),
                  accountEmail: Text(data['email'] ?? _user.email ?? ''),
                  currentAccountPicture: const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.admin_panel_settings,
                        color: Colors.orange, size: 36),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.receipt_long),
              title: const Text('Orders'),
              onTap: () {
                setState(() => _selected = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.fastfood),
              title: const Text('Manage Menu'),
              onTap: () {
                setState(() => _selected = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Logout'),
              onTap: () async {
                await _auth.signOut();
                if (!mounted) return;
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginPage()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersDashboard() {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          const TabBar(
            indicatorColor: Colors.orange,
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.black54,
            tabs: [
              Tab(text: 'To-Do'),
              Tab(text: 'In Progress'),
              Tab(text: 'Done'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersList('to-do'),
                _buildOrdersList('in-progress'),
                _buildOrdersList('done'),
                _buildOrdersList('cancelled'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('orders')
          .where('status', isEqualTo: status)
          .orderBy('timestamp', descending: true)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(child: Text('No $status orders.'));
        }

        return ListView.builder(
          padding: const EdgeInsets.all(12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final data = docs[i].data() as Map<String, dynamic>;
            final userName = data['userName'] ?? 'Unknown';
            final userEmail = data['userEmail'] ?? '';
            final items = (data['items'] as List?) ?? [];
            final total = (data['total'] as num?)?.toDouble() ?? 0;

            return Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order #${docs[i].id.substring(0, 6)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 6),
                    Text('Customer: $userName'),
                    Text('Email: $userEmail',
                        style: const TextStyle(fontSize: 12, color: Colors.black54)),
                    const Divider(),
                    ...items.map((e) => Text(
                        '${e['name']} (₱${e['price']} × ${e['qty']})')),
                    const SizedBox(height: 6),
                    Text('Total: ₱${total.toStringAsFixed(2)}',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, color: Colors.black87)),
                    const SizedBox(height: 6),
                    Align(
                      alignment: Alignment.centerRight,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Chip(
                            label: Text(
                              status.toUpperCase(),
                              style: const TextStyle(color: Colors.white),
                            ),
                            backgroundColor: _statusColor(status),
                          ),
                          if (status == 'to-do') ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () =>
                                  _updateOrderStatus(docs[i].id, 'in-progress'),
                              child: const Text('Start'),
                            ),
                          ] else if (status == 'in-progress') ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () =>
                                  _updateOrderStatus(docs[i].id, 'done'),
                              child: const Text('Done'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _updateOrderStatus(String id, String newStatus) async {
    await FirebaseFirestore.instance
        .collection('orders')
        .doc(id)
        .update({'status': newStatus});
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'to-do':
        return Colors.grey;
      case 'in-progress':
        return Colors.blue;
      case 'done':
        return Colors.green;
      case 'cancelled':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
