// lib/pages/admin/admin_dashboard_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:rxdart/rxdart.dart';

import '../../theme/app_theme.dart';

class AdminDashboardPage extends StatefulWidget {
  const AdminDashboardPage({super.key});

  @override
  State<AdminDashboardPage> createState() => _AdminDashboardPageState();
}

class _AdminDashboardPageState extends State<AdminDashboardPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async => setState(() {}),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _header(isDark),
                const SizedBox(height: 24),
                _statsGrid(isDark),
                const SizedBox(height: 24),
                _recentActivity(isDark),
                const SizedBox(height: 24),
                _pendingRequests(isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Dashboard',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'System overview & management',
          style: TextStyle(
            fontSize: 14,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _statsGrid(bool isDark) {
    return StreamBuilder<List<QuerySnapshot>>(
      stream: _getCombinedStreams(),
      builder: (context, snap) {
        int totalUsers = 0;
        int totalStores = 0;
        int totalOrders = 0;
        int pendingRequests = 0;

        if (snap.hasData) {
          totalUsers = snap.data![0].docs.length;
          totalStores = snap.data![1].docs.length;
          totalOrders = snap.data![2].docs.length;
          pendingRequests = snap.data![3].docs.length;
        }

        return GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.15,
          children: [
            _statCard(
              title: 'Total Users',
              value: totalUsers.toString(),
              icon: Iconsax.people,
              color: AppColors.primary,
              isDark: isDark,
            ),
            _statCard(
              title: 'Total Stores',
              value: totalStores.toString(),
              icon: Iconsax.shop,
              color: AppColors.success,
              isDark: isDark,
            ),
            _statCard(
              title: 'Total Orders',
              value: totalOrders.toString(),
              icon: Iconsax.receipt_2,
              color: AppColors.warning,
              isDark: isDark,
            ),
            _statCard(
              title: 'Pending Requests',
              value: pendingRequests.toString(),
              icon: Iconsax.message_question,
              color: AppColors.error,
              isDark: isDark,
            ),
          ],
        );
      },
    );
  }

  Stream<List<QuerySnapshot>> _getCombinedStreams() {
    return CombineLatestStream.list([
      FirebaseFirestore.instance.collection('users').snapshots(),
      FirebaseFirestore.instance.collection('stores').snapshots(),
      FirebaseFirestore.instance.collection('orders').snapshots(),
      FirebaseFirestore.instance
          .collection('passwordRequests')
          .where('status', isEqualTo: 'pending')
          .snapshots(),
    ]);
  }

  Widget _statCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow:
            isDark
                ? []
                : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
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
    );
  }

  Widget _recentActivity(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Orders',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('orders')
                  .orderBy('timestamp', descending: true)
                  .limit(5)
                  .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return _emptyCard('No recent orders', isDark);
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children:
                    docs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final userName = data['userName'] ?? 'Unknown';
                      final storeName = data['storeName'] ?? 'Unknown Store';
                      final status = data['status'] ?? 'unknown';
                      final total = (data['total'] as num?)?.toDouble() ?? 0;

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border:
                              i < docs.length - 1
                                  ? Border(
                                    bottom: BorderSide(
                                      color:
                                          isDark
                                              ? AppColors.borderDark
                                              : Colors.grey.shade200,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: _statusColor(status).withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  Iconsax.receipt_2,
                                  color: _statusColor(status),
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    userName,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    storeName,
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  '₱${total.toStringAsFixed(0)}',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                _statusBadge(status),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _pendingRequests(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending Registration Requests',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream:
              FirebaseFirestore.instance
                  .collection('registrationRequests')
                  .where('status', isEqualTo: 'pending')
                  .orderBy('createdAt', descending: true)
                  .limit(3)
                  .snapshots(),
          builder: (context, snap) {
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final docs = snap.data!.docs;
            if (docs.isEmpty) {
              return _emptyCard('No pending requests', isDark);
            }

            return Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.surfaceDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : Colors.grey.shade200,
                ),
              ),
              child: Column(
                children:
                    docs.asMap().entries.map((entry) {
                      final i = entry.key;
                      final data = entry.value.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Unknown';
                      final email = data['email'] ?? '';
                      final role = data['role'] ?? 'student';
                      final isStudent = role == 'student';

                      return Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          border:
                              i < docs.length - 1
                                  ? Border(
                                    bottom: BorderSide(
                                      color:
                                          isDark
                                              ? AppColors.borderDark
                                              : Colors.grey.shade200,
                                    ),
                                  )
                                  : null,
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: (isStudent
                                        ? AppColors.primary
                                        : AppColors.success)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Center(
                                child: Icon(
                                  isStudent ? Iconsax.user : Iconsax.shop,
                                  color:
                                      isStudent
                                          ? AppColors.primary
                                          : AppColors.success,
                                  size: 18,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    name,
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    email,
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: (isStudent
                                        ? AppColors.primary
                                        : AppColors.success)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                isStudent ? 'Student' : 'Merchant',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color:
                                      isStudent
                                          ? AppColors.primary
                                          : AppColors.success,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _emptyCard(String message, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Center(
        child: Text(
          message,
          style: TextStyle(
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(String status) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: _statusColor(status).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        status.replaceAll('-', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: _statusColor(status),
        ),
      ),
    );
  }

  Color _statusColor(String s) {
    switch (s) {
      case 'to-do':
        return AppColors.statusTodo;
      case 'in-progress':
        return AppColors.statusPreparing;
      case 'ready':
        return AppColors.info;
      case 'done':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }
}

