// lib/pages/admin_shell.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../theme/app_theme.dart';
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Byte Plus Admin',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : Colors.white,
          ),
        ),
        backgroundColor: isDark ? AppColors.surfaceDark : AppColors.primary,
        leading: Builder(
          builder:
              (context) => IconButton(
                icon: Icon(
                  Icons.menu,
                  color: isDark ? AppColors.textPrimaryDark : Colors.white,
                ),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
        ),
      ),
      drawer: _buildDrawer(context, isDark),
      body:
          _selected == 0
              ? _buildOrdersDashboard(isDark)
              : const ManageMenuPage(),
    );
  }

  Drawer _buildDrawer(BuildContext context, bool isDark) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: SafeArea(
        child: Column(
          children: [
            FutureBuilder<DocumentSnapshot>(
              future:
                  FirebaseFirestore.instance
                      .collection('users')
                      .doc(_user.uid)
                      .get(),
              builder: (context, snap) {
                final data = snap.data?.data() as Map<String, dynamic>? ?? {};
                return UserAccountsDrawerHeader(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.primaryDark : AppColors.primary,
                  ),
                  accountName: Text(
                    data['name'] ?? 'Admin',
                    style: const TextStyle(color: Colors.white),
                  ),
                  accountEmail: Text(
                    data['email'] ?? _user.email ?? '',
                    style: TextStyle(color: Colors.white.withOpacity(0.8)),
                  ),
                  currentAccountPicture: CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(
                      Icons.admin_panel_settings,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: Icon(
                Icons.receipt_long,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              title: Text(
                'Orders',
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              onTap: () {
                setState(() => _selected = 0);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(
                Icons.fastfood,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
              title: Text(
                'Manage Menu',
                style: TextStyle(
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              onTap: () {
                setState(() => _selected = 1);
                Navigator.pop(context);
              },
            ),
            const Spacer(),
            Divider(color: isDark ? AppColors.borderDark : AppColors.border),
            ListTile(
              leading: Icon(Icons.logout, color: AppColors.error),
              title: Text('Logout', style: TextStyle(color: AppColors.error)),
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

  Widget _buildOrdersDashboard(bool isDark) {
    return DefaultTabController(
      length: 4,
      child: Column(
        children: [
          TabBar(
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
            tabs: const [
              Tab(text: 'To-Do'),
              Tab(text: 'In Progress'),
              Tab(text: 'Done'),
              Tab(text: 'Cancelled'),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildOrdersList('to-do', isDark),
                _buildOrdersList('in-progress', isDark),
                _buildOrdersList('done', isDark),
                _buildOrdersList('cancelled', isDark),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(String status, bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('orders')
              .where('status', isEqualTo: status)
              .orderBy('timestamp', descending: true)
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return Center(
            child: CircularProgressIndicator(color: AppColors.primary),
          );
        }
        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return Center(
            child: Text(
              'No $status orders.',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          );
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
              color: isDark ? AppColors.surfaceDark : Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              margin: const EdgeInsets.only(bottom: 12),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order #${docs[i].id.substring(0, 6)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Customer: $userName',
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Email: $userEmail',
                      style: TextStyle(
                        fontSize: 12,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                    Divider(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    ...items.map(
                      (e) => Text(
                        '${e['name']} (₱${e['price']} × ${e['qty']})',
                        style: TextStyle(
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Total: ₱${total.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
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
                                backgroundColor: AppColors.info,
                              ),
                              onPressed:
                                  () => _updateOrderStatus(
                                    docs[i].id,
                                    'in-progress',
                                  ),
                              child: const Text(
                                'Start',
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ] else if (status == 'in-progress') ...[
                            const SizedBox(width: 8),
                            ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                              ),
                              onPressed:
                                  () => _updateOrderStatus(docs[i].id, 'done'),
                              child: const Text(
                                'Done',
                                style: TextStyle(color: Colors.white),
                              ),
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
    await FirebaseFirestore.instance.collection('orders').doc(id).update({
      'status': newStatus,
    });
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'to-do':
        return AppColors.statusTodo;
      case 'in-progress':
        return AppColors.statusPreparing;
      case 'done':
        return AppColors.statusDone;
      case 'cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.textTertiary;
    }
  }
}
