// lib/pages/product_page.dart

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
  DocumentSnapshot? doc;

  // Size price now represents FULL PRICE (100 / 110)
  int selectedSizePrice = 0;
  String? selectedSize;

  // Required fields
  String? selectedSugar;
  String? selectedIce;

  // Optional
  final Set<Map<String, dynamic>> selectedToppings = {};
  int toppingsTotal = 0;

  int quantity = 1;
  int basePrice = 0; // Regular full price
  bool collapsed = false;

  final TextEditingController noteCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    loadProduct();
  }

  Future<void> loadProduct() async {
    final snap =
        await FirebaseFirestore.instance
            .collection("stores")
            .doc(widget.storeId)
            .collection("menu")
            .doc(widget.productId)
            .get();

    if (snap.exists) {
      setState(() {
        doc = snap;
        basePrice = int.parse(snap["price"].toString());
      });
    }
  }

  // ------------------------------------------------------------
  // REQUIRED LOGIC
  // ------------------------------------------------------------
  bool isCompleted(String section) {
    switch (section) {
      case "size":
        return selectedSize != null;
      case "sugar":
        return selectedSugar != null;
      case "ice":
        return selectedIce != null;
      default:
        return false;
    }
  }

  // ------------------------------------------------------------
  // TOTAL PRICE LOGIC (Option B — FULL PRICE)
  // ------------------------------------------------------------
  int get appliedSizePrice =>
      selectedSizePrice > 0 ? selectedSizePrice : basePrice;

  int computeTotal() {
    return (appliedSizePrice + toppingsTotal) * quantity;
  }

  bool sameToppings(List a, List b) {
    if (a.length != b.length) return false;
    final A = a.map((e) => e.toString()).toList()..sort();
    final B = b.map((e) => e.toString()).toList()..sort();
    return A.toString() == B.toString();
  }

  Future<void> addToCart() async {
    if (doc == null) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;
    final cartRef = FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("cartItems");

    final toppingsList = selectedToppings.toList();

    final match =
        await cartRef
            .where("storeId", isEqualTo: widget.storeId)
            .where("productId", isEqualTo: widget.productId)
            .where("sizeName", isEqualTo: selectedSize ?? "")
            .where("sugarLevel", isEqualTo: selectedSugar ?? "")
            .where("iceLevel", isEqualTo: selectedIce ?? "")
            .get();

    bool merged = false;

    for (var x in match.docs) {
      final data = x.data();
      final existingT = List.from(data["toppings"] ?? []);

      if (sameToppings(existingT, toppingsList)) {
        int newQty = (data["quantity"] ?? 1) + quantity;

        await x.reference.update({
          "quantity": newQty,
          "lineTotal": newQty * (appliedSizePrice + toppingsTotal),
        });

        merged = true;
        break;
      }
    }

    if (!merged) {
      await cartRef.add({
        "storeId": widget.storeId,
        "productId": widget.productId,
        "productName": doc!["name"],
        "imageUrl": doc!["imageUrl"],
        "basePrice": appliedSizePrice,
        "sizeName": selectedSize ?? "",
        "sizePrice": appliedSizePrice,
        "sugarLevel": selectedSugar ?? "",
        "iceLevel": selectedIce ?? "",
        "toppings": toppingsList,
        "toppingsTotal": toppingsTotal,
        "note": noteCtrl.text.trim(),
        "quantity": quantity,
        "lineTotal": computeTotal(),
        "createdAt": DateTime.now(),
      });
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    if (doc == null) {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      return Scaffold(
        backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
        body: Center(
          child: CircularProgressIndicator(
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),
      );
    }

    final data = doc!.data() as Map<String, dynamic>;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  _sliverHeader(data, isDark),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: _buildBody(data, isDark),
                    ),
                  ),
                ],
              ),
            ),
            _bottomBar(isDark),
          ],
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // HEADER
  // ------------------------------------------------------------
  SliverAppBar _sliverHeader(Map data, bool isDark) {
    return SliverAppBar(
      pinned: true,
      expandedHeight: 280,
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      elevation: 0,
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
                  color: Colors.black.withOpacity(0.1),
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
        opacity: collapsed ? 1 : 0,
        duration: const Duration(milliseconds: 200),
        child: Text(
          data["name"] ?? '',
          style: TextStyle(
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, c) {
          bool collapse = c.biggest.height < 150;

          if (collapse != collapsed) {
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) setState(() => collapsed = collapse);
            });
          }

          return FlexibleSpaceBar(
            background: Center(
              child: Image.network(
                data["imageUrl"] ?? '',
                height: 220,
                fit: BoxFit.contain,
                errorBuilder:
                    (_, __, ___) => Icon(
                      Iconsax.image,
                      size: 64,
                      color:
                          isDark
                              ? AppColors.textTertiaryDark
                              : AppColors.textTertiary,
                    ),
              ),
            ),
          );
        },
      ),
    );
  }

  // ------------------------------------------------------------
  // BODY
  // ------------------------------------------------------------
  Widget _buildBody(Map data, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          data["name"] ?? '',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),

        // PRICE DISPLAY (FIXED)
        Text(
          "₱$appliedSizePrice",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: isDark ? AppColors.primaryLight : AppColors.primary,
          ),
        ),

        const SizedBox(height: 20),

        // DESCRIPTION
        if (data["description"] != null)
          Text(
            data["description"],
            style: TextStyle(
              fontSize: 14,
              color:
                  isDark
                      ? AppColors.textSecondaryDark
                      : AppColors.textSecondary,
            ),
          ),

        const SizedBox(height: 25),

        // SIZE REQUIRED
        _sectionTitle("Size", required: true, keyName: "size", isDark: isDark),
        _container(
          Column(
            children: List.generate(data["size"]?.length ?? 0, (i) {
              final s = data["size"][i];
              return RadioListTile(
                title: Text(
                  "${s["name"]}  (₱${s["price"]})",
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                value: s["name"],
                groupValue: selectedSize,
                activeColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                onChanged: (v) {
                  setState(() {
                    selectedSize = v.toString();
                    selectedSizePrice = int.parse(s["price"].toString());
                  });
                },
              );
            }),
          ),
          isDark,
        ),

        const SizedBox(height: 25),

        // SUGAR REQUIRED
        _sectionTitle(
          "Sugar Level",
          required: true,
          keyName: "sugar",
          isDark: isDark,
        ),
        _container(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(data["sugarOptions"]?.length ?? 0, (i) {
              final opt = data["sugarOptions"][i];
              final isSelected = selectedSugar == opt;
              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                  ),
                ),
                selected: isSelected,
                selectedColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                backgroundColor:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : Colors.grey.shade200,
                onSelected: (_) => setState(() => selectedSugar = opt),
              );
            }),
          ),
          isDark,
        ),

        const SizedBox(height: 25),

        // ICE REQUIRED
        _sectionTitle(
          "Ice Level",
          required: true,
          keyName: "ice",
          isDark: isDark,
        ),
        _container(
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: List.generate(data["iceOptions"]?.length ?? 0, (i) {
              final opt = data["iceOptions"][i];
              final isSelected = selectedIce == opt;
              return ChoiceChip(
                label: Text(
                  opt,
                  style: TextStyle(
                    color:
                        isSelected
                            ? Colors.white
                            : (isDark
                                ? AppColors.textPrimaryDark
                                : AppColors.textPrimary),
                  ),
                ),
                selected: isSelected,
                selectedColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                backgroundColor:
                    isDark
                        ? AppColors.surfaceVariantDark
                        : Colors.grey.shade200,
                onSelected: (_) => setState(() => selectedIce = opt),
              );
            }),
          ),
          isDark,
        ),

        const SizedBox(height: 25),

        // TOPPINGS OPTIONAL
        _sectionTitle("Toppings", isDark: isDark),
        _container(
          Column(
            children: List.generate(data["toppings"]?.length ?? 0, (i) {
              final t = data["toppings"][i];
              final added = selectedToppings.any((x) => x["name"] == t["name"]);
              return CheckboxListTile(
                title: Text(
                  "${t["name"]}  (+₱${t["price"]})",
                  style: TextStyle(
                    color:
                        isDark
                            ? AppColors.textPrimaryDark
                            : AppColors.textPrimary,
                  ),
                ),
                value: added,
                activeColor:
                    isDark ? AppColors.primaryLight : AppColors.primary,
                checkColor: Colors.white,
                onChanged: (v) {
                  setState(() {
                    if (v == true) {
                      selectedToppings.add(t);
                    } else {
                      selectedToppings.removeWhere(
                        (x) => x["name"] == t["name"],
                      );
                    }
                    toppingsTotal = selectedToppings.fold(
                      0,
                      (sum, x) => sum + int.parse(x["price"].toString()),
                    );
                  });
                },
              );
            }),
          ),
          isDark,
        ),

        const SizedBox(height: 25),

        _sectionTitle("Note to Vendor", isDark: isDark),
        _container(
          TextField(
            controller: noteCtrl,
            maxLines: 2,
            style: TextStyle(
              color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
            ),
            decoration: InputDecoration(
              border: InputBorder.none,
              hintText: "Add your request (optional)",
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

        const SizedBox(height: 140),
      ],
    );
  }

  // ------------------------------------------------------------
  // SECTION TITLE UI
  // ------------------------------------------------------------
  Widget _sectionTitle(
    String text, {
    bool required = false,
    String keyName = "",
    required bool isDark,
  }) {
    bool done = required ? isCompleted(keyName) : false;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimary,
          ),
        ),
        if (required)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color:
                  done
                      ? (isDark
                          ? AppColors.surfaceVariantDark
                          : Colors.grey.shade300)
                      : (isDark
                          ? AppColors.primary.withOpacity(0.2)
                          : Colors.blue.shade50),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              done ? "Completed" : "Required",
              style: TextStyle(
                color:
                    done
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
              "Optional",
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppColors.textSecondaryDark : Colors.black54,
              ),
            ),
          ),
      ],
    );
  }

  Widget _container(Widget child, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceVariantDark : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ------------------------------------------------------------
  // BOTTOM BAR
  // ------------------------------------------------------------
  Widget _bottomBar(bool isDark) {
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
          // QUANTITY
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
                      quantity > 1 ? () => setState(() => quantity--) : null,
                ),
                Text(
                  "$quantity",
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
                  onPressed: () => setState(() => quantity++),
                ),
              ],
            ),
          ),

          const SizedBox(width: 12),

          // ADD TO CART
          Expanded(
            child: ElevatedButton(
              onPressed:
                  isCompleted("size") &&
                          isCompleted("sugar") &&
                          isCompleted("ice")
                      ? addToCart
                      : null,
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
                "Add to cart • ₱${computeTotal()}",
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
