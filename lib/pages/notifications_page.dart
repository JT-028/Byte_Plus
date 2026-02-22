// lib/pages/notifications_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:intl/intl.dart';

import '../theme/app_theme.dart';
import '../services/notification_service.dart';

class NotificationsPage extends StatefulWidget {
  const NotificationsPage({super.key});

  @override
  State<NotificationsPage> createState() => _NotificationsPageState();
}

class _NotificationsPageState extends State<NotificationsPage> {
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _deleteReadNotifications() async {
    final count = await NotificationService.deleteAllReadNotifications(_uid);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Deleted $count read notification${count == 1 ? '' : 's'}',
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        actions: [
          PopupMenuButton<String>(
            icon: Icon(
              Icons.more_vert,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            onSelected: (value) {
              switch (value) {
                case 'mark_read':
                  NotificationService.markAllAsRead(_uid);
                  break;
                case 'delete_read':
                  _deleteReadNotifications();
                  break;
              }
            },
            itemBuilder:
                (context) => [
                  PopupMenuItem(
                    value: 'mark_read',
                    child: Row(
                      children: [
                        Icon(
                          Iconsax.tick_circle,
                          size: 20,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                        const SizedBox(width: 12),
                        Text('Mark all as read'),
                      ],
                    ),
                  ),
                  PopupMenuItem(
                    value: 'delete_read',
                    child: Row(
                      children: [
                        Icon(Iconsax.trash, size: 20, color: AppColors.error),
                        const SizedBox(width: 12),
                        Text(
                          'Delete all read',
                          style: TextStyle(color: AppColors.error),
                        ),
                      ],
                    ),
                  ),
                ],
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: NotificationService.getNotificationsStream(_uid),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _emptyState(isDark);
          }

          final notifications = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: notifications.length,
            itemBuilder: (context, index) {
              final doc = notifications[index];
              final data = doc.data() as Map<String, dynamic>;
              final isRead = data['read'] ?? false;

              return Dismissible(
                key: Key(doc.id),
                direction: DismissDirection.endToStart,
                background: Container(
                  alignment: Alignment.centerRight,
                  padding: const EdgeInsets.only(right: 20),
                  color: AppColors.error,
                  child: const Icon(Iconsax.trash, color: Colors.white),
                ),
                confirmDismiss: (direction) async {
                  return await showDialog<bool>(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Delete Notification'),
                              content: const Text(
                                'Are you sure you want to delete this notification?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: TextButton.styleFrom(
                                    foregroundColor: AppColors.error,
                                  ),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                      ) ??
                      false;
                },
                onDismissed: (direction) {
                  NotificationService.deleteNotification(_uid, doc.id);
                },
                child: _NotificationTile(
                  notificationId: doc.id,
                  title: data['title'] ?? 'Notification',
                  body: data['body'] ?? '',
                  isRead: isRead,
                  createdAt: data['createdAt'] as Timestamp?,
                  type: data['type'] ?? 'general',
                  isDark: isDark,
                  userId: _uid,
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _emptyState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color:
                    isDark
                        ? AppColors.primaryLight.withOpacity(0.1)
                        : AppColors.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Iconsax.notification,
                size: 56,
                color: isDark ? AppColors.primaryLight : AppColors.primary,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'No Notifications',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "You're all caught up! We'll notify you when something important happens.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final String notificationId;
  final String title;
  final String body;
  final bool isRead;
  final Timestamp? createdAt;
  final String type;
  final bool isDark;
  final String userId;

  const _NotificationTile({
    required this.notificationId,
    required this.title,
    required this.body,
    required this.isRead,
    required this.createdAt,
    required this.type,
    required this.isDark,
    required this.userId,
  });

  IconData get _icon {
    switch (type) {
      case 'order_status':
        if (title.contains('Ready')) return Iconsax.tick_circle;
        if (title.contains('Cancelled')) return Iconsax.close_circle;
        if (title.contains('Completed')) return Iconsax.medal_star;
        return Iconsax.receipt_item;
      case 'new_order':
        return Iconsax.shopping_bag;
      default:
        return Iconsax.notification;
    }
  }

  Color get _iconColor {
    if (title.contains('Ready')) return Colors.green;
    if (title.contains('Cancelled')) return AppColors.error;
    if (title.contains('Completed')) return Colors.amber;
    return isDark ? AppColors.primaryLight : AppColors.primary;
  }

  String _formatTime(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        if (!isRead) {
          NotificationService.markAsRead(userId, notificationId);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color:
              isRead
                  ? Colors.transparent
                  : (isDark
                      ? AppColors.primaryLight.withOpacity(0.08)
                      : AppColors.primary.withOpacity(0.05)),
          border: Border(
            bottom: BorderSide(
              color: isDark ? AppColors.borderDark : Colors.grey.shade200,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _iconColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_icon, size: 22, color: _iconColor),
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
                          title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight:
                                isRead ? FontWeight.w500 : FontWeight.w700,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                      ),
                      if (!isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color:
                                isDark
                                    ? AppColors.primaryLight
                                    : AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    body,
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    _formatTime(createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
