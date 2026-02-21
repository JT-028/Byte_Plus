// lib/pages/admin/admin_users_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_modal_dialog.dart';

class AdminUsersPage extends StatefulWidget {
  const AdminUsersPage({super.key});

  @override
  State<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends State<AdminUsersPage> {
  String searchQuery = '';
  String selectedRoleFilter = 'All';
  final searchController = TextEditingController();

  final roles = ['All', 'student', 'staff', 'admin'];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _header(isDark),
            _searchAndFilter(isDark),
            Expanded(child: _usersList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Manage Users',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _searchAndFilter(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: searchController,
            onChanged: (val) => setState(() => searchQuery = val.toLowerCase()),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: TextStyle(
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
              ),
              prefixIcon: Icon(
                Iconsax.search_normal,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
              filled: true,
              fillColor: isDark ? AppColors.surfaceDark : Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 12),
          // Role filter
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  roles.map((role) {
                    final isSelected = selectedRoleFilter == role;
                    return GestureDetector(
                      onTap: () => setState(() => selectedRoleFilter = role),
                      child: Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color:
                              isSelected
                                  ? AppColors.primary
                                  : (isDark
                                      ? AppColors.surfaceDark
                                      : Colors.white),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color:
                                isSelected
                                    ? AppColors.primary
                                    : (isDark
                                        ? AppColors.borderDark
                                        : Colors.grey.shade300),
                          ),
                        ),
                        child: Text(
                          role == 'All' ? 'All Roles' : _capitalizeRole(role),
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color:
                                isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _usersList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('users')
              .orderBy('name')
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data!.docs;

        // Filter by role
        if (selectedRoleFilter != 'All') {
          docs =
              docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                return data['role'] == selectedRoleFilter;
              }).toList();
        }

        // Filter by search
        if (searchQuery.isNotEmpty) {
          docs =
              docs.where((d) {
                final data = d.data() as Map<String, dynamic>;
                final name = (data['name'] ?? '').toString().toLowerCase();
                final email = (data['email'] ?? '').toString().toLowerCase();
                return name.contains(searchQuery) ||
                    email.contains(searchQuery);
              }).toList();
        }

        if (docs.isEmpty) {
          return _emptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _userCard(docs[i], isDark),
        );
      },
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.people,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No users found',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _userCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? 'Unknown';
    final email = data['email']?.toString() ?? '';
    final role = data['role']?.toString() ?? 'student';
    final storeId = data['storeId']?.toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _roleColor(role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(_roleIcon(role), color: _roleColor(role), size: 22),
            ),
          ),
          const SizedBox(width: 14),
          // Info
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
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 13,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (role == 'staff' && storeId != null) ...[
                  const SizedBox(height: 4),
                  FutureBuilder<DocumentSnapshot>(
                    future:
                        FirebaseFirestore.instance
                            .collection('stores')
                            .doc(storeId)
                            .get(),
                    builder: (context, snap) {
                      final storeName =
                          (snap.data?.data()
                              as Map<String, dynamic>?)?['name'] ??
                          storeId;
                      return Text(
                        'Store: $storeName',
                        style: TextStyle(
                          fontSize: 11,
                          color: AppColors.primary,
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Role badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: _roleColor(role).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              _capitalizeRole(role),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _roleColor(role),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Actions
          PopupMenuButton<String>(
            icon: Icon(
              Iconsax.more,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            color: isDark ? AppColors.surfaceDark : Colors.white,
            onSelected: (value) {
              if (value.startsWith('role_')) {
                _changeRole(doc.id, value.substring(5));
              } else if (value == 'assign_store') {
                _showAssignStoreDialog(doc.id, storeId, isDark);
              }
            },
            itemBuilder:
                (_) => [
                  const PopupMenuItem(
                    enabled: false,
                    child: Text(
                      'Change Role',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role_student',
                    child: _roleMenuItem('Student', role == 'student', isDark),
                  ),
                  PopupMenuItem(
                    value: 'role_staff',
                    child: _roleMenuItem(
                      'Staff/Merchant',
                      role == 'staff',
                      isDark,
                    ),
                  ),
                  PopupMenuItem(
                    value: 'role_admin',
                    child: _roleMenuItem('Admin', role == 'admin', isDark),
                  ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'assign_store',
                    child: Text('Assign to Store'),
                  ),
                ],
          ),
        ],
      ),
    );
  }

  Widget _roleMenuItem(String label, bool isSelected, bool isDark) {
    return Row(
      children: [
        if (isSelected)
          const Icon(Icons.check, size: 16, color: AppColors.primary)
        else
          const SizedBox(width: 16),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _changeRole(String userId, String newRole) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Change Role?',
      message:
          'This will change the user\'s role to ${_capitalizeRole(newRole)}.',
      confirmLabel: 'Change',
      cancelLabel: 'Cancel',
    );

    if (ok == true) {
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'role': newRole,
      });

      if (mounted) {
        await AppModalDialog.success(
          context: context,
          title: 'Role Changed',
          message: 'The user role has been updated.',
        );
      }
    }
  }

  Future<void> _showAssignStoreDialog(
    String userId,
    String? currentStoreId,
    bool isDark,
  ) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => _AssignStoreSheet(
            userId: userId,
            currentStoreId: currentStoreId,
            isDark: isDark,
          ),
    );

    // Show success dialog after bottom sheet is dismissed
    if (result != null && mounted) {
      await AppModalDialog.success(
        context: context,
        title: 'Store Assigned',
        message:
            result['storeId'] == null
                ? 'The user has been unassigned from any store.'
                : 'The user has been assigned to the store.',
      );
    }
  }

  String _capitalizeRole(String role) {
    if (role == 'staff') return 'Merchant';
    return role[0].toUpperCase() + role.substring(1);
  }

  Color _roleColor(String role) {
    switch (role) {
      case 'admin':
        return AppColors.error;
      case 'staff':
        return AppColors.warning;
      case 'student':
      default:
        return AppColors.primary;
    }
  }

  IconData _roleIcon(String role) {
    switch (role) {
      case 'admin':
        return Iconsax.shield_tick;
      case 'staff':
        return Iconsax.shop;
      case 'student':
      default:
        return Iconsax.user;
    }
  }
}

class _AssignStoreSheet extends StatefulWidget {
  final String userId;
  final String? currentStoreId;
  final bool isDark;

  const _AssignStoreSheet({
    required this.userId,
    required this.currentStoreId,
    required this.isDark,
  });

  @override
  State<_AssignStoreSheet> createState() => _AssignStoreSheetState();
}

class _AssignStoreSheetState extends State<_AssignStoreSheet> {
  String? selectedStoreId;

  @override
  void initState() {
    super.initState();
    selectedStoreId = widget.currentStoreId;
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color:
                      widget.isDark ? AppColors.borderDark : AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Assign to Store',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color:
                    widget.isDark
                        ? AppColors.textPrimaryDark
                        : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('stores').snapshots(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final stores = snap.data!.docs;

                return Column(
                  children: [
                    // No store option
                    _storeOption(null, 'No Store', widget.isDark),
                    ...stores.map((s) {
                      final data = s.data() as Map<String, dynamic>;
                      return _storeOption(
                        s.id,
                        data['name'] ?? s.id,
                        widget.isDark,
                      );
                    }).toList(),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(
                        color:
                            widget.isDark
                                ? AppColors.borderDark
                                : AppColors.border,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: TextStyle(
                        color:
                            widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _assignStore,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('Assign'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _storeOption(String? storeId, String name, bool isDark) {
    final isSelected = selectedStoreId == storeId;

    return GestureDetector(
      onTap: () => setState(() => selectedStoreId = storeId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color:
              isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : (isDark ? AppColors.backgroundDark : AppColors.background),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.primary
                    : (isDark ? AppColors.borderDark : Colors.grey.shade300),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              storeId == null ? Iconsax.close_circle : Iconsax.shop,
              color:
                  isSelected
                      ? AppColors.primary
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
              size: 20,
            ),
            const SizedBox(width: 12),
            Text(
              name,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color:
                    isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary),
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: AppColors.primary,
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _assignStore() async {
    await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.userId)
        .update({'storeId': selectedStoreId});

    if (mounted) {
      // Return the result to parent to show success dialog
      Navigator.pop(context, {'success': true, 'storeId': selectedStoreId});
    }
  }
}
