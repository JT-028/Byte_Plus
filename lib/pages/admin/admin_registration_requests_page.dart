// lib/pages/admin/admin_registration_requests_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_modal_dialog.dart';

class AdminRegistrationRequestsPage extends StatefulWidget {
  const AdminRegistrationRequestsPage({super.key});

  @override
  State<AdminRegistrationRequestsPage> createState() =>
      _AdminRegistrationRequestsPageState();
}

class _AdminRegistrationRequestsPageState
    extends State<AdminRegistrationRequestsPage> {
  int statusTabIndex = 0;
  String roleFilter = 'All';

  final statusTabs = ['Pending', 'Approved', 'Rejected'];
  final statusMap = ['pending', 'approved', 'rejected'];
  final roleFilters = ['All', 'student', 'staff'];

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
            const SizedBox(height: 12),
            _statusTabsRow(isDark),
            const SizedBox(height: 12),
            _roleFilterRow(isDark),
            const SizedBox(height: 16),
            Expanded(child: _requestsList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Iconsax.user_add,
              color: AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Registration Requests',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Review and approve new accounts',
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
        ],
      ),
    );
  }

  Widget _roleFilterRow(bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children:
            roleFilters.map((role) {
              final isSelected = roleFilter == role;
              String displayLabel;
              IconData icon;

              switch (role) {
                case 'student':
                  displayLabel = 'Students';
                  icon = Iconsax.user;
                  break;
                case 'staff':
                  displayLabel = 'Merchants';
                  icon = Iconsax.shop;
                  break;
                default:
                  displayLabel = 'All Roles';
                  icon = Iconsax.people;
              }

              return Padding(
                padding: const EdgeInsets.only(right: 10),
                child: GestureDetector(
                  onTap: () => setState(() => roleFilter = role),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade300),
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          icon,
                          size: 18,
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          displayLabel,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isSelected ? FontWeight.w600 : FontWeight.w500,
                            color:
                                isSelected
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
      ),
    );
  }

  Widget _statusTabsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children:
              statusTabs.asMap().entries.map((entry) {
                final i = entry.key;
                final label = entry.value;
                final isSelected = statusTabIndex == i;

                return Expanded(
                  child: GestureDetector(
                    onTap: () => setState(() => statusTabIndex = i),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected ? _tabColor(i) : Colors.transparent,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color:
                              isSelected
                                  ? Colors.white
                                  : (isDark
                                      ? AppColors.textSecondaryDark
                                      : AppColors.textSecondary),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
        ),
      ),
    );
  }

  Color _tabColor(int index) {
    switch (index) {
      case 0:
        return AppColors.warning;
      case 1:
        return AppColors.success;
      case 2:
        return AppColors.error;
      default:
        return AppColors.primary;
    }
  }

  Widget _requestsList(bool isDark) {
    final status = statusMap[statusTabIndex];

    Query<Map<String, dynamic>> query = FirebaseFirestore.instance
        .collection('registrationRequests')
        .where('status', isEqualTo: status);

    if (roleFilter != 'All') {
      query = query.where('role', isEqualTo: roleFilter);
    }

    return StreamBuilder<QuerySnapshot>(
      stream: query.orderBy('createdAt', descending: true).snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Iconsax.warning_2,
                      size: 48,
                      color: AppColors.error,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Unable to Load Requests',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please check your permissions and try again',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () => setState(() {}),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(Iconsax.refresh, color: Colors.white),
                    label: const Text(
                      'Retry',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          itemCount: docs.length,
          itemBuilder: (_, i) => _requestCard(docs[i], isDark),
        );
      },
    );
  }

  Widget _emptyState(bool isDark) {
    String roleText =
        roleFilter == 'All'
            ? ''
            : (roleFilter == 'student' ? ' student' : ' merchant');
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.user_add,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No ${statusTabs[statusTabIndex]}$roleText Requests',
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

  Widget _requestCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? 'Unknown';
    final email = data['email']?.toString() ?? 'Unknown';
    final role = data['role']?.toString() ?? 'student';
    final status = data['status']?.toString() ?? 'pending';
    final storeName = data['storeName']?.toString();
    final studentId = data['studentId']?.toString();
    final createdAt = data['createdAt'] as Timestamp?;

    final dateStr =
        createdAt != null
            ? DateFormat('MMM dd, yyyy').format(createdAt.toDate())
            : 'Unknown date';

    final isStudent = role == 'student';
    final roleIcon = isStudent ? Iconsax.user : Iconsax.shop;
    final roleLabel = isStudent ? 'Student' : 'Merchant';
    final roleColor = isStudent ? Colors.blue : Colors.purple;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with name, email, role badge
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        roleColor.withOpacity(0.2),
                        roleColor.withOpacity(0.1),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Icon(roleIcon, color: roleColor, size: 22),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: roleColor.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              roleLabel,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: roleColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Iconsax.sms,
                            size: 12,
                            color:
                                isDark
                                    ? AppColors.textTertiaryDark
                                    : AppColors.textTertiary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              email,
                              style: TextStyle(
                                fontSize: 13,
                                color:
                                    isDark
                                        ? AppColors.textSecondaryDark
                                        : AppColors.textSecondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Store name for merchants
          if (!isStudent && storeName != null && storeName.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.backgroundDark.withOpacity(0.5)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.building,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      storeName,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),

          // Student ID for students
          if (isStudent && studentId != null && studentId.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.backgroundDark.withOpacity(0.5)
                        : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    Iconsax.card,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Student ID: ',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                  Text(
                    studentId,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                      fontFamily: 'monospace',
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),

          // Footer with date and status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Row(
              children: [
                Icon(
                  Iconsax.calendar,
                  size: 13,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  dateStr,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                ),
                const Spacer(),
                if (status != 'pending')
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _statusColor(status).withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          status == 'approved'
                              ? Iconsax.tick_circle
                              : Iconsax.close_circle,
                          size: 14,
                          color: _statusColor(status),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          status[0].toUpperCase() + status.substring(1),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _statusColor(status),
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          // Actions for pending requests
          if (status == 'pending')
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectRequest(doc.id, name),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: const BorderSide(
                          color: AppColors.error,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.close_circle, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Reject',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _approveRequest(doc.id, data),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.tick_circle, size: 18),
                          SizedBox(width: 6),
                          Text(
                            'Approve',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'approved':
        return AppColors.success;
      case 'rejected':
        return AppColors.error;
      case 'pending':
      default:
        return AppColors.warning;
    }
  }

  Future<void> _approveRequest(
    String requestId,
    Map<String, dynamic> data,
  ) async {
    final name = data['name']?.toString() ?? '';
    final email = data['email']?.toString() ?? '';
    final role = data['role']?.toString() ?? 'student';
    final password = data['password']?.toString() ?? '';
    final storeName = data['storeName']?.toString();
    final studentId = data['studentId']?.toString();

    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Approve Registration?',
      message:
          'This will create an account for $name ($email) as a ${role == 'student' ? 'Student' : 'Merchant'}.',
      confirmLabel: 'Approve',
      cancelLabel: 'Cancel',
    );

    if (ok != true) return;

    _showLoadingOverlay();

    try {
      // Use Cloud Function to create user
      final callable = FirebaseFunctions.instance.httpsCallable(
        'createUserAuth',
      );
      await callable.call({
        'email': email,
        'password': password,
        'name': name,
        'role': role,
        'storeName': storeName,
        'studentId': studentId,
        'fromRegistrationRequest': true,
      });

      // Update request status
      await FirebaseFirestore.instance
          .collection('registrationRequests')
          .doc(requestId)
          .update({
            'status': 'approved',
            'processedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        await AppModalDialog.success(
          context: context,
          title: 'Registration Approved',
          message:
              'Account created for $name. They can now login with their credentials.',
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Dismiss loading
        await AppModalDialog.error(
          context: context,
          title: 'Error',
          message: 'Failed to create account: $e',
        );
      }
    }
  }

  Future<void> _rejectRequest(String requestId, String name) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Reject Registration?',
      message: 'This request from $name will be marked as rejected.',
      confirmLabel: 'Reject',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok != true) return;

    await FirebaseFirestore.instance
        .collection('registrationRequests')
        .doc(requestId)
        .update({
          'status': 'rejected',
          'processedAt': FieldValue.serverTimestamp(),
        });

    if (mounted) {
      await AppModalDialog.info(
        context: context,
        title: 'Request Rejected',
        message: 'The registration request has been rejected.',
      );
    }
  }

  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }
}
