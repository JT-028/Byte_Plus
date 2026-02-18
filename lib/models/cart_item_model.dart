class CartItemModel {
  final String id; // Firestore doc ID
  final String storeId;
  final String productId;
  final String productName;
  final String imageUrl;

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
    required this.sizeName,
    required this.sizePrice,
    required this.sugarLevel,
    required this.iceLevel,
    required this.toppings,
    required this.toppingsTotal,
    required this.note,
    required this.quantity,
    required this.lineTotal,
  });

  factory CartItemModel.fromFirestore(String id, Map<String, dynamic> data) {
    return CartItemModel(
      id: id,
      storeId: data['storeId'] ?? '',
      productId: data['productId'] ?? '',
      productName: data['productName'] ?? '',
      imageUrl: data['imageUrl'] ?? '',
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
