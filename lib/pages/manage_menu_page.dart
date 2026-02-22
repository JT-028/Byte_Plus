// lib/pages/manage_menu_page.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../services/inventory_service.dart';
import '../widgets/app_modal_dialog.dart';
import 'add_item_page.dart';
import 'add_category_page.dart';

class ManageMenuPage extends StatefulWidget {
  const ManageMenuPage({super.key});

  @override
  State<ManageMenuPage> createState() => _ManageMenuPageState();
}

class _ManageMenuPageState extends State<ManageMenuPage> {
  String? storeId;
  bool storeIdLoaded = false;
  Set<String> expandedCategories = {};
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  @override
  void initState() {
    super.initState();
    _listenToStoreId();
  }

  @override
  void dispose() {
    _userDocSubscription?.cancel();
    super.dispose();
  }

  void _listenToStoreId() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    debugPrint('[ManageMenuPage] Current user UID: $uid');
    if (uid == null) {
      setState(() => storeIdLoaded = true);
      return;
    }

    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (doc) {
            if (!mounted) return;

            if (doc.exists) {
              final loadedStoreId = doc.data()?['storeId']?.toString();
              debugPrint('[ManageMenuPage] User doc storeId: $loadedStoreId');
              setState(() {
                storeId =
                    (loadedStoreId?.isNotEmpty == true) ? loadedStoreId : null;
                storeIdLoaded = true;
              });
            } else {
              debugPrint('[ManageMenuPage] User doc does not exist');
              setState(() {
                storeId = null;
                storeIdLoaded = true;
              });
            }
          },
          onError: (e) {
            debugPrint('Error listening to storeId: $e');
            if (mounted) {
              setState(() => storeIdLoaded = true);
            }
          },
        );
  }

  CollectionReference get menuCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('menu');

  CollectionReference get categoriesCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('categories');

  CollectionReference get variationsCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('variations');

  CollectionReference get choiceGroupsCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(storeId)
      .collection('choiceGroups');

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
      return _noStoreState(isDark);
    }

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(isDark),
            Expanded(child: _buildCategoriesAndProducts(isDark)),
          ],
        ),
      ),
    );
  }

  Widget _noStoreState(bool isDark) {
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Menu',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          _addNewDropdown(isDark),
        ],
      ),
    );
  }

  Widget _addNewDropdown(bool isDark) {
    return PopupMenuButton<String>(
      onSelected: (value) async {
        if (storeId == null) return;
        switch (value) {
          case 'item':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddItemPage(storeId: storeId!),
              ),
            );
            break;
          case 'category':
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddCategoryPage(storeId: storeId!),
              ),
            );
            break;
        }
      },
      offset: const Offset(0, 44),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Colors.white, size: 18),
            SizedBox(width: 6),
            Text(
              'Add New',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            SizedBox(width: 4),
            Icon(Icons.keyboard_arrow_down, color: Colors.white, size: 18),
          ],
        ),
      ),
      itemBuilder:
          (context) => [
            _popupMenuItem('item', 'Item', Iconsax.box, isDark),
            _popupMenuItem('category', 'Category', Iconsax.folder, isDark),
          ],
    );
  }

  PopupMenuItem<String> _popupMenuItem(
    String value,
    String label,
    IconData icon,
    bool isDark,
  ) {
    return PopupMenuItem<String>(
      value: value,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color:
                isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
          ),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoriesAndProducts(bool isDark) {
    debugPrint('[ManageMenuPage] Building with storeId: $storeId');
    return StreamBuilder<QuerySnapshot>(
      stream: categoriesCollection.orderBy('name').snapshots(),
      builder: (context, catSnap) {
        return StreamBuilder<QuerySnapshot>(
          stream: menuCollection.orderBy('name').snapshots(),
          builder: (context, prodSnap) {
            if (catSnap.hasError) {
              debugPrint('[ManageMenuPage] Categories error: ${catSnap.error}');
            }
            if (prodSnap.hasError) {
              debugPrint('[ManageMenuPage] Products error: ${prodSnap.error}');
            }
            if (!catSnap.hasData || !prodSnap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final categories = catSnap.data!.docs;
            final products = prodSnap.data!.docs;
            debugPrint(
              '[ManageMenuPage] Found ${categories.length} categories, ${products.length} products',
            );

            // Group products by category
            final Map<String, List<DocumentSnapshot>> productsByCategory = {};
            final List<DocumentSnapshot> uncategorized = [];

            // Track category names from category documents
            final Set<String> categoryDocNames = {};
            for (final cat in categories) {
              final catData = cat.data() as Map<String, dynamic>?;
              if (catData != null) {
                final name = catData['name']?.toString();
                if (name != null) categoryDocNames.add(name);
              }
            }

            for (final product in products) {
              final data = product.data() as Map<String, dynamic>?;
              if (data == null) continue;
              final categoryList = data['category'] as List?;
              if (categoryList != null && categoryList.isNotEmpty) {
                final catName = categoryList.first.toString();
                productsByCategory.putIfAbsent(catName, () => []);
                productsByCategory[catName]!.add(product);
              } else {
                uncategorized.add(product);
              }
            }

            // Get all unique category names (from docs + from products)
            final allCategoryNames = <String>{
              ...categoryDocNames,
              ...productsByCategory.keys,
            };

            if (allCategoryNames.isEmpty && products.isEmpty) {
              return _emptyState(isDark);
            }

            // Sort category names alphabetically
            final sortedCategoryNames = allCategoryNames.toList()..sort();

            return SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                  // Category sections (from both docs and product categories)
                  ...sortedCategoryNames.map((catName) {
                    // Find the category doc ID if it exists
                    String catId = catName.toLowerCase().replaceAll(' ', '_');
                    for (final cat in categories) {
                      final catData = cat.data() as Map<String, dynamic>?;
                      if (catData?['name']?.toString() == catName) {
                        catId = cat.id;
                        break;
                      }
                    }
                    final catProducts = productsByCategory[catName] ?? [];
                    return _categorySection(
                      catName,
                      catId,
                      catProducts,
                      isDark,
                    );
                  }),

                  // Uncategorized section
                  if (uncategorized.isNotEmpty)
                    _categorySection(
                      'Uncategorized',
                      'uncategorized',
                      uncategorized,
                      isDark,
                    ),
                ],
              ),
            );
          },
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
            Iconsax.box_1,
            size: 64,
            color: isDark ? AppColors.textTertiaryDark : Colors.grey.shade400,
          ),
          const SizedBox(height: 16),
          Text(
            'No Menu Items Yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Tap "Add New" to create categories and products',
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

  Widget _categorySection(
    String categoryName,
    String categoryId,
    List<DocumentSnapshot> products,
    bool isDark,
  ) {
    final isExpanded = expandedCategories.contains(categoryId);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () {
              setState(() {
                if (isExpanded) {
                  expandedCategories.remove(categoryId);
                } else {
                  expandedCategories.add(categoryId);
                }
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Center(
                      child: Icon(
                        Iconsax.folder,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          categoryName,
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
                          '${products.length} items',
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
                  if (categoryId != 'uncategorized')
                    IconButton(
                      icon: Icon(
                        Iconsax.more,
                        color:
                            isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed:
                          () => _showCategoryOptions(
                            categoryId,
                            categoryName,
                            isDark,
                          ),
                    ),
                  Icon(
                    isExpanded ? Iconsax.arrow_up_2 : Iconsax.arrow_down_1,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Products (if expanded)
          if (isExpanded && products.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                children: products.map((p) => _productCard(p, isDark)).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _productCard(DocumentSnapshot doc, bool isDark) {
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return const SizedBox.shrink();

    final name = data['name']?.toString() ?? '';
    final price = (data['price'] as num?)?.toDouble() ?? 0;
    final imageUrl = data['imageUrl']?.toString() ?? '';
    final isAvailable = data['isAvailable'] ?? true;

    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : Colors.grey.shade200,
        ),
      ),
      child: Row(
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: SizedBox(
              width: 60,
              height: 60,
              child:
                  imageUrl.isNotEmpty
                      ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                      )
                      : _imagePlaceholder(isDark),
            ),
          ),
          const SizedBox(width: 12),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '₱ ${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          // Availability toggle
          GestureDetector(
            onTap: () => _toggleAvailability(doc.id, isAvailable),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color:
                    isAvailable
                        ? AppColors.success.withOpacity(0.1)
                        : AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                isAvailable ? 'Available' : 'Unavailable',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isAvailable ? AppColors.success : AppColors.error,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Edit button
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder:
                      (context) => AddItemPage(
                        storeId: storeId!,
                        itemId: doc.id,
                        existingData: data,
                      ),
                ),
              );
            },
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Iconsax.edit,
                size: 16,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imagePlaceholder(bool isDark) {
    return Container(
      color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
      child: Center(
        child: Icon(
          Iconsax.image,
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

  // ============================================
  // DIALOG: Add Category
  // ============================================
  void _showAddCategoryDialog(bool isDark) {
    final nameController = TextEditingController();
    final pageContext = context;

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
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _sheetHandle(isDark),
                const SizedBox(height: 20),
                Text(
                  'Add Category',
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
                  controller: nameController,
                  label: 'Category Name',
                  icon: Iconsax.folder,
                  isDark: isDark,
                ),
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
                        message: 'Category name is required.',
                      );
                      return;
                    }

                    await categoriesCollection.add({
                      'name': name,
                      'createdAt': FieldValue.serverTimestamp(),
                    });

                    if (mounted) {
                      Navigator.pop(sheetContext);
                      await AppModalDialog.success(
                        context: pageContext,
                        title: 'Category Added',
                        message: 'The category has been created.',
                      );
                    }
                  },
                  confirmLabel: 'Add Category',
                ),
              ],
            ),
          ),
    );
  }

  // ============================================
  // DIALOG: Add Product
  // ============================================
  void _showAddProductDialog(bool isDark) {
    final nameController = TextEditingController();
    final priceController = TextEditingController();
    final imageUrlController = TextEditingController();
    String? selectedCategory;
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(isDark),
                        const SizedBox(height: 20),
                        Text(
                          'Add Product',
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
                          controller: nameController,
                          label: 'Product Name',
                          icon: Iconsax.box,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: priceController,
                          label: 'Price (₱)',
                          icon: Iconsax.money,
                          isDark: isDark,
                          isNumber: true,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: imageUrlController,
                          label: 'Image URL',
                          icon: Iconsax.image,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        // Category dropdown
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              categoriesCollection.orderBy('name').snapshots(),
                          builder: (context, snap) {
                            final cats = snap.data?.docs ?? [];
                            return DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: _dropdownDecoration(
                                'Category',
                                Iconsax.folder,
                                isDark,
                              ),
                              dropdownColor:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No Category'),
                                ),
                                ...cats.map((c) {
                                  final data =
                                      c.data() as Map<String, dynamic>?;
                                  if (data == null) return null;
                                  final name = data['name']?.toString() ?? '';
                                  return DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).whereType<DropdownMenuItem<String>>(),
                              ],
                              onChanged:
                                  (val) => setSheetState(
                                    () => selectedCategory = val,
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _actionButtons(
                          isDark: isDark,
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () async {
                            final name = nameController.text.trim();
                            final priceText = priceController.text.trim();
                            final imageUrl = imageUrlController.text.trim();

                            if (name.isEmpty || priceText.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'Name and price are required.',
                              );
                              return;
                            }

                            final price = double.tryParse(priceText) ?? 0;

                            await menuCollection.add({
                              'name': name,
                              'price': price,
                              'imageUrl': imageUrl,
                              'category':
                                  selectedCategory != null
                                      ? [selectedCategory]
                                      : [],
                              'isAvailable': true,
                              'createdAt': FieldValue.serverTimestamp(),
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              await AppModalDialog.success(
                                context: pageContext,
                                title: 'Product Added',
                                message:
                                    'The product has been added to the menu.',
                              );
                            }
                          },
                          confirmLabel: 'Add Product',
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ============================================
  // DIALOG: Edit Product
  // ============================================
  void _showEditProductDialog(
    String productId,
    Map<String, dynamic> existing,
    bool isDark,
  ) {
    final nameController = TextEditingController(
      text: existing['name']?.toString() ?? '',
    );
    final priceController = TextEditingController(
      text: existing['price']?.toString() ?? '',
    );
    final imageUrlController = TextEditingController(
      text: existing['imageUrl']?.toString() ?? '',
    );
    String? selectedCategory =
        (existing['category'] as List?)?.firstOrNull?.toString();
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(isDark),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Edit Product',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.trash,
                                color: AppColors.error,
                              ),
                              onPressed: () async {
                                _showLoadingOverlay();
                                await Future.delayed(
                                  const Duration(milliseconds: 50),
                                );
                                if (mounted) {
                                  Navigator.pop(context); // Dismiss loading
                                }
                                _deleteProduct(productId);
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _textField(
                          controller: nameController,
                          label: 'Product Name',
                          icon: Iconsax.box,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: priceController,
                          label: 'Price (₱)',
                          icon: Iconsax.money,
                          isDark: isDark,
                          isNumber: true,
                        ),
                        const SizedBox(height: 12),
                        _textField(
                          controller: imageUrlController,
                          label: 'Image URL',
                          icon: Iconsax.image,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 12),
                        StreamBuilder<QuerySnapshot>(
                          stream:
                              categoriesCollection.orderBy('name').snapshots(),
                          builder: (context, snap) {
                            final cats = snap.data?.docs ?? [];
                            return DropdownButtonFormField<String>(
                              initialValue: selectedCategory,
                              decoration: _dropdownDecoration(
                                'Category',
                                Iconsax.folder,
                                isDark,
                              ),
                              dropdownColor:
                                  isDark ? AppColors.surfaceDark : Colors.white,
                              items: [
                                const DropdownMenuItem(
                                  value: null,
                                  child: Text('No Category'),
                                ),
                                ...cats.map((c) {
                                  final data =
                                      c.data() as Map<String, dynamic>?;
                                  if (data == null) return null;
                                  final name = data['name']?.toString() ?? '';
                                  return DropdownMenuItem(
                                    value: name,
                                    child: Text(name),
                                  );
                                }).whereType<DropdownMenuItem<String>>(),
                              ],
                              onChanged:
                                  (val) => setSheetState(
                                    () => selectedCategory = val,
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        _actionButtons(
                          isDark: isDark,
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () async {
                            final name = nameController.text.trim();
                            final priceText = priceController.text.trim();
                            final imageUrl = imageUrlController.text.trim();

                            if (name.isEmpty || priceText.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'Name and price are required.',
                              );
                              return;
                            }

                            final price = double.tryParse(priceText) ?? 0;

                            await menuCollection.doc(productId).update({
                              'name': name,
                              'price': price,
                              'imageUrl': imageUrl,
                              'category':
                                  selectedCategory != null
                                      ? [selectedCategory]
                                      : [],
                              'updatedAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              await AppModalDialog.success(
                                context: pageContext,
                                title: 'Product Updated',
                                message: 'The product has been updated.',
                              );
                            }
                          },
                          confirmLabel: 'Save Changes',
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ============================================
  // DIALOG: Add Variation
  // ============================================
  void _showAddVariationDialog(bool isDark) {
    final nameController = TextEditingController();
    final List<Map<String, TextEditingController>> options = [
      {'name': TextEditingController(), 'price': TextEditingController()},
    ];
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(isDark),
                        const SizedBox(height: 20),
                        Text(
                          'Add Variation',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'E.g., Size with Regular, Large options',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _textField(
                          controller: nameController,
                          label: 'Variation Name (e.g., Size)',
                          icon: Iconsax.size,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Options',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final opt = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: opt['name'],
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Option name',
                                      hintStyle: TextStyle(
                                        color:
                                            isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? AppColors.backgroundDark
                                              : AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: opt['price'],
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '+ ₱',
                                      hintStyle: TextStyle(
                                        color:
                                            isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? AppColors.backgroundDark
                                              : AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (options.length > 1)
                                  GestureDetector(
                                    onTap:
                                        () => setSheetState(
                                          () => options.removeAt(i),
                                        ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Iconsax.minus,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap:
                              () => setSheetState(
                                () => options.add({
                                  'name': TextEditingController(),
                                  'price': TextEditingController(),
                                }),
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isDark
                                        ? AppColors.borderDark
                                        : AppColors.border,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.add,
                                  size: 16,
                                  color:
                                      isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Option',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _actionButtons(
                          isDark: isDark,
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'Variation name is required.',
                              );
                              return;
                            }

                            final optionsList =
                                options
                                    .map(
                                      (o) => {
                                        'name': o['name']!.text.trim(),
                                        'additionalPrice':
                                            double.tryParse(
                                              o['price']!.text.trim(),
                                            ) ??
                                            0,
                                      },
                                    )
                                    .where(
                                      (o) => (o['name'] as String).isNotEmpty,
                                    )
                                    .toList();

                            if (optionsList.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'At least one option is required.',
                              );
                              return;
                            }

                            await variationsCollection.add({
                              'name': name,
                              'options': optionsList,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              await AppModalDialog.success(
                                context: pageContext,
                                title: 'Variation Added',
                                message: 'The variation has been created.',
                              );
                            }
                          },
                          confirmLabel: 'Add Variation',
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ============================================
  // DIALOG: Add Choice Group
  // ============================================
  void _showAddChoiceGroupDialog(bool isDark) {
    final nameController = TextEditingController();
    bool isRequired = false;
    bool allowMultiple = true;
    final List<Map<String, TextEditingController>> choices = [
      {'name': TextEditingController(), 'price': TextEditingController()},
    ];
    final pageContext = context;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => StatefulBuilder(
            builder:
                (context, setSheetState) => Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    20,
                    20,
                    MediaQuery.of(context).viewInsets.bottom + 20,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _sheetHandle(isDark),
                        const SizedBox(height: 20),
                        Text(
                          'Add Choice Group',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'E.g., Toppings, Add-ons',
                          style: TextStyle(
                            fontSize: 13,
                            color:
                                isDark
                                    ? AppColors.textSecondaryDark
                                    : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 20),
                        _textField(
                          controller: nameController,
                          label: 'Group Name (e.g., Toppings)',
                          icon: Iconsax.menu_board,
                          isDark: isDark,
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: CheckboxListTile(
                                value: isRequired,
                                onChanged:
                                    (v) => setSheetState(
                                      () => isRequired = v ?? false,
                                    ),
                                title: Text(
                                  'Required',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                              ),
                            ),
                            Expanded(
                              child: CheckboxListTile(
                                value: allowMultiple,
                                onChanged:
                                    (v) => setSheetState(
                                      () => allowMultiple = v ?? true,
                                    ),
                                title: Text(
                                  'Multiple',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        isDark
                                            ? AppColors.textPrimaryDark
                                            : AppColors.textPrimary,
                                  ),
                                ),
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                                activeColor: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Choices',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...choices.asMap().entries.map((entry) {
                          final i = entry.key;
                          final ch = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: TextField(
                                    controller: ch['name'],
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: 'Choice name',
                                      hintStyle: TextStyle(
                                        color:
                                            isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? AppColors.backgroundDark
                                              : AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: ch['price'],
                                    keyboardType: TextInputType.number,
                                    style: TextStyle(
                                      color:
                                          isDark
                                              ? AppColors.textPrimaryDark
                                              : AppColors.textPrimary,
                                    ),
                                    decoration: InputDecoration(
                                      hintText: '+ ₱',
                                      hintStyle: TextStyle(
                                        color:
                                            isDark
                                                ? AppColors.textTertiaryDark
                                                : AppColors.textTertiary,
                                      ),
                                      filled: true,
                                      fillColor:
                                          isDark
                                              ? AppColors.backgroundDark
                                              : AppColors.background,
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                        borderSide: BorderSide.none,
                                      ),
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 12,
                                            vertical: 10,
                                          ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                if (choices.length > 1)
                                  GestureDetector(
                                    onTap:
                                        () => setSheetState(
                                          () => choices.removeAt(i),
                                        ),
                                    child: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: AppColors.error.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Icon(
                                        Iconsax.minus,
                                        size: 16,
                                        color: AppColors.error,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        }),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap:
                              () => setSheetState(
                                () => choices.add({
                                  'name': TextEditingController(),
                                  'price': TextEditingController(),
                                }),
                              ),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            decoration: BoxDecoration(
                              border: Border.all(
                                color:
                                    isDark
                                        ? AppColors.borderDark
                                        : AppColors.border,
                                style: BorderStyle.solid,
                              ),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Iconsax.add,
                                  size: 16,
                                  color:
                                      isDark
                                          ? AppColors.textSecondaryDark
                                          : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'Add Choice',
                                  style: TextStyle(
                                    color:
                                        isDark
                                            ? AppColors.textSecondaryDark
                                            : AppColors.textSecondary,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        _actionButtons(
                          isDark: isDark,
                          onCancel: () => Navigator.pop(context),
                          onConfirm: () async {
                            final name = nameController.text.trim();
                            if (name.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'Group name is required.',
                              );
                              return;
                            }

                            final choicesList =
                                choices
                                    .map(
                                      (c) => {
                                        'name': c['name']!.text.trim(),
                                        'additionalPrice':
                                            double.tryParse(
                                              c['price']!.text.trim(),
                                            ) ??
                                            0,
                                      },
                                    )
                                    .where(
                                      (c) => (c['name'] as String).isNotEmpty,
                                    )
                                    .toList();

                            if (choicesList.isEmpty) {
                              await AppModalDialog.warning(
                                context: context,
                                title: 'Missing Information',
                                message: 'At least one choice is required.',
                              );
                              return;
                            }

                            await choiceGroupsCollection.add({
                              'name': name,
                              'isRequired': isRequired,
                              'allowMultiple': allowMultiple,
                              'choices': choicesList,
                              'createdAt': FieldValue.serverTimestamp(),
                            });

                            if (mounted) {
                              Navigator.pop(context);
                              await AppModalDialog.success(
                                context: pageContext,
                                title: 'Choice Group Added',
                                message: 'The choice group has been created.',
                              );
                            }
                          },
                          confirmLabel: 'Add Choice Group',
                        ),
                      ],
                    ),
                  ),
                ),
          ),
    );
  }

  // ============================================
  // CATEGORY OPTIONS
  // ============================================

  Future<void> _editCategory(String categoryId) async {
    // Fetch category data and navigate to edit page
    final catDoc =
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(storeId)
            .collection('categories')
            .doc(categoryId)
            .get();
    if (mounted && catDoc.exists) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder:
              (context) => AddCategoryPage(
                storeId: storeId!,
                categoryId: categoryId,
                existingData: catDoc.data(),
              ),
        ),
      );
    }
  }

  void _showCategoryOptions(
    String categoryId,
    String categoryName,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder:
          (context) => SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _sheetHandle(isDark),
                  const SizedBox(height: 20),
                  Text(
                    categoryName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _optionTile(
                    icon: Iconsax.edit,
                    label: 'Edit Category',
                    isDark: isDark,
                    onTap: () {
                      Navigator.pop(context);
                      _editCategory(categoryId);
                    },
                  ),
                  const SizedBox(height: 12),
                  _optionTile(
                    icon: Iconsax.trash,
                    label: 'Delete Category',
                    isDark: isDark,
                    isDestructive: true,
                    onTap: () async {
                      Navigator.pop(context);
                      _showLoadingOverlay();
                      await Future.delayed(const Duration(milliseconds: 50));
                      if (mounted) Navigator.pop(context); // Dismiss loading
                      _deleteCategory(categoryId, categoryName);
                    },
                  ),
                ],
              ),
            ),
          ),
    );
  }

  Widget _optionTile({
    required IconData icon,
    required String label,
    required bool isDark,
    bool isDestructive = false,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: isDark ? AppColors.backgroundDark : AppColors.background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 20,
                color:
                    isDestructive
                        ? AppColors.error
                        : (isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      isDestructive
                          ? AppColors.error
                          : (isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _renameCategory(
    String categoryId,
    String currentName,
    bool isDark,
  ) async {
    final nameController = TextEditingController(text: currentName);

    await showModalBottomSheet(
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
                _sheetHandle(isDark),
                const SizedBox(height: 20),
                Text(
                  'Rename Category',
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
                  controller: nameController,
                  label: 'Category Name',
                  icon: Iconsax.folder,
                  isDark: isDark,
                ),
                const SizedBox(height: 24),
                _actionButtons(
                  isDark: isDark,
                  onCancel: () => Navigator.pop(context),
                  onConfirm: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) {
                      await AppModalDialog.warning(
                        context: context,
                        title: 'Missing Information',
                        message: 'Category name is required.',
                      );
                      return;
                    }

                    // Update category doc
                    await categoriesCollection.doc(categoryId).update({
                      'name': name,
                      'updatedAt': FieldValue.serverTimestamp(),
                    });

                    // Update products with old category name
                    final productsWithOldCategory =
                        await menuCollection
                            .where('category', arrayContains: currentName)
                            .get();

                    for (final doc in productsWithOldCategory.docs) {
                      final data = doc.data() as Map<String, dynamic>?;
                      if (data == null) continue;
                      final categories = List<String>.from(
                        data['category'] ?? [],
                      );
                      final index = categories.indexOf(currentName);
                      if (index != -1) {
                        categories[index] = name;
                        await menuCollection.doc(doc.id).update({
                          'category': categories,
                        });
                      }
                    }

                    if (mounted) {
                      Navigator.pop(context);
                      await AppModalDialog.success(
                        context: context,
                        title: 'Category Renamed',
                        message: 'The category has been renamed.',
                      );
                    }
                  },
                  confirmLabel: 'Save',
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _deleteCategory(String categoryId, String categoryName) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Delete Category?',
      message: 'Products in this category will become uncategorized.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      // Remove category from products
      final productsWithCategory =
          await menuCollection
              .where('category', arrayContains: categoryName)
              .get();

      for (final doc in productsWithCategory.docs) {
        final data = doc.data() as Map<String, dynamic>?;
        if (data == null) continue;
        final categories = List<String>.from(data['category'] ?? []);
        categories.remove(categoryName);
        await menuCollection.doc(doc.id).update({'category': categories});
      }

      // Delete category doc
      await categoriesCollection.doc(categoryId).delete();

      if (mounted) {
        await AppModalDialog.success(
          context: context,
          title: 'Category Deleted',
          message: 'The category has been deleted.',
        );
      }
    }
  }

  Future<void> _deleteProduct(String productId) async {
    final ok = await AppModalDialog.confirm(
      context: context,
      title: 'Delete Product?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDanger: true,
    );

    if (ok == true) {
      Navigator.pop(context); // Close edit sheet
      await menuCollection.doc(productId).delete();

      if (mounted) {
        await AppModalDialog.success(
          context: context,
          title: 'Product Deleted',
          message: 'The product has been deleted.',
        );
      }
    }
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

  // ============================================
  // UI HELPERS
  // ============================================
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

  Widget _textField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required bool isDark,
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

  InputDecoration _dropdownDecoration(
    String label,
    IconData icon,
    bool isDark,
  ) {
    return InputDecoration(
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
