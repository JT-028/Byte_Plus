// lib/pages/admin/edit_store_page.dart
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:image_picker/image_picker.dart';

import '../../theme/app_theme.dart';
import '../../widgets/app_modal_dialog.dart';
import '../../services/cloudinary_service.dart';

class EditStorePage extends StatefulWidget {
  final String? storeId; // null for new store, non-null for edit
  final Map<String, dynamic>? existingData;

  const EditStorePage({super.key, this.storeId, this.existingData});

  @override
  State<EditStorePage> createState() => _EditStorePageState();
}

class _EditStorePageState extends State<EditStorePage> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String? _logoUrl;
  File? _selectedLogoFile;
  bool _isUploadingLogo = false;

  String? _bannerUrl;
  File? _selectedBannerFile;
  bool _isUploadingBanner = false;

  bool _isActive = true;
  bool _isLoading = false;

  // Category
  static const List<String> _categoryOptions = [
    'Drinks',
    'Burger',
    'Coffee',
    'Chicken',
    'Snacks',
    'Desserts',
  ];
  final List<String> _selectedCategories = [];

  // Operating Hours
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  bool get isEditing => widget.storeId != null;

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
    _descriptionController.text = data['description']?.toString() ?? '';
    _logoUrl = data['logoUrl']?.toString();
    _bannerUrl = data['bannerUrl']?.toString();
    _isActive = data['isActive'] ?? true;

    // Load categories (supports multiple)
    final cats = data['category'] as List<dynamic>?;
    if (cats != null) {
      _selectedCategories.addAll(cats.map((e) => e.toString()));
    }

    // Load operating hours
    final openStr = data['openingTime']?.toString();
    final closeStr = data['closingTime']?.toString();
    if (openStr != null && openStr.contains(':')) {
      final parts = openStr.split(':');
      _openingTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
    if (closeStr != null && closeStr.contains(':')) {
      final parts = closeStr.split(':');
      _closingTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
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
            Icons.arrow_back,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEditing ? 'Edit Store' : 'Add Store',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          if (isEditing)
            IconButton(
              icon: const Icon(Iconsax.trash, color: AppColors.error),
              onPressed: _confirmDelete,
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildInfoSection(isDark),
                const SizedBox(height: 20),
                _buildImagesSection(isDark),
                const SizedBox(height: 20),
                _buildOperatingHoursSection(isDark),
                const SizedBox(height: 20),
                _buildStatusSection(isDark),
                const SizedBox(height: 32),
                _buildSaveButton(isDark),
                const SizedBox(height: 40),
              ],
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

  Widget _buildInfoSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Store Information',
      children: [
        _labelText('Store Name *', isDark),
        const SizedBox(height: 8),
        _inputField(_nameController, 'Enter store name', isDark),
        const SizedBox(height: 16),
        _labelText('Description', isDark),
        const SizedBox(height: 8),
        _inputField(
          _descriptionController,
          'Enter description',
          isDark,
          maxLines: 3,
        ),
        const SizedBox(height: 16),
        _labelText('Categories', isDark),
        const SizedBox(height: 4),
        Text(
          'Select all that apply',
          style: TextStyle(
            fontSize: 12,
            color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children:
              _categoryOptions.map((cat) {
                final isSelected = _selectedCategories.contains(cat);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _selectedCategories.remove(cat);
                      } else {
                        _selectedCategories.add(cat);
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? AppColors.backgroundDark
                                  : Colors.grey.shade50),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? AppColors.borderDark
                                    : AppColors.border),
                        width: isSelected ? 1.5 : 1,
                      ),
                    ),
                    child: Text(
                      cat,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w400,
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
      ],
    );
  }

  String _formatTimeOfDay(TimeOfDay t) {
    final hour = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final min = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$min $period';
  }

  Future<void> _pickTime({required bool isOpening}) async {
    final initial =
        isOpening
            ? (_openingTime ?? const TimeOfDay(hour: 8, minute: 0))
            : (_closingTime ?? const TimeOfDay(hour: 17, minute: 0));
    final picked = await showTimePicker(context: context, initialTime: initial);
    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  Widget _buildOperatingHoursSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Operating Hours',
      children: [
        Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelText('Opening Time', isDark),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(isOpening: true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.backgroundDark
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _openingTime != null
                                ? _formatTimeOfDay(_openingTime!)
                                : 'Set time',
                            style: TextStyle(
                              color:
                                  _openingTime != null
                                      ? (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary)
                                      : (isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _labelText('Closing Time', isDark),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () => _pickTime(isOpening: false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color:
                            isDark
                                ? AppColors.backgroundDark
                                : Colors.grey.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color:
                              isDark ? AppColors.borderDark : AppColors.border,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Iconsax.clock,
                            size: 18,
                            color: AppColors.primary,
                          ),
                          const SizedBox(width: 10),
                          Text(
                            _closingTime != null
                                ? _formatTimeOfDay(_closingTime!)
                                : 'Set time',
                            style: TextStyle(
                              color:
                                  _closingTime != null
                                      ? (isDark
                                          ? AppColors.textPrimaryDark
                                          : AppColors.textPrimary)
                                      : (isDark
                                          ? AppColors.textTertiaryDark
                                          : AppColors.textTertiary),
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
      ],
    );
  }

  Widget _buildImagesSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Store Images',
      children: [
        // Logo
        _labelText('Store Logo', isDark),
        const SizedBox(height: 8),
        _buildImagePicker(
          isDark: isDark,
          imageUrl: _logoUrl,
          selectedFile: _selectedLogoFile,
          isUploading: _isUploadingLogo,
          height: 100,
          isSquare: true,
          onTap: () => _showImagePickerOptions(isLogo: true),
          onRemove: () {
            setState(() {
              _selectedLogoFile = null;
              _logoUrl = null;
            });
          },
        ),
        const SizedBox(height: 20),
        // Banner
        _labelText('Store Banner', isDark),
        const SizedBox(height: 8),
        _buildImagePicker(
          isDark: isDark,
          imageUrl: _bannerUrl,
          selectedFile: _selectedBannerFile,
          isUploading: _isUploadingBanner,
          height: 150,
          isSquare: false,
          onTap: () => _showImagePickerOptions(isLogo: false),
          onRemove: () {
            setState(() {
              _selectedBannerFile = null;
              _bannerUrl = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatusSection(bool isDark) {
    return _sectionCard(
      isDark: isDark,
      title: 'Store Status',
      children: [
        SwitchListTile(
          value: _isActive,
          onChanged: (val) => setState(() => _isActive = val),
          title: Text(
            'Store Active',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
          subtitle: Text(
            _isActive
                ? 'Store is visible to customers'
                : 'Store is hidden from customers',
            style: TextStyle(
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
          activeThumbColor: AppColors.primary,
          contentPadding: EdgeInsets.zero,
        ),
      ],
    );
  }

  Widget _buildSaveButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _saveStore,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: Text(
          isEditing ? 'Save Changes' : 'Create Store',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildImagePicker({
    required bool isDark,
    required String? imageUrl,
    required File? selectedFile,
    required bool isUploading,
    required double height,
    required bool isSquare,
    required VoidCallback onTap,
    required VoidCallback onRemove,
  }) {
    final hasImage =
        selectedFile != null || (imageUrl != null && imageUrl.isNotEmpty);

    return GestureDetector(
      onTap: isUploading ? null : onTap,
      child: Container(
        height: height,
        width: isSquare ? height : double.infinity,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.borderDark : AppColors.border,
          ),
        ),
        child:
            isUploading
                ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 8),
                      Text('Uploading...'),
                    ],
                  ),
                )
                : hasImage
                ? Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child:
                          selectedFile != null
                              ? Image.file(
                                selectedFile,
                                width: double.infinity,
                                height: height,
                                fit: BoxFit.cover,
                              )
                              : Image.network(
                                imageUrl!,
                                width: double.infinity,
                                height: height,
                                fit: BoxFit.cover,
                                errorBuilder:
                                    (_, __, ___) => _emptyImagePlaceholder(
                                      isDark,
                                      isSquare,
                                    ),
                              ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: GestureDetector(
                        onTap: onRemove,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(
                            Icons.close,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        decoration: const BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(12),
                            bottomRight: Radius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Tap to change',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  ],
                )
                : _emptyImagePlaceholder(isDark, isSquare),
      ),
    );
  }

  Widget _emptyImagePlaceholder(bool isDark, bool isSquare) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border,
          width: 2,
          style: BorderStyle.solid,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSquare ? Iconsax.gallery_add : Iconsax.image,
              size: 32,
              color:
                  isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to add image',
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

  void _showImagePickerOptions({required bool isLogo}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Iconsax.camera, color: AppColors.primary),
                  ),
                  title: Text(
                    'Take Photo',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.camera, isLogo: isLogo);
                  },
                ),
                ListTile(
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Iconsax.gallery,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(
                    'Choose from Gallery',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _pickImage(ImageSource.gallery, isLogo: isLogo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _pickImage(ImageSource source, {required bool isLogo}) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(
        source: source,
        maxWidth: isLogo ? 512 : 1920,
        maxHeight: isLogo ? 512 : 1080,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          if (isLogo) {
            _selectedLogoFile = File(pickedFile.path);
          } else {
            _selectedBannerFile = File(pickedFile.path);
          }
        });
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to pick image: $e')));
      }
    }
  }

  Future<String?> _uploadImageIfNeeded(
    File? file,
    String? existingUrl,
    bool isLogo,
  ) async {
    if (file == null) {
      return existingUrl;
    }

    setState(() {
      if (isLogo) {
        _isUploadingLogo = true;
      } else {
        _isUploadingBanner = true;
      }
    });

    try {
      debugPrint(
        '[EditStorePage] Uploading ${isLogo ? "logo" : "banner"} to Cloudinary...',
      );
      final url = await CloudinaryService.uploadImage(file);

      if (url != null) {
        debugPrint('[EditStorePage] Upload successful: $url');
        // Update state with the uploaded URL and clear the selected file
        if (mounted) {
          setState(() {
            if (isLogo) {
              _logoUrl = url;
              _selectedLogoFile = null;
            } else {
              _bannerUrl = url;
              _selectedBannerFile = null;
            }
          });
        }
        return url;
      } else {
        debugPrint('[EditStorePage] Upload failed, keeping existing URL');
        // Show error to user
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Failed to upload ${isLogo ? "logo" : "banner"}. Please try again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
        return existingUrl;
      }
    } catch (e) {
      debugPrint('[EditStorePage] Upload error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return existingUrl;
    } finally {
      if (mounted) {
        setState(() {
          if (isLogo) {
            _isUploadingLogo = false;
          } else {
            _isUploadingBanner = false;
          }
        });
      }
    }
  }

  Future<void> _saveStore() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      await AppModalDialog.warning(
        context: context,
        title: 'Missing Information',
        message: 'Store name is required.',
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Upload images if new ones were selected
      final logoUrl = await _uploadImageIfNeeded(
        _selectedLogoFile,
        _logoUrl,
        true,
      );
      final bannerUrl = await _uploadImageIfNeeded(
        _selectedBannerFile,
        _bannerUrl,
        false,
      );

      final data = <String, dynamic>{
        'name': name,
        'description': _descriptionController.text.trim(),
        'logoUrl': logoUrl ?? '',
        'bannerUrl': bannerUrl ?? '',
        'isActive': _isActive,
        'updatedAt': FieldValue.serverTimestamp(),
        'category': _selectedCategories,
        'openingTime':
            _openingTime != null
                ? '${_openingTime!.hour.toString().padLeft(2, '0')}:${_openingTime!.minute.toString().padLeft(2, '0')}'
                : null,
        'closingTime':
            _closingTime != null
                ? '${_closingTime!.hour.toString().padLeft(2, '0')}:${_closingTime!.minute.toString().padLeft(2, '0')}'
                : null,
      };

      if (isEditing) {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .update(data);
      } else {
        data['createdAt'] = FieldValue.serverTimestamp();
        await FirebaseFirestore.instance.collection('stores').add(data);
      }

      if (mounted) {
        // Show success dialog first, then pop the page
        await AppModalDialog.success(
          context: context,
          title: isEditing ? 'Store Updated' : 'Store Created',
          message:
              isEditing
                  ? 'The store has been updated successfully.'
                  : 'The store has been created successfully.',
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
          message: 'Failed to save store: $e',
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
      title: 'Delete Store',
      message:
          'Are you sure you want to delete this store? This will also delete all menu items and orders. This cannot be undone.',
      confirmLabel: 'Delete',
      isDanger: true,
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await FirebaseFirestore.instance
            .collection('stores')
            .doc(widget.storeId)
            .delete();

        if (mounted) {
          // Show success dialog first, then pop the page
          await AppModalDialog.success(
            context: context,
            title: 'Store Deleted',
            message: 'The store has been deleted.',
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
            message: 'Failed to delete store: $e',
          );
        }
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }

  Widget _sectionCard({
    required bool isDark,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
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
          Text(
            title,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
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
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiary,
        ),
        filled: true,
        fillColor: isDark ? AppColors.backgroundDark : Colors.grey.shade50,
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
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      style: TextStyle(
        color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
      ),
    );
  }
}
