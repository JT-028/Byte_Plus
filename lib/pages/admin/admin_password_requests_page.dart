// lib/pages/admin/admin_password_requests_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_modal_dialog.dart';

class AdminPasswordRequestsPage extends StatefulWidget {
  const AdminPasswordRequestsPage({super.key});

  @override
  State<AdminPasswordRequestsPage> createState() =>
      _AdminPasswordRequestsPageState();
}

class _AdminPasswordRequestsPageState extends State<AdminPasswordRequestsPage> {
  int tabIndex = 0;

  final tabs = ['Pending', 'Approved', 'Rejected'];
  final statusMap = ['pending', 'approved', 'rejected'];

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
            _tabsRow(isDark),
            Expanded(child: _requestsList(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Password Requests',
        style: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _tabsRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children:
            tabs.asMap().entries.map((entry) {
              final i = entry.key;
              final label = entry.value;
              final isSelected = tabIndex == i;

              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => tabIndex = i),
                  child: Container(
                    margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? _tabColor(i)
                              : (isDark ? AppColors.surfaceDark : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? _tabColor(i)
                                : (isDark
                                    ? AppColors.borderDark
                                    : Colors.grey.shade300),
                      ),
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
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
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
    final status = statusMap[tabIndex];

    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('passwordRequests')
              .where('status', isEqualTo: status)
              .orderBy('createdAt', descending: true)
              .snapshots(),
      builder: (context, snap) {
        // Handle errors (e.g., missing Firestore index)
        if (snap.hasError) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.warning_2,
                  size: 48,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : Colors.grey.shade400,
                ),
                const SizedBox(height: 16),
                Text(
                  'Error loading requests',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  snap.error.toString(),
                  textAlign: TextAlign.center,
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

        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(tabs[tabIndex], isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(20),
          itemCount: docs.length,
          itemBuilder: (_, i) => _requestCard(docs[i], isDark),
        );
      },
    );
  }

  Widget _emptyState(String tab, bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Iconsax.key,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No $tab Requests',
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
    final email = data['email']?.toString() ?? 'Unknown';
    final status = data['status']?.toString() ?? 'pending';
    final createdAt = data['createdAt'] as Timestamp?;
    final reason = data['reason']?.toString() ?? '';

    final dateStr =
        createdAt != null
            ? DateFormat('MMM dd, yyyy • h:mm a').format(createdAt.toDate())
            : 'Unknown date';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    Iconsax.key,
                    color: _statusColor(status),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      email,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _statusColor(status).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _statusColor(status),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Date
          Row(
            children: [
              Icon(
                Iconsax.calendar,
                size: 14,
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
            ],
          ),

          // Reason
          if (reason.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : AppColors.background,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    Iconsax.message_text,
                    size: 16,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      reason,
                      style: TextStyle(
                        fontSize: 13,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Actions for pending
          if (status == 'pending') ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () async {
                      _showLoadingOverlay();
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (mounted) Navigator.pop(context); // Dismiss loading
                      _rejectRequest(doc.id);
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.error),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Reject',
                      style: TextStyle(
                        color: AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () async {
                      _showLoadingOverlay();
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (mounted) Navigator.pop(context); // Dismiss loading
                      _approveRequest(doc.id, email);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.success,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text(
                      'Approve & Send Link',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],

          // Processing info for approved/rejected
          if (status != 'pending' && data['processedAt'] != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: isDark ? AppColors.borderDark : Colors.grey.shade200,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  status == 'approved'
                      ? Iconsax.tick_circle
                      : Iconsax.close_circle,
                  size: 14,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(width: 6),
                Text(
                  '${status == 'approved' ? 'Approved' : 'Rejected'} on ${_formatDate(data['processedAt'])}',
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
          ],
        ],
      ),
    );
  }

  /// Show a loading overlay to prevent multiple clicks
  void _showLoadingOverlay() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
  }

  String _formatDate(dynamic timestamp) {
    if (timestamp is Timestamp) {
      return DateFormat('MMM dd, yyyy').format(timestamp.toDate());
    }
    return 'Unknown';
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

  Future<void> _approveRequest(String requestId, String email) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Approve Request?',
      message: 'This will send a password reset link to $email.',
      confirmLabel: 'Approve',
      cancelLabel: 'Cancel',
    );

    if (ok == true) {
      try {
        // Send password reset email
        await FirebaseAuth.instance.sendPasswordResetEmail(email: email);

        // Update request status
        await FirebaseFirestore.instance
            .collection('passwordRequests')
            .doc(requestId)
            .update({
              'status': 'approved',
              'processedAt': FieldValue.serverTimestamp(),
              'processedBy': FirebaseAuth.instance.currentUser?.uid,
            });

        if (mounted) {
          await AppModalDialog.success(
            context: context,
            title: 'Request Approved',
            message: 'A password reset link has been sent to $email.',
          );
        }
      } catch (e) {
        if (mounted) {
          await AppModalDialog.warning(
            context: context,
            title: 'Error',
            message: 'Failed to send reset email: $e',
          );
        }
      }
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Reject Request?',
      message: 'This request will be marked as rejected.',
      confirmLabel: 'Reject',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      await FirebaseFirestore.instance
          .collection('passwordRequests')
          .doc(requestId)
          .update({
            'status': 'rejected',
            'processedAt': FieldValue.serverTimestamp(),
            'processedBy': FirebaseAuth.instance.currentUser?.uid,
          });

      if (mounted) {
        await AppModalDialog.info(
          context: context,
          title: 'Request Rejected',
          message: 'The password request has been rejected.',
        );
      }
    }
  }
}

