// lib/pages/admin/admin_stores_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_modal_dialog.dart';
import 'edit_store_page.dart';
import 'geofence_map_picker.dart';

class AdminStoresPage extends StatefulWidget {
  const AdminStoresPage({super.key});

  @override
  State<AdminStoresPage> createState() => _AdminStoresPageState();
}

class _AdminStoresPageState extends State<AdminStoresPage> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const EditStorePage()),
          );
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Store', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [_header(isDark), Expanded(child: _storesList(isDark))],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Text(
              'Manage Stores',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w700,
                color:
                    isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _storesList(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream:
          FirebaseFirestore.instance
              .collection('stores')
              .orderBy('name')
              .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs;
        if (docs.isEmpty) {
          return _emptyState(isDark);
        }

        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 100),
          itemCount: docs.length,
          itemBuilder: (_, i) => _storeCard(docs[i], isDark),
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
            Iconsax.shop,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No stores yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add Store" to create one',
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
    );
  }

  Widget _storeCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name']?.toString() ?? 'Unnamed Store';
    final description = data['description']?.toString() ?? '';
    final logoUrl = data['logoUrl']?.toString();
    final isActive = data['isActive'] ?? true;
    final latitude = (data['latitude'] as num?)?.toDouble();
    final longitude = (data['longitude'] as num?)?.toDouble();
    final geofenceRadius = (data['geofenceRadius'] as num?)?.toDouble() ?? 100;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Main info
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: SizedBox(
                    width: 56,
                    height: 56,
                    child:
                        logoUrl != null && logoUrl.isNotEmpty
                            ? Image.network(
                              logoUrl,
                              fit: BoxFit.cover,
                              errorBuilder:
                                  (_, __, ___) => _logoPlaceholder(isDark),
                            )
                            : _logoPlaceholder(isDark),
                  ),
                ),
                const SizedBox(width: 14),
                // Info
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
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color:
                                  isActive
                                      ? AppColors.success.withOpacity(0.1)
                                      : AppColors.error.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              isActive ? 'Active' : 'Inactive',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color:
                                    isActive
                                        ? AppColors.success
                                        : AppColors.error,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (description.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          description,
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
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Geofence info
          Container(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.backgroundDark : AppColors.background,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Iconsax.location,
                  size: 16,
                  color:
                      isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    latitude != null && longitude != null
                        ? 'Geofence: ${latitude.toStringAsFixed(4)}, ${longitude.toStringAsFixed(4)} (${geofenceRadius.toInt()}m)'
                        : 'No geofence configured',
                    style: TextStyle(
                      fontSize: 12,
                      color:
                          isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondary,
                    ),
                  ),
                ),
                // Actions
                IconButton(
                  icon: Icon(Iconsax.edit, size: 18, color: AppColors.primary),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder:
                            (_) => EditStorePage(
                              storeId: doc.id,
                              existingData: data,
                            ),
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: Icon(
                    Iconsax.location_tick,
                    size: 18,
                    color: AppColors.warning,
                  ),
                  onPressed: () async {
                    _showLoadingOverlay();
                    await Future.delayed(const Duration(milliseconds: 50));
                    if (mounted) Navigator.pop(context); // Dismiss loading
                    _showGeofenceDialog(doc.id, data, isDark);
                  },
                ),
                IconButton(
                  icon: Icon(Iconsax.trash, size: 18, color: AppColors.error),
                  onPressed: () async {
                    _showLoadingOverlay();
                    await Future.delayed(const Duration(milliseconds: 50));
                    if (mounted) Navigator.pop(context); // Dismiss loading
                    _deleteStore(doc.id, name);
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _logoPlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
      child: Center(
        child: Icon(
          Iconsax.shop,
          size: 24,
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
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

  // ignore: unused_element
  void _showAddStoreDialog(bool isDark) {
    final nameController = TextEditingController();
    final descController = TextEditingController();
    final logoController = TextEditingController();
    final pageContext = context; // Store page context

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(sheetContext).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _sheetHandle(isDark),
                  const SizedBox(height: 20),
                  Text(
                    'Add Store',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _textField(
                    nameController,
                    'Store Name',
                    Iconsax.shop,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _textField(
                    descController,
                    'Description',
                    Iconsax.document_text,
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _textField(logoController, 'Logo URL', Iconsax.image, isDark),
                  const SizedBox(height: 24),
                  _actionButtons(
                    isDark: isDark,
                    onCancel: () => Navigator.pop(sheetContext),
                    onConfirm: () async {
                      final name = nameController.text.trim();
                      if (name.isEmpty) {
                        await AppModalDialog.warning(
                          context: sheetContext,
                          title: 'Missing Information',
                          message: 'Store name is required.',
                        );
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('stores')
                          .add({
                            'name': name,
                            'description': descController.text.trim(),
                            'logoUrl': logoController.text.trim(),
                            'isActive': true,
                            'createdAt': FieldValue.serverTimestamp(),
                          });

                      if (mounted) {
                        Navigator.pop(sheetContext);
                        await AppModalDialog.success(
                          context:
                              pageContext, // Use page context, not sheet context
                          title: 'Store Created',
                          message: 'The store has been created.',
                        );
                      }
                    },
                    confirmLabel: 'Add Store',
                  ),
                ],
              ),
            ),
          ),
    );
  }

  // ignore: unused_element
  void _showEditStoreDialog(
    String storeId,
    Map<String, dynamic> data,
    bool isDark,
  ) {
    final nameController = TextEditingController(
      text: data['name']?.toString() ?? '',
    );
    final descController = TextEditingController(
      text: data['description']?.toString() ?? '',
    );
    final logoController = TextEditingController(
      text: data['logoUrl']?.toString() ?? '',
    );
    bool isActive = data['isActive'] ?? true;
    final pageContext = context; // Store page context

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (sheetContext) => StatefulBuilder(
            builder: (context, setSheetState) {
              final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
              return AnimatedPadding(
                duration: const Duration(milliseconds: 100),
                padding: EdgeInsets.fromLTRB(20, 20, 20, bottomInset + 20),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sheetHandle(isDark),
                      const SizedBox(height: 20),
                      Text(
                        'Edit Store',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color:
                              isDark
                                  ? AppColors.textPrimaryDark
                                  : AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _textField(
                        nameController,
                        'Store Name',
                        Iconsax.shop,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        descController,
                        'Description',
                        Iconsax.document_text,
                        isDark,
                      ),
                      const SizedBox(height: 12),
                      _textField(
                        logoController,
                        'Logo URL',
                        Iconsax.image,
                        isDark,
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        value: isActive,
                        onChanged: (val) => setSheetState(() => isActive = val),
                        title: Text(
                          'Store Active',
                          style: TextStyle(
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      const SizedBox(height: 20),
                      _actionButtons(
                        isDark: isDark,
                        onCancel: () => Navigator.pop(context),
                        onConfirm: () async {
                          final name = nameController.text.trim();
                          if (name.isEmpty) {
                            await AppModalDialog.warning(
                              context: context,
                              title: 'Missing Information',
                              message: 'Store name is required.',
                            );
                            return;
                          }

                          await FirebaseFirestore.instance
                              .collection('stores')
                              .doc(storeId)
                              .update({
                                'name': name,
                                'description': descController.text.trim(),
                                'logoUrl': logoController.text.trim(),
                                'isActive': isActive,
                                'updatedAt': FieldValue.serverTimestamp(),
                              });

                          if (mounted) {
                            Navigator.pop(context);
                            await AppModalDialog.success(
                              context:
                                  pageContext, // Use page context, not sheet context
                              title: 'Store Updated',
                              message: 'The store has been updated.',
                            );
                          }
                        },
                        confirmLabel: 'Save Changes',
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
    );
  }

  void _showGeofenceDialog(
    String storeId,
    Map<String, dynamic> data,
    bool isDark,
  ) async {
    final result = await Navigator.push<Map<String, dynamic>>(
      context,
      MaterialPageRoute(
        builder:
            (_) => GeofenceMapPicker(
              initialLat: (data['latitude'] as num?)?.toDouble(),
              initialLng: (data['longitude'] as num?)?.toDouble(),
              initialRadius:
                  (data['geofenceRadius'] as num?)?.toDouble() ?? 100,
              storeName: data['name']?.toString() ?? 'Store',
            ),
      ),
    );

    if (result != null && mounted) {
      await FirebaseFirestore.instance
          .collection('stores')
          .doc(storeId)
          .update({
            'latitude': result['latitude'],
            'longitude': result['longitude'],
            'geofenceRadius': result['radius'],
            'updatedAt': FieldValue.serverTimestamp(),
          });

      if (mounted) {
        await AppModalDialog.success(
          context: context,
          title: 'Geofence Updated',
          message: 'The geofence has been configured.',
        );
      }
    }
  }

  Future<void> _deleteStore(String storeId, String storeName) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Delete Store?',
      message:
          'This will permanently delete "$storeName" and all menu items, categories, and orders. This cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      try {
        final storeRef = FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId);

        // Delete all subcollections first
        final batch = FirebaseFirestore.instance.batch();

        // Delete menu items
        final menuItems = await storeRef.collection('menu').get();
        for (final doc in menuItems.docs) {
          batch.delete(doc.reference);
        }

        // Delete categories
        final categories = await storeRef.collection('categories').get();
        for (final doc in categories.docs) {
          batch.delete(doc.reference);
        }

        // Delete orders
        final orders = await storeRef.collection('orders').get();
        for (final doc in orders.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        // Now delete the store document
        await storeRef.delete();

        if (mounted) {
          await AppModalDialog.success(
            context: context,
            title: 'Store Deleted',
            message: 'The store and all related data have been deleted.',
          );
        }
      } catch (e) {
        if (mounted) {
          await AppModalDialog.error(
            context: context,
            title: 'Error',
            message: 'Failed to delete store: $e',
          );
        }
      }
    }
  }

  Widget _sheetHandle(bool isDark) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? AppColors.borderDark : AppColors.border,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _textField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType:
          isNumber
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.text,
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.primary),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
    );
  }

  Widget _actionButtons({
    required bool isDark,
    required VoidCallback onCancel,
    required VoidCallback onConfirm,
    required String confirmLabel,
  }) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              side: BorderSide(
                color: isDark ? AppColors.borderDark : AppColors.border,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
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
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(confirmLabel),
          ),
        ),
      ],
    );
  }
}
