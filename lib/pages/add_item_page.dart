// lib/pages/add_item_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

class AddItemPage extends StatefulWidget {
  final String storeId;
  final String? itemId; // null for new item, non-null for edit
  final Map<String, dynamic>? existingData;

  const AddItemPage({
    super.key,
    required this.storeId,
    this.itemId,
    this.existingData,
  });

  @override
  State<AddItemPage> createState() => _AddItemPageState();
}

class _AddItemPageState extends State<AddItemPage> {
  final _nameController = TextEditingController();
  final _stockController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _basePriceController = TextEditingController();
  final _imageUrlController = TextEditingController();

  String? _selectedCategory;
  bool _isLoading = false;

  // Variations: List of {name: String, price: double}
  List<Map<String, dynamic>> _variations = [];

  // Choice Groups: List of {name, isRequired, maxSelections, choices: List<{name, price}>}
  List<Map<String, dynamic>> _choiceGroups = [];

  bool get isEditing => widget.itemId != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _loadExistingData();
    }
  }

  void _loadExistingData() {
    final data = widget.existingData!;
    _nameController.text = data['name']?.toString() ?? '';
    _stockController.text = data['stock']?.toString() ?? '';
    _descriptionController.text = data['description']?.toString() ?? '';
    _basePriceController.text = data['price']?.toString() ?? '';
    _imageUrlController.text = data['imageUrl']?.toString() ?? '';

    final categoryList = data['category'] as List?;
    if (categoryList != null && categoryList.isNotEmpty) {
      _selectedCategory = categoryList.first.toString();
    }

    // Load variations
    final variations = data['variations'] as List?;
    if (variations != null) {
      _variations =
          variations.map((v) {
            return {
              'name': v['name']?.toString() ?? '',
              'price': (v['price'] as num?)?.toDouble() ?? 0.0,
            };
          }).toList();
    }

    // Load choice groups
    final choiceGroups = data['choiceGroups'] as List?;
    if (choiceGroups != null) {
      _choiceGroups =
          choiceGroups.map((g) {
            final choices =
                (g['choices'] as List?)?.map((c) {
                  return {
                    'name': c['name']?.toString() ?? '',
                    'price': (c['price'] as num?)?.toDouble() ?? 0.0,
                  };
                }).toList() ??
                [];

            return {
              'name': g['name']?.toString() ?? '',
              'isRequired': g['isRequired'] ?? false,
              'maxSelections': g['maxSelections'] ?? 1,
              'choices': choices,
            };
          }).toList();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    _basePriceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  CollectionReference get _menuCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(widget.storeId)
      .collection('menu');

  CollectionReference get _categoriesCollection => FirebaseFirestore.instance
      .collection('stores')
      .doc(widget.storeId)
      .collection('categories');

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.background,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Item' : 'Add Item',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
        actions:
            isEditing
                ? [
                  IconButton(
                    icon: const Icon(Iconsax.trash, color: AppColors.error),
                    onPressed: _confirmDelete,
                  ),
                ]
                : null,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildProductInfoSection(isDark),
                const SizedBox(height: 24),
                _buildPriceAndVariationSection(isDark),
                const SizedBox(height: 24),
                _buildChoiceGroupsSection(isDark),
                const SizedBox(height: 100), // Space for button
              ],
            ),
          ),
          // Save button at bottom
          Positioned(
            left: 20,
            right: 20,
            bottom: 20,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _saveItem,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEditing ? 'Update product' : 'Save product',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black26,
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),
    );
  }

  Widget _buildProductInfoSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Product info',
      children: [
        // Image URL
        _labelText('Image URL (Optional)', isDark),
        const SizedBox(height: 8),
        Row(
          children: [
            if (_imageUrlController.text.isNotEmpty)
              Container(
                width: 50,
                height: 50,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color:
                      isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    _imageUrlController.text,
                    fit: BoxFit.cover,
                    errorBuilder:
                        (_, __, ___) => Icon(
                          Iconsax.image,
                          color:
                              isDark
                                  ? AppColors.textTertiaryDark
                                  : AppColors.textTertiary,
                        ),
                  ),
                ),
              ),
            Expanded(
              child: _inputField(
                _imageUrlController,
                'Enter image URL',
                isDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Product Name
        _labelText('Product Name', isDark),
        const SizedBox(height: 8),
        _inputField(_nameController, 'Enter product name', isDark),
        const SizedBox(height: 16),

        // Stock Quantity
        _labelText('Stock Quantity', isDark),
        const SizedBox(height: 8),
        _inputField(
          _stockController,
          'Enter stock quantity',
          isDark,
          isNumber: true,
        ),
        const SizedBox(height: 16),

        // Description (Optional)
        _labelText('Description (Optional)', isDark),
        const SizedBox(height: 8),
        _inputField(
          _descriptionController,
          'Enter description',
          isDark,
          maxLines: 2,
        ),
        const SizedBox(height: 16),

        // Category dropdown
        _labelText('Category', isDark),
        const SizedBox(height: 8),
        StreamBuilder<QuerySnapshot>(
          stream: _categoriesCollection.orderBy('name').snapshots(),
          builder: (context, snap) {
            final cats = snap.data?.docs ?? [];
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.borderDark : AppColors.border,
                ),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: _selectedCategory,
                  isExpanded: true,
                  hint: Text(
                    'Select category',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
                  ),
                  dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
                  items: [
                    ...cats.map((c) {
                      final data = c.data() as Map<String, dynamic>?;
                      if (data == null) return null;
                      final name = data['name']?.toString() ?? '';
                      return DropdownMenuItem(value: name, child: Text(name));
                    }).whereType<DropdownMenuItem<String>>(),
                  ],
                  onChanged: (val) => setState(() => _selectedCategory = val),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildPriceAndVariationSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Price and Variation',
      subtitle:
          'Add a variation if this item comes in different sizes (e.g. Small, Medium, Large)',
      children: [
        // Base price (shown when no variations)
        if (_variations.isEmpty) ...[
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Text(
                  '₱',
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                  ),
                  child: TextField(
                    controller: _basePriceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Price',
                      hintStyle: TextStyle(
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],

        // Variation list
        ..._variations.asMap().entries.map((entry) {
          final index = entry.key;
          final variation = entry.value;
          return _buildVariationItem(index, variation, isDark);
        }),

        const SizedBox(height: 12),
        // Add Variation button
        GestureDetector(
          onTap: _addVariation,
          child: Row(
            children: [
              const Icon(Icons.add, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Add Variation',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildVariationItem(
    int index,
    Map<String, dynamic> variation,
    bool isDark,
  ) {
    final nameController = TextEditingController(text: variation['name']);
    final priceController = TextEditingController(
      text: variation['price'].toString(),
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _labelText('Variation Name', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      onChanged: (val) => _variations[index]['name'] = val,
                      decoration: _inputDecoration('e.g. Regular', isDark),
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
              const SizedBox(width: 12),
              IconButton(
                icon: const Icon(
                  Iconsax.trash,
                  color: AppColors.error,
                  size: 20,
                ),
                onPressed: () => _removeVariation(index),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color:
                      isDark ? AppColors.backgroundDark : Colors.grey.shade100,
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(12),
                  ),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border,
                  ),
                ),
                child: Text(
                  '₱',
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
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDark ? AppColors.borderDark : AppColors.border,
                    ),
                    borderRadius: const BorderRadius.horizontal(
                      right: Radius.circular(12),
                    ),
                  ),
                  child: TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    onChanged:
                        (val) =>
                            _variations[index]['price'] =
                                double.tryParse(val) ?? 0,
                    decoration: InputDecoration(
                      hintText: 'Price',
                      hintStyle: TextStyle(
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 14,
                      ),
                    ),
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChoiceGroupsSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Choice Groups',
      subtitle:
          'Add choices for this item that customers can choose. You can create a bundle or combo set, add toppings and sides or item customisations.',
      children: [
        // Existing choice groups
        ..._choiceGroups.asMap().entries.map((entry) {
          final index = entry.key;
          final group = entry.value;
          return _buildChoiceGroupItem(index, group, isDark);
        }),

        const SizedBox(height: 12),
        // Create Choice Group button
        GestureDetector(
          onTap: _showCreateChoiceGroupDialog,
          child: Row(
            children: [
              const Icon(Icons.add, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Create Choice Group',
                style: TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildChoiceGroupItem(
    int index,
    Map<String, dynamic> group,
    bool isDark,
  ) {
    final name = group['name'] ?? '';
    final isRequired = group['isRequired'] ?? false;
    final maxSelections = group['maxSelections'] ?? 1;
    final choices = group['choices'] as List? ?? [];

    final choiceNames = choices.map((c) => c['name'].toString()).join(', ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: true,
            onChanged: (val) => _removeChoiceGroup(index),
            activeColor: AppColors.primary,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
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
                    const SizedBox(width: 8),
                    Text(
                      '${isRequired ? "Required" : "Optional"} (Select ${maxSelections == 1 ? "1" : "up to $maxSelections"}) ${choices.length} Choices',
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
                const SizedBox(height: 4),
                Text(
                  choiceNames,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textSecondaryDark
                            : AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              Iconsax.edit,
              size: 18,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
            onPressed: () => _editChoiceGroup(index),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required bool isDark,
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 12,
                color:
                    isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _labelText(String label, bool isDark) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }

  Widget _inputField(
    TextEditingController controller,
    String hint,
    bool isDark, {
    bool isNumber = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      maxLines: maxLines,
      decoration: _inputDecoration(hint, isDark),
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, bool isDark) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
        color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
      ),
      filled: true,
      fillColor: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? AppColors.borderDark : AppColors.border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    );
  }

  // Actions
  void _addVariation() {
    setState(() {
      _variations.add({'name': '', 'price': 0.0});
    });
  }

  void _removeVariation(int index) {
    setState(() {
      _variations.removeAt(index);
    });
  }

  void _removeChoiceGroup(int index) {
    setState(() {
      _choiceGroups.removeAt(index);
    });
  }

  void _editChoiceGroup(int index) {
    _showChoiceGroupDialog(existingIndex: index);
  }

  void _showCreateChoiceGroupDialog() {
    _showChoiceGroupDialog();
  }

  void _showChoiceGroupDialog({int? existingIndex}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isEditing = existingIndex != null;

    final nameController = TextEditingController(
      text: isEditing ? _choiceGroups[existingIndex]['name'] : '',
    );
    bool isRequired =
        isEditing ? _choiceGroups[existingIndex]['isRequired'] : false;
    int maxSelections =
        isEditing ? _choiceGroups[existingIndex]['maxSelections'] : 1;
    List<Map<String, dynamic>> choices =
        isEditing
            ? List<Map<String, dynamic>>.from(
              _choiceGroups[existingIndex]['choices'],
            )
            : [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
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
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isEditing ? 'Edit Choice Group' : 'Create Choice Group',
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

                    // Group Name
                    _labelText('Group Name', isDark),
                    const SizedBox(height: 8),
                    TextField(
                      controller: nameController,
                      decoration: _inputDecoration(
                        'e.g. Sugar Level, Toppings',
                        isDark,
                      ),
                      style: TextStyle(
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Required toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Required',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        Switch(
                          value: isRequired,
                          onChanged:
                              (val) => setSheetState(() => isRequired = val),
                          activeColor: AppColors.primary,
                        ),
                      ],
                    ),

                    // Max selections
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Max Selections',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color:
                                isDark
                                    ? AppColors.textPrimaryDark
                                    : AppColors.textPrimary,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline),
                              onPressed:
                                  maxSelections > 1
                                      ? () =>
                                          setSheetState(() => maxSelections--)
                                      : null,
                            ),
                            Text(
                              '$maxSelections',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color:
                                    isDark
                                        ? AppColors.textPrimaryDark
                                        : AppColors.textPrimary,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline),
                              onPressed:
                                  () => setSheetState(() => maxSelections++),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Choices
                    Text(
                      'Choices',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color:
                            isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...choices.asMap().entries.map((entry) {
                      final idx = entry.key;
                      final choice = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: TextField(
                                controller: TextEditingController(
                                  text: choice['name'],
                                ),
                                onChanged: (val) => choices[idx]['name'] = val,
                                decoration: _inputDecoration(
                                  'Choice name',
                                  isDark,
                                ),
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: TextField(
                                controller: TextEditingController(
                                  text: choice['price'].toString(),
                                ),
                                onChanged:
                                    (val) =>
                                        choices[idx]['price'] =
                                            double.tryParse(val) ?? 0,
                                keyboardType: TextInputType.number,
                                decoration: _inputDecoration('₱ Price', isDark),
                                style: TextStyle(
                                  color:
                                      isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Iconsax.trash,
                                color: AppColors.error,
                                size: 18,
                              ),
                              onPressed:
                                  () => setSheetState(
                                    () => choices.removeAt(idx),
                                  ),
                            ),
                          ],
                        ),
                      );
                    }),

                    GestureDetector(
                      onTap:
                          () => setSheetState(
                            () => choices.add({'name': '', 'price': 0.0}),
                          ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.add,
                            color: AppColors.primary,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          const Text(
                            'Add Choice',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
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
                            onPressed: () {
                              final name = nameController.text.trim();
                              if (name.isEmpty) {
                                return;
                              }

                              final newGroup = {
                                'name': name,
                                'isRequired': isRequired,
                                'maxSelections': maxSelections,
                                'choices':
                                    choices
                                        .where(
                                          (c) =>
                                              c['name'].toString().isNotEmpty,
                                        )
                                        .toList(),
                              };

                              if (isEditing) {
                                setState(
                                  () => _choiceGroups[existingIndex] = newGroup,
                                );
                              } else {
                                setState(() => _choiceGroups.add(newGroup));
                              }

                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Text(
                              isEditing ? 'Update' : 'Create',
                              style: const TextStyle(color: Colors.white),
                            ),
                          ),
                        ),
                      ],
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

  Future<void> _saveItem() async {
    final name = _nameController.text.trim();
    final stockText = _stockController.text.trim();
    final description = _descriptionController.text.trim();
    final basePriceText = _basePriceController.text.trim();

    if (name.isEmpty) {
      await AppModalDialog.warning(
        context: context,
        title: 'Missing Information',
        message: 'Product name is required.',
      );
      return;
    }

    // Validate price/variations
    if (_variations.isEmpty && basePriceText.isEmpty) {
      await AppModalDialog.warning(
        context: context,
        title: 'Missing Information',
        message: 'Price or at least one variation is required.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final imageUrl = _imageUrlController.text.trim();
      final basePrice = double.tryParse(basePriceText) ?? 0;
      final stock = int.tryParse(stockText) ?? 0;

      final data = {
        'name': name,
        'price':
            _variations.isNotEmpty
                ? (_variations.first['price'] as num?)?.toDouble() ?? 0
                : basePrice,
        'stock': stock,
        'description': description,
        'imageUrl': imageUrl,
        'category': _selectedCategory != null ? [_selectedCategory] : [],
        'variations': _variations,
        'choiceGroups': _choiceGroups,
        'isAvailable': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await _menuCollection.doc(widget.itemId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _menuCollection.add(data);
      }

      if (mounted) {
        Navigator.pop(context);
        await AppModalDialog.success(
          context: context,
          title: isEditing ? 'Product Updated' : 'Product Added',
          message:
              isEditing
                  ? 'The product has been updated successfully.'
                  : 'The product has been added to the menu.',
        );
      }
    } catch (e) {
      if (mounted) {
        await AppModalDialog.error(
          context: context,
          title: 'Error',
          message: 'Failed to save product: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _confirmDelete() async {
    final confirmed = await AppModalDialog.confirm(
      context: context,
      title: 'Delete Product',
      message:
          'Are you sure you want to delete this product? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed == true) {
      await _deleteProduct();
    }
  }

  Future<void> _deleteProduct() async {
    setState(() => _isLoading = true);

    try {
      await _menuCollection.doc(widget.itemId).delete();

      if (mounted) {
        Navigator.pop(context);
        await AppModalDialog.success(
          context: context,
          title: 'Product Deleted',
          message: 'The product has been deleted successfully.',
        );
      }
    } catch (e) {
      if (mounted) {
        await AppModalDialog.error(
          context: context,
          title: 'Error',
          message: 'Failed to delete product: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
