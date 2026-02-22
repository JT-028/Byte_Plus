// lib/pages/admin/admin_users_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateUserDialog(isDark);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Iconsax.user_add),
        label: const Text('Add User'),
      ),
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

        // Filter out deleted users
        docs =
            docs.where((d) {
              final data = d.data() as Map<String, dynamic>;
              final status = (data['status'] ?? '').toString().toLowerCase();
              return status != 'deleted';
            }).toList();

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
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
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
                  maxLines: 1,
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
            onSelected: (value) async {
              if (value.startsWith('role_')) {
                _changeRole(doc.id, value.substring(5));
              } else if (value == 'assign_store') {
                _showAssignStoreDialog(doc.id, storeId, isDark);
              } else if (value == 'edit_user') {
                _showEditUserDialog(doc.id, name, email, role, isDark);
              } else if (value == 'delete_user') {
                _deleteUser(doc.id, name);
              }
            },
            itemBuilder:
                (_) => [
                  PopupMenuItem(
                    value: 'edit_user',
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.edit,
                          size: 18,
                          color:
                              isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Edit User',
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const PopupMenuDivider(),
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
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete_user',
                    child: Row(
                      children: [
                        const Icon(
                          Iconsax.trash,
                          size: 18,
                          color: AppColors.error,
                        ),
                        const SizedBox(width: 10),
                        const Text(
                          'Delete User',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
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

  /// Show a full-screen loading overlay to prevent UI interactions
  void _showLoadingOverlay(bool isDark, String message) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black54,
      builder:
          (context) => PopScope(
            canPop: false,
            child: Center(
              child: Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.surfaceDark : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      message,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                        decoration: TextDecoration.none,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
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

  /// Show dialog to create a new user account
  Future<void> _showCreateUserDialog(bool isDark) async {
    final result = await showModalBottomSheet<Map<String, dynamic>?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => _CreateEditUserSheet(isDark: isDark, isEditing: false),
    );

    if (result != null && mounted) {
      // Prompt admin for their password first, before any account creation
      final adminPassword = await _promptForAdminPassword(isDark);
      if (adminPassword == null) {
        return; // User cancelled
      }

      // Show full-screen loading overlay to block all StreamBuilders during auth switch
      _showLoadingOverlay(isDark, 'Creating user account...');

      try {
        final email = result['email'] as String;
        final password = result['password'] as String;
        final name = result['name'] as String;
        final role = result['role'] as String;

        // Save admin credentials to re-authenticate after user creation
        final adminUser = FirebaseAuth.instance.currentUser;
        final adminEmail = adminUser?.email;
        final adminUid = adminUser?.uid;

        if (adminEmail == null) {
          throw Exception('Admin email not found');
        }

        // Create auth account (this will sign in as the new user)
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(email: email, password: password);

        // Create Firestore document for the new user
        await FirebaseFirestore.instance
            .collection('users')
            .doc(credential.user!.uid)
            .set({
              'name': name,
              'email': email,
              'role': role,
              'createdAt': FieldValue.serverTimestamp(),
              'createdBy': adminUid,
            });

        // Sign out the newly created user immediately
        await FirebaseAuth.instance.signOut();

        // Re-authenticate as admin as fast as possible
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: adminEmail,
          password: adminPassword,
        );

        // Dismiss loading overlay
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        if (mounted) {
          await AppModalDialog.success(
            context: context,
            title: 'User Created',
            message: 'The new user account has been created successfully.',
          );
        }
      } on FirebaseAuthException catch (e) {
        // Dismiss loading overlay
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        // Try to re-sign in admin if something went wrong
        await _tryReauthenticateAdmin();

        if (mounted) {
          await AppModalDialog.warning(
            context: context,
            title: 'Error',
            message: e.message ?? 'Failed to create user account.',
          );
        }
      } catch (e) {
        // Dismiss loading overlay
        if (mounted) Navigator.of(context, rootNavigator: true).pop();

        // Try to re-sign in admin if something went wrong
        await _tryReauthenticateAdmin();

        if (mounted) {
          await AppModalDialog.warning(
            context: context,
            title: 'Error',
            message: 'Failed to create user: $e',
          );
        }
      }
    }
  }

  /// Prompt admin for their password
  Future<String?> _promptForAdminPassword(bool isDark) async {
    final controller = TextEditingController();
    final result = await showDialog<String?>(
      context: context,
      barrierDismissible: false,
      builder:
          (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: Text(
              'Confirm Your Password',
              style: TextStyle(
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter your admin password to continue creating this user.',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: controller,
                  obscureText: true,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: 'Your Password',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, null),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Continue'),
              ),
            ],
          ),
    );
    controller.dispose();
    return result;
  }

  /// Try to re-authenticate admin if session was lost
  Future<void> _tryReauthenticateAdmin() async {
    // If we're not signed in, redirect to login
    if (FirebaseAuth.instance.currentUser == null) {
      // The splash page will handle redirecting to login
      if (mounted) {
        Navigator.of(context).pushNamedAndRemoveUntil('/', (_) => false);
      }
    }
  }

  /// Show dialog to edit user details
  Future<void> _showEditUserDialog(
    String userId,
    String currentName,
    String currentEmail,
    String currentRole,
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
          (context) => _CreateEditUserSheet(
            isDark: isDark,
            isEditing: true,
            initialName: currentName,
            initialEmail: currentEmail,
            initialRole: currentRole,
          ),
    );

    if (result != null && mounted) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
              'name': result['name'],
              'role': result['role'],
              'updatedAt': FieldValue.serverTimestamp(),
              'updatedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        if (mounted) {
          await AppModalDialog.success(
            context: context,
            title: 'User Updated',
            message: 'The user details have been updated.',
          );
        }
      } catch (e) {
        if (mounted) {
          await AppModalDialog.warning(
            context: context,
            title: 'Error',
            message: 'Failed to update user: $e',
          );
        }
      }
    }
  }

  /// Delete user account from both Firestore and Firebase Auth
  Future<void> _deleteUser(String userId, String userName) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Delete User?',
      message:
          'Are you sure you want to permanently delete "$userName"? This will remove their account from both the database and authentication system. This action cannot be undone.',
      confirmLabel: 'Delete Permanently',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      try {
        // Show loading dialog
        showDialog(
          context: context,
          barrierDismissible: false,
          builder:
              (context) => const Center(child: CircularProgressIndicator()),
        );

        // Call the Cloud Function to delete user from Auth and Firestore
        final callable = FirebaseFunctions.instance.httpsCallable(
          'deleteUserAuth',
        );
        final result = await callable.call({'userId': userId});

        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        final data = result.data as Map<String, dynamic>;

        await AppModalDialog.success(
          context: context,
          title: 'User Deleted',
          message: data['message'] ?? 'The user has been permanently deleted.',
        );
      } on FirebaseFunctionsException catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        await AppModalDialog.warning(
          context: context,
          title: 'Error',
          message: 'Failed to delete user: ${e.message}',
        );
      } catch (e) {
        if (!mounted) return;
        Navigator.pop(context); // Close loading dialog

        await AppModalDialog.warning(
          context: context,
          title: 'Error',
          message: 'Failed to delete user: $e',
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
                    }),
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

/// Bottom sheet for creating or editing a user
class _CreateEditUserSheet extends StatefulWidget {
  final bool isDark;
  final bool isEditing;
  final String? initialName;
  final String? initialEmail;
  final String? initialRole;

  const _CreateEditUserSheet({
    required this.isDark,
    required this.isEditing,
    this.initialName,
    this.initialEmail,
    this.initialRole,
  });

  @override
  State<_CreateEditUserSheet> createState() => _CreateEditUserSheetState();
}

class _CreateEditUserSheetState extends State<_CreateEditUserSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  String _selectedRole = 'student';
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _passwordController = TextEditingController();
    _selectedRole = widget.initialRole ?? 'student';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use viewInsets separately to avoid rebuilding entire tree
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 100),
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: bottomInset + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color:
                          widget.isDark
                              ? AppColors.borderDark
                              : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Title
                Text(
                  widget.isEditing ? 'Edit User' : 'Create New User',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  widget.isEditing
                      ? 'Update the user\'s information below.'
                      : 'Enter the details for the new user account.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        widget.isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                // Name field
                _buildLabel('Full Name'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  style: TextStyle(
                    color:
                        widget.isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  decoration: _inputDecoration('Enter full name', Iconsax.user),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Please enter the name';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Email field (only for create)
                if (!widget.isEditing) ...[
                  _buildLabel('Email Address'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: TextStyle(
                      color:
                          widget.isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                    decoration: _inputDecoration('Enter email', Iconsax.sms),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return 'Please enter the email';
                      }
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Please enter a valid email';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Password field
                  _buildLabel('Password'),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: TextStyle(
                      color:
                          widget.isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Enter password',
                      hintStyle: TextStyle(
                        color:
                            widget.isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
                      prefixIcon: Icon(
                        Iconsax.lock,
                        color:
                            widget.isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Iconsax.eye : Iconsax.eye_slash,
                          color:
                              widget.isDark
                                  ? AppColors.textSecondaryDark
                                  : AppColors.textSecondary,
                        ),
                        onPressed:
                            () => setState(
                              () => _obscurePassword = !_obscurePassword,
                            ),
                      ),
                      filled: true,
                      fillColor:
                          widget.isDark
                              ? AppColors.backgroundDark
                              : AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return 'Please enter a password';
                      }
                      if (v.length < 6) {
                        return 'Password must be at least 6 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],

                // Role selector
                _buildLabel('Role'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _roleChip('student', 'Student'),
                    const SizedBox(width: 8),
                    _roleChip('staff', 'Merchant'),
                    const SizedBox(width: 8),
                    _roleChip('admin', 'Admin'),
                  ],
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _isLoading ? null : () => Navigator.pop(context),
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
                        onPressed: _isLoading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child:
                            _isLoading
                                ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                                : Text(widget.isEditing ? 'Update' : 'Create'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color:
            widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color:
            widget.isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      prefixIcon: Icon(
        icon,
        color:
            widget.isDark
                ? AppColors.textSecondaryDark
                : AppColors.textSecondary,
      ),
      filled: true,
      fillColor:
          widget.isDark ? AppColors.backgroundDark : AppColors.background,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  Widget _roleChip(String value, String label) {
    final isSelected = _selectedRole == value;

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedRole = value),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color:
                isSelected
                    ? AppColors.primary.withOpacity(0.1)
                    : (widget.isDark
                        ? AppColors.backgroundDark
                        : AppColors.background),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  isSelected
                      ? AppColors.primary
                      : (widget.isDark
                          ? AppColors.borderDark
                          : Colors.grey.shade300),
              width: isSelected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color:
                  isSelected
                      ? AppColors.primary
                      : (widget.isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      Navigator.pop(context, {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
        'role': _selectedRole,
      });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
