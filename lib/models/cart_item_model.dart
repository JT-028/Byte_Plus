class CartItemModel {
  final String id; // Firestore doc ID
  final String storeId;
  final String productId;
  final String productName;
  final String imageUrl;

  // New structure (variations & choice groups)
  final String variationName;
  final double variationPrice;
  final List<Map<String, dynamic>> selectedChoices;
  final double choicesTotal;

  // Legacy fields (for backwards compatibility)
  final String sizeName;
  final double sizePrice;
  final String sugarLevel;
  final String iceLevel;
  final List<Map<String, dynamic>> toppings;
  final double toppingsTotal;

  final String note;
  final int quantity;
  final double lineTotal;

  CartItemModel({
    required this.id,
    required this.storeId,
    required this.productId,
    required this.productName,
    required this.imageUrl,
    this.variationName = '',
    this.variationPrice = 0,
    this.selectedChoices = const [],
    this.choicesTotal = 0,
    this.sizeName = '',
    this.sizePrice = 0,
    this.sugarLevel = '',
    this.iceLevel = '',
    this.toppings = const [],
    this.toppingsTotal = 0,
    required this.note,
    required this.quantity,
    required this.lineTotal,
  });

  /// Get display variation (new or legacy)
  String get displayVariation =>
      variationName.isNotEmpty ? variationName : sizeName;

  /// Get display subtitle for cart item
  String get displaySubtitle {
    final parts = <String>[];

    // Variation/Size
    final variation = variationName.isNotEmpty ? variationName : sizeName;
    if (variation.isNotEmpty) parts.add(variation);

    // New choice groups
    if (selectedChoices.isNotEmpty) {
      for (var choice in selectedChoices) {
        final name = choice['name']?.toString() ?? '';
        if (name.isNotEmpty) parts.add(name);
      }
    } else {
      // Legacy sugar/ice/toppings
      if (sugarLevel.isNotEmpty) parts.add(sugarLevel);
      if (iceLevel.isNotEmpty) parts.add(iceLevel);
      for (var t in toppings) {
        final name = t['name']?.toString() ?? '';
        if (name.isNotEmpty) parts.add(name);
      }
    }

    return parts.join(' • ');
  }

  factory CartItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CartItemModel(
      id: id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
      variationName: data['variationName'] ?? '',
      variationPrice: (data['variationPrice'] as num?)?.toDouble() ?? 0,
      selectedChoices: List<Map<String, dynamic>>.from(
        data['selectedChoices'] ?? [],
      ),
      choicesTotal: (data['choicesTotal'] as num?)?.toDouble() ?? 0,
      sizeName: data['sizeName'] ?? '',
      sizePrice: (data['sizePrice'] as num?)?.toDouble() ?? 0,
      sugarLevel: data['sugarLevel'] ?? '',
      iceLevel: data['iceLevel'] ?? '',
      toppings: List<Map<String, dynamic>>.from(data['toppings'] ?? []),
      toppingsTotal: (data['toppingsTotal'] as num?)?.toDouble() ?? 0,
      note: data['note'] ?? '',
      quantity: (data['quantity'] as num?)?.toInt() ?? 1,
      lineTotal: (data['lineTotal'] as num?)?.toDouble() ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "storeId": storeId,
      "productId": productId,
      "productName": productName,
      "imageUrl": imageUrl,
      "variationName": variationName,
      "variationPrice": variationPrice,
      "selectedChoices": selectedChoices,
      "choicesTotal": choicesTotal,
      "sizeName": sizeName,
      "sizePrice": sizePrice,
      "sugarLevel": sugarLevel,
      "iceLevel": iceLevel,
      "toppings": toppings,
      "toppingsTotal": toppingsTotal,
      "note": note,
      "quantity": quantity,
      "lineTotal": lineTotal,
    };
  }
}

