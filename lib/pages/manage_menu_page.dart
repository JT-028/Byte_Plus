// lib/pages/manage_menu_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/app_modal_dialog.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  String? storeId;
  String selectedCategory = 'All';
  bool showUnavailableOnly = false;
  bool storeIdLoaded = false;

  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final imageUrlController = TextEditingController();
  final categoryController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadStoreId();
  }

  Future<void> _loadStoreId() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => storeIdLoaded = true);
      return;
    }

    try {
      final userDoc =
          await FirebaseFirestore.instance.collection('users').doc(uid).get();

      if (userDoc.exists) {
        final loadedStoreId = userDoc.data()?['storeId']?.toString();
        setState(() {
          storeId = (loadedStoreId?.isNotEmpty == true) ? loadedStoreId : null;
          storeIdLoaded = true;
        });
      } else {
        setState(() => storeIdLoaded = true);
      }
    } catch (e) {
      setState(() => storeIdLoaded = true);
      debugPrint('Error loading storeId: $e');
    }
  }

  CollectionReference get menuCollection {
    return FirebaseFirestore.instance
        .collection('stores')
        .doc(storeId)
        .collection('menu');
  }

  Future<void> _toggleAvailability(String productId, bool currentStatus) async {
    if (storeId == null) return;

    await InventoryService.toggleProductAvailability(
      storeId: storeId!,
      productId: productId,
      isAvailable: !currentStatus,
    );

    if (mounted) {
      await AppModalDialog.success(
        context: context,
        title: currentStatus ? 'Item Unavailable' : 'Item Available',
        message:
            currentStatus
                ? 'This item has been marked as unavailable.'
                : 'This item is now available for ordering.',
      );
    }
  }

  Future<void> _addOrEditItem({
    String? id,
    Map<String, dynamic>? existing,
  }) async {
    final name = nameController.text.trim();
    final priceText = priceController.text.trim();
    final imageUrl = imageUrlController.text.trim();
    final category = categoryController.text.trim();

    if (name.isEmpty || priceText.isEmpty) {
      await AppModalDialog.warning(
        context: context,
        title: 'Missing Information',
        message: 'Name and price are required.',
      );
      return;
    }

    final price = int.tryParse(priceText) ?? 0;

    final data = {
      'name': name,
      'price': price,
      'imageUrl': imageUrl,
      'category': category.isNotEmpty ? [category] : [],
      'isAvailable': existing?['isAvailable'] ?? true,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (id == null) {
      data['createdAt'] = FieldValue.serverTimestamp();
      await menuCollection.add(data);
      if (mounted) {
        Navigator.pop(context);
        await AppModalDialog.success(
          context: context,
          title: 'Item Added',
          message: 'The menu item has been added successfully.',
        );
      }
    } else {
      await menuCollection.doc(id).update(data);
      if (mounted) {
        Navigator.pop(context);
        await AppModalDialog.success(
          context: context,
          title: 'Item Updated',
          message: 'The menu item has been updated successfully.',
        );
      }
    }

    _clearControllers();
  }

  void _clearControllers() {
    nameController.clear();
    priceController.clear();
    imageUrlController.clear();
    categoryController.clear();
  }

  void _showAddEditDialog({String? id, Map<String, dynamic>? existing}) {
    nameController.text = existing?['name'] ?? '';
    priceController.text = existing?['price']?.toString() ?? '';
    imageUrlController.text = existing?['imageUrl'] ?? '';
    categoryController.text =
        (existing?['category'] as List?)?.first?.toString() ?? '';

    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              20,
              20,
              MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  id == null ? 'Add Menu Item' : 'Edit Menu Item',
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
                _buildTextField(
                  nameController,
                  'Item Name',
                  Iconsax.tag,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  priceController,
                  'Price (₱)',
                  Iconsax.money,
                  isDark,
                  isNumber: true,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  imageUrlController,
                  'Image URL',
                  Iconsax.image,
                  isDark,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  categoryController,
                  'Category',
                  Iconsax.category,
                  isDark,
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          _clearControllers();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color:
                                isDark
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
                        onPressed:
                            () => _addOrEditItem(id: id, existing: existing),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.merchantPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(id == null ? 'Add Item' : 'Save Changes'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    IconData icon,
    bool isDark, {
    bool isNumber = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
        ),
        prefixIcon: Icon(icon, color: AppColors.merchantPrimary),
        filled: true,
        fillColor: isDark ? AppColors.surfaceVariantDark : AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.merchantPrimary,
            width: 2,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!storeIdLoaded) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (storeId == null) {
      return Scaffold(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.box_1,
                  size: 80,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(height: 24),
                Text(
                  'No Store Connected',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                Text(
                  'Menu management will be available once your store is set up.',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEditDialog(),
        backgroundColor: AppColors.merchantPrimary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Add Item', style: TextStyle(color: Colors.white)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildFilterRow(isDark),
            Expanded(child: _buildMenuGrid(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Menu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                FutureBuilder<Map<String, int>>(
                  future: InventoryService.getInventorySummary(storeId!),
                  builder: (context, snap) {
                    if (!snap.hasData) return const SizedBox();
                    final data = snap.data!;
                    return Text(
                      '${data['available']} available • ${data['unavailable']} unavailable',
                      style: TextStyle(
                        fontSize: 14,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterRow(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          FilterChip(
            label: const Text('Unavailable Only'),
            selected: showUnavailableOnly,
            onSelected: (val) => setState(() => showUnavailableOnly = val),
            selectedColor: AppColors.error.withOpacity(0.2),
            checkmarkColor: AppColors.error,
            labelStyle: TextStyle(
              color:
                  showUnavailableOnly
                      ? AppColors.error
                      : (isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuGrid(bool isDark) {
    return StreamBuilder<QuerySnapshot>(
      stream: menuCollection.orderBy('name').snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Text(
              'Failed to load menu',
              style: TextStyle(
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        var docs = snap.data!.docs;

        // Filter by availability
        if (showUnavailableOnly) {
          docs =
              docs.where((doc) {
                final data = doc.data() as Map<String, dynamic>;
                return !(data['isAvailable'] ?? true);
              }).toList();
        }

        if (docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Iconsax.box_1,
                  size: 64,
                  color:
                      isDark
                          ? AppColors.textTertiaryDark
                          : AppColors.textTertiary,
                ),
                const SizedBox(height: 16),
                Text(
                  showUnavailableOnly
                      ? 'No unavailable items'
                      : 'No menu items yet',
                  style: TextStyle(
                    fontSize: 16,
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

        return GridView.builder(
          padding: const EdgeInsets.all(20),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: docs.length,
          itemBuilder: (_, i) => _buildMenuCard(docs[i], isDark),
        );
      },
    );
  }

  Widget _buildMenuCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['name'] ?? '';
    final price = data['price'] ?? 0;
    final imageUrl = data['imageUrl'] ?? '';
    final isAvailable = data['isAvailable'] ?? true;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image
              Expanded(
                child: ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      imageUrl.isNotEmpty
                          ? Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder:
                                (_, __, ___) => _imagePlaceholder(isDark),
                          )
                          : _imagePlaceholder(isDark),
                      if (!isAvailable)
                        Container(
                          color: Colors.black.withOpacity(0.5),
                          alignment: Alignment.center,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.error,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Text(
                              'OUT OF STOCK',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              // Info
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₱$price',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.merchantPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap:
                                () => _toggleAvailability(doc.id, isAvailable),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 6),
                              decoration: BoxDecoration(
                                color:
                                    isAvailable
                                        ? AppColors.success.withOpacity(0.1)
                                        : AppColors.error.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    isAvailable
                                        ? Iconsax.tick_circle
                                        : Iconsax.close_circle,
                                    size: 14,
                                    color:
                                        isAvailable
                                            ? AppColors.success
                                            : AppColors.error,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    isAvailable ? 'Available' : 'Unavailable',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color:
                                          isAvailable
                                              ? AppColors.success
                                              : AppColors.error,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap:
                              () => _showAddEditDialog(
                                id: doc.id,
                                existing: data,
                              ),
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.merchantPrimary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Iconsax.edit,
                              size: 16,
                              color: AppColors.merchantPrimary,
                            ),
                          ),
                        ),
                      ],
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

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
      child: Icon(
        Iconsax.image,
        size: 40,
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
    );
  }
}
