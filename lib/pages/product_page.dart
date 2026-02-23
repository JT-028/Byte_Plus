// lib/pages/product_page.dart

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../theme/app_theme.dart';

class ProductPage extends StatefulWidget {
  final String storeId;
  final String productId;

  const ProductPage({
    super.key,
    required this.storeId,
    required this.productId,
  });

  @override
  State<ProductPage> createState() => _ProductPageState();
}

class _ProductPageState extends State<ProductPage> {
  // Product data - loaded once
  Map<String, dynamic>? _productData;
  bool _isLoading = true;

  // Store info
  String _storeName = '';
  String _storeLogo = '';

  // Selected variation (e.g., Small, Large)
  int? _selectedVariationIndex;
  double _selectedVariationPrice = 0;

  // Selected choices per group: groupIndex -> Set of choice indices
  final Map<int, Set<int>> _selectedChoices = {};

  // Total add-on price from choice groups
  double _choicesTotal = 0;

  int _quantity = 1;
  bool _collapsed = false;

  final TextEditingController _noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadProduct();
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProduct() async {
    // Fetch store info for storeName and storeLogo
    final storeSnap =
        await FirebaseFirestore.instance
            .collection("stores")
            .doc(widget.storeId)
            .get();

    if (storeSnap.exists) {
      final storeData = storeSnap.data() as Map<String, dynamic>;
      _storeName = (storeData['name'] ?? '').toString();
      _storeLogo = (storeData['logoUrl'] ?? '').toString();
    }

    final snap =
        await FirebaseFirestore.instance
            .collection("stores")
            .doc(widget.storeId)
            .collection("menu")
            .doc(widget.productId)
            .get();

    if (snap.exists && mounted) {
      final data = snap.data() as Map<String, dynamic>;

      // Initialize choice groups selection
      final choiceGroups = data['choiceGroups'] as List? ?? [];
      for (int i = 0; i < choiceGroups.length; i++) {
        _selectedChoices[i] = {};
      }

      setState(() {
        _productData = data;
        _isLoading = false;
      });
    } else if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Get base price (when no variations)
  double get _basePrice {
    if (_productData == null) return 0;
    return ((_productData!['price'] as num?) ?? 0).toDouble();
  }

  // Get the applied price (variation price or base price)
  double get _appliedPrice {
    if (_selectedVariationPrice > 0) return _selectedVariationPrice;
    return _basePrice;
  }

  // Calculate total price
  double get _totalPrice {
    return (_appliedPrice + _choicesTotal) * _quantity;
  }

  // Check if all required choice groups are completed
  bool _isChoiceGroupComplete(int groupIndex) {
    final groups = _productData?['choiceGroups'] as List? ?? [];
    if (groupIndex >= groups.length) return true;

    final group = groups[groupIndex] as Map<String, dynamic>;
    final isRequired = group['isRequired'] ?? false;
    final maxSelections = (group['maxSelections'] as num?)?.toInt() ?? 1;

    if (!isRequired) return true;

    final selected = _selectedChoices[groupIndex]?.length ?? 0;
    return selected >= 1 && selected <= maxSelections;
  }

  // Check if all required groups are satisfied
  bool get _canAddToCart {
    final variations = _productData?['variations'] as List? ?? [];
    final choiceGroups = _productData?['choiceGroups'] as List? ?? [];

    // If there are variations, one must be selected
    if (variations.isNotEmpty && _selectedVariationIndex == null) {
      return false;
    }

    // Check all required choice groups
    for (int i = 0; i < choiceGroups.length; i++) {
      final group = choiceGroups[i] as Map<String, dynamic>;
      if (group['isRequired'] == true) {
        if (!_isChoiceGroupComplete(i)) return false;
      }
    }

    return true;
  }

  // Update choices total when selection changes
  void _updateChoicesTotal() {
    double total = 0;
    final choiceGroups = _productData?['choiceGroups'] as List? ?? [];

    for (int groupIndex = 0; groupIndex < choiceGroups.length; groupIndex++) {
      final group = choiceGroups[groupIndex] as Map<String, dynamic>;
      final choices = group['choices'] as List? ?? [];
      final selectedIndices = _selectedChoices[groupIndex] ?? {};

      for (int choiceIndex in selectedIndices) {
        if (choiceIndex < choices.length) {
          final choice = choices[choiceIndex] as Map<String, dynamic>;
          total += ((choice['price'] as num?) ?? 0).toDouble();
        }
      }
    }

    setState(() => _choicesTotal = total);
  }

  // Toggle a choice selection
  void _toggleChoice(int groupIndex, int choiceIndex) {
    final groups = _productData?['choiceGroups'] as List? ?? [];
    if (groupIndex >= groups.length) return;

    final group = groups[groupIndex] as Map<String, dynamic>;
    final maxSelections = (group['maxSelections'] as num?)?.toInt() ?? 1;

    setState(() {
      final currentSet = _selectedChoices[groupIndex] ?? {};

      if (currentSet.contains(choiceIndex)) {
        // Deselect
        currentSet.remove(choiceIndex);
      } else {
        // Select
        if (maxSelections == 1) {
          // Single selection - replace
          currentSet.clear();
          currentSet.add(choiceIndex);
        } else {
          // Multi-selection - check limit
          if (currentSet.length < maxSelections) {
            currentSet.add(choiceIndex);
          }
        }
      }

      _selectedChoices[groupIndex] = currentSet;
    });

    _updateChoicesTotal();
  }

  Future<void> _addToCart() async {
    if (_productData == null || !_canAddToCart) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cartRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cartItems");

    // Build selected choices list
    final List<Map<String, dynamic>> selectedChoicesList = [];
    final choiceGroups = _productData!['choiceGroups'] as List? ?? [];

    for (int groupIndex = 0; groupIndex < choiceGroups.length; groupIndex++) {
      final group = choiceGroups[groupIndex] as Map<String, dynamic>;
      final choices = group['choices'] as List? ?? [];
      final selectedIndices = _selectedChoices[groupIndex] ?? {};

      for (int choiceIndex in selectedIndices) {
        if (choiceIndex < choices.length) {
          final choice = choices[choiceIndex] as Map<String, dynamic>;
          selectedChoicesList.add({
            'groupName': group['name'],
            'name': choice['name'],
            'price': choice['price'],
          });
        }
      }
    }

    // Get variation info
    String variationName = '';
    final variations = _productData!['variations'] as List? ?? [];
    if (_selectedVariationIndex != null &&
        _selectedVariationIndex! < variations.length) {
      variationName =
          (variations[_selectedVariationIndex!] as Map)['name']?.toString() ??
          '';
    }

    // Check for existing matching cart item
    final match =
        await cartRef
            .where("storeId", isEqualTo: widget.storeId)
            .where("productId", isEqualTo: widget.productId)
            .where("variationName", isEqualTo: variationName)
            .get();

    bool merged = false;

    for (var doc in match.docs) {
      final data = doc.data();
      final existingChoices = List<Map<String, dynamic>>.from(
        data["selectedChoices"] ?? [],
      );

      // Compare choices
      if (_sameChoices(existingChoices, selectedChoicesList)) {
        int newQty = ((data["quantity"] as num?) ?? 1).toInt() + _quantity;
        await doc.reference.update({
          "quantity": newQty,
          "lineTotal": newQty * (_appliedPrice + _choicesTotal),
        });
        merged = true;
        break;
      }
    }

    if (!merged) {
      await cartRef.add({
        "storeId": widget.storeId,
        "storeName": _storeName,
        "storeLogo": _storeLogo,
        "productId": widget.productId,
        "productName": _productData!["name"],
        "imageUrl": _productData!["imageUrl"],
        "basePrice": _appliedPrice,
        "variationName": variationName,
        "variationPrice": _selectedVariationPrice,
        "selectedChoices": selectedChoicesList,
        "choicesTotal": _choicesTotal,
        "note": _noteCtrl.text.trim(),
        "quantity": _quantity,
        "lineTotal": _totalPrice,
        "createdAt": DateTime.now(),
      });
    }

    if (mounted) Navigator.pop(context);
  }

  bool _sameChoices(
    List<Map<String, dynamic>> a,
    List<Map<String, dynamic>> b,
  ) {
    if (a.length != b.length) return false;
    final aNames =
        a.map((e) => '${e['groupName']}-${e['name']}').toList()..sort();
    final bNames =
        b.map((e) => '${e['groupName']}-${e['name']}').toList()..sort();
    return aNames.toString() == bNames.toString();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_isLoading) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      );
    }

    if (_productData == null) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: isDark ? AppColors.backgroundDark : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Center(
          child: Text(
            'Product not found',
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
          ),
        ),
      );
    }

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? AppColors.borderDark : Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Expanded(
            child: CustomScrollView(
              slivers: [
                _buildHeader(isDark),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: _buildBody(isDark),
                  ),
                ),
              ],
            ),
          ),
          _buildBottomBar(isDark),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER with product image
  // ============================================================
  SliverAppBar _buildHeader(bool isDark) {
    final imageUrl = _productData?['imageUrl']?.toString() ?? '';

    return SliverAppBar(
      pinned: true,
      expandedHeight: 260,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      leading: GestureDetector(
        onTap: () => Navigator.pop(context),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.surfaceVariantDark : Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Iconsax.close_circle,
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
              size: 24,
            ),
          ),
        ),
      ),
      title: AnimatedOpacity(
        opacity: _collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          _productData?['name'] ?? '',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          bool collapse = constraints.biggest.height < 150;
          if (collapse != _collapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => _collapsed = collapse);
            });
          }

          return FlexibleSpaceBar(
            background: Center(
              child:
                  imageUrl.isNotEmpty
                      ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        height: 200,
                        fit: BoxFit.contain,
                        placeholder:
                            (_, __) => Container(
                              height: 200,
                              width: 200,
                              decoration: BoxDecoration(
                                color:
                                    isDark
                                        ? AppColors.surfaceVariantDark
                                        : Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(
                                Iconsax.image,
                                size: 48,
                                color:
                                    isDark
                                        ? AppColors.textTertiaryDark
                                        : AppColors.textTertiary,
                              ),
                            ),
                        errorWidget:
                            (_, __, ___) => Icon(
                              Iconsax.image,
                              size: 64,
                              color:
                                  isDark
                                      ? AppColors.textTertiaryDark
                                      : AppColors.textTertiary,
                            ),
                      )
                      : Icon(
                        Iconsax.image,
                        size: 64,
                        color:
                            isDark
                                ? AppColors.textTertiaryDark
                                : AppColors.textTertiary,
                      ),
            ),
          );
        },
      ),
    );
  }

  // ============================================================
  // BODY - Product info, variations, price, choice groups
  // ============================================================
  Widget _buildBody(bool isDark) {
    final variations = _productData?['variations'] as List? ?? [];
    final choiceGroups = _productData?['choiceGroups'] as List? ?? [];
    final description = _productData?['description']?.toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ---- PRODUCT INFO ----
        Text(
          _productData?['name'] ?? '',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),

        // Description
        if (description != null && description.isNotEmpty) ...[
          Text(
            description,
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
        ],

        // ---- PRICE DISPLAY ----
        Text(
          '₱${_appliedPrice.toStringAsFixed(0)}',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),

        const SizedBox(height: 24),

        // ---- VARIATIONS (Group Variation) ----
        if (variations.isNotEmpty) ...[
          _buildSectionTitle(
            'Size / Variation',
            required: true,
            isCompleted: _selectedVariationIndex != null,
            isDark: isDark,
          ),
          const SizedBox(height: 10),
          _buildContainer(
            Column(
              children: List.generate(variations.length, (index) {
                final v = variations[index] as Map<String, dynamic>;
                final name = v['name']?.toString() ?? '';
                final price = ((v['price'] as num?) ?? 0).toDouble();
                // ignore: unused_local_variable - available for styling selected variation
                final isSelected = _selectedVariationIndex == index;

                return RadioListTile<int>(
                  title: Text(
                    '$name  (₱${price.toStringAsFixed(0)})',
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  value: index,
                  groupValue: _selectedVariationIndex,
                  activeColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  onChanged: (val) {
                    setState(() {
                      _selectedVariationIndex = val;
                      _selectedVariationPrice = price;
                    });
                  },
                );
              }),
            ),
            isDark,
          ),
          const SizedBox(height: 24),
        ],

        // ---- CHOICE GROUPS ----
        ...choiceGroups.asMap().entries.map((entry) {
          final groupIndex = entry.key;
          final group = entry.value as Map<String, dynamic>;
          return _buildChoiceGroup(groupIndex, group, isDark);
        }),

        // ---- NOTE TO VENDOR ----
        _buildSectionTitle('Note to Vendor', isDark: isDark),
        const SizedBox(height: 10),
        _buildContainer(
          TextField(
            controller: _noteCtrl,
            maxLines: 2,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: 'Add your request (optional)',
              hintStyle: TextStyle(
                color:
                    isDark
                        ? AppColors.textTertiaryDark
                        : AppColors.textTertiary,
              ),
            ),
          ),
          isDark,
        ),

        const SizedBox(height: 120),
      ],
    );
  }

  // ============================================================
  // CHOICE GROUP BUILDER
  // ============================================================
  Widget _buildChoiceGroup(
    int groupIndex,
    Map<String, dynamic> group,
    bool isDark,
  ) {
    final name = group['name']?.toString() ?? 'Options';
    final isRequired = group['isRequired'] ?? false;
    final maxSelections = (group['maxSelections'] as num?)?.toInt() ?? 1;
    final choices = group['choices'] as List? ?? [];
    final selectedSet = _selectedChoices[groupIndex] ?? {};
    final isComplete = _isChoiceGroupComplete(groupIndex);

    String subtitle = '';
    if (maxSelections == 1) {
      subtitle = 'Select 1';
    } else {
      subtitle = 'Select up to $maxSelections';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle(
          name,
          required: isRequired,
          isCompleted: isComplete,
          subtitle: subtitle,
          isDark: isDark,
        ),
        const SizedBox(height: 10),
        _buildContainer(
          Column(
            children: List.generate(choices.length, (choiceIndex) {
              final choice = choices[choiceIndex] as Map<String, dynamic>;
              final choiceName = choice['name']?.toString() ?? '';
              final choicePrice = ((choice['price'] as num?) ?? 0).toDouble();
              final isSelected = selectedSet.contains(choiceIndex);

              if (maxSelections == 1) {
                // Single select - use radio
                return RadioListTile<int>(
                  title: Text(
                    choicePrice > 0
                        ? '$choiceName  (+₱${choicePrice.toStringAsFixed(0)})'
                        : choiceName,
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  value: choiceIndex,
                  groupValue: selectedSet.isNotEmpty ? selectedSet.first : null,
                  activeColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  onChanged: (_) => _toggleChoice(groupIndex, choiceIndex),
                );
              } else {
                // Multi-select - use checkbox
                return CheckboxListTile(
                  title: Text(
                    choicePrice > 0
                        ? '$choiceName  (+₱${choicePrice.toStringAsFixed(0)})'
                        : choiceName,
                    style: TextStyle(
                      color:
                          isDark
                              ? AppColors.textPrimaryDark
                              : AppColors.textPrimary,
                    ),
                  ),
                  value: isSelected,
                  activeColor:
                      isDark ? AppColors.primaryLight : AppColors.primary,
                  checkColor: Colors.white,
                  onChanged: (_) => _toggleChoice(groupIndex, choiceIndex),
                );
              }
            }),
          ),
          isDark,
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  // ============================================================
  // SECTION TITLE
  // ============================================================
  Widget _buildSectionTitle(
    String text, {
    bool required = false,
    bool isCompleted = false,
    String? subtitle,
    required bool isDark,
  }) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color:
                      isDark
                          ? AppColors.textPrimaryDark
                          : AppColors.textPrimary,
                ),
              ),
              if (subtitle != null)
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark
                            ? AppColors.textTertiaryDark
                            : AppColors.textTertiary,
                  ),
                ),
            ],
          ),
        ),
        if (required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isCompleted
                      ? (isDark
                          ? AppColors.surfaceVariantDark
                          : Colors.grey.shade300)
                      : (isDark
                          ? AppColors.primary.withValues(alpha: 0.2)
                          : Colors.blue.shade50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              isCompleted ? 'Completed' : 'Required',
              style: TextStyle(
                color:
                    isCompleted
                        ? (isDark
                            ? AppColors.textSecondaryDark
                            : Colors.black54)
                        : (isDark ? AppColors.primaryLight : AppColors.primary),
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  isDark ? AppColors.surfaceVariantDark : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'Optional',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildContainer(Widget child, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ============================================================
  // BOTTOM BAR
  // ============================================================
  Widget _buildBottomBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.black12,
            blurRadius: 5,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Quantity selector
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDark ? AppColors.borderDark : Colors.grey.shade400,
              ),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: Icon(
                    Iconsax.minus,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  onPressed:
                      _quantity > 1 ? () => setState(() => _quantity--) : null,
                ),
                Text(
                  '$_quantity',
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
                  icon: Icon(
                    Iconsax.add,
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                  onPressed: () => setState(() => _quantity++),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Add to cart button
          Expanded(
            child: ElevatedButton(
              onPressed: _canAddToCart ? _addToCart : null,
              style: ElevatedButton.styleFrom(
                backgroundColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                disabledBackgroundColor:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : Colors.grey.shade300,
                foregroundColor: Colors.white,
                disabledForegroundColor:
                    isDark ? AppColors.textTertiaryDark : Colors.grey.shade500,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Add to cart • ₱${_totalPrice.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
