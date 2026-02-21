// lib/pages/add_category_page.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';
import '../widgets/app_modal_dialog.dart';

class AddCategoryPage extends StatefulWidget {
  final String storeId;
  final String? categoryId; // null for new, non-null for edit
  final Map<String, dynamic>? existingData;

  const AddCategoryPage({
    super.key,
    required this.storeId,
    this.categoryId,
    this.existingData,
  });

  @override
  State<AddCategoryPage> createState() => _AddCategoryPageState();
}

class _AddCategoryPageState extends State<AddCategoryPage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  bool _isLoading = false;

  bool get isEditing => widget.categoryId != null;

  @override
  void initState() {
    super.initState();
    if (widget.existingData != null) {
      _nameController.text = widget.existingData!['name']?.toString() ?? '';
      _descriptionController.text =
          widget.existingData!['description']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

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
          isEditing ? 'Edit Category' : 'Add Category',
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
                _buildCategoryForm(isDark),
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
              onPressed: _isLoading ? null : _saveCategory,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                isEditing ? 'Update category' : 'Save category',
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

  Widget _buildCategoryForm(bool isDark) {
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
            'Category info',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 20),

          // Category Name
          Text(
            'Category Name',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _nameController,
            decoration: _inputDecoration('Enter category name', isDark),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // Description (Optional)
          Text(
            'Description (Optional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: _inputDecoration('Enter description', isDark),
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ],
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

  Future<void> _confirmDelete() async {
    final confirmed = await AppModalDialog.confirm(
      context: context,
      title: 'Delete Category',
      message:
          'Are you sure you want to delete this category? This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed == true) {
      await _deleteCategory();
    }
  }

  Future<void> _deleteCategory() async {
    setState(() => _isLoading = true);

    try {
      await _categoriesCollection.doc(widget.categoryId).delete();

      if (mounted) {
        // Show success dialog first, then pop the page
        await AppModalDialog.success(
          context: context,
          title: 'Category Deleted',
          message: 'The category has been deleted successfully.',
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        await AppModalDialog.error(
          context: context,
          title: 'Error',
          message: 'Failed to delete category: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    final description = _descriptionController.text.trim();

    if (name.isEmpty) {
      await AppModalDialog.warning(
        context: context,
        title: 'Missing Information',
        message: 'Category name is required.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final data = {
        'name': name,
        'description': description,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      if (isEditing) {
        await _categoriesCollection.doc(widget.categoryId).update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await _categoriesCollection.add(data);
      }

      if (mounted) {
        // Show success dialog first, then pop the page
        await AppModalDialog.success(
          context: context,
          title: isEditing ? 'Category Updated' : 'Category Added',
          message:
              isEditing
                  ? 'The category has been updated successfully.'
                  : 'The category has been added.',
        );
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        await AppModalDialog.error(
          context: context,
          title: 'Error',
          message: 'Failed to save category: $e',
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
