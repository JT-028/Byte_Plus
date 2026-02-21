// Script to populate store menus from the pricelist
// Run this once to add all products to Firestore

import 'package:cloud_firestore/cloud_firestore.dart';

class StoreMenuPopulator {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Placeholder image URL
  static const String placeholderImage =
      'https://via.placeholder.com/400x300/E8F5E9/4CAF50?text=Product+Image';

  static Future<void> populateAngelinaStore() async {
    print('🏪 Finding Angelina store...');

    // Find Angelina store
    final storesQuery =
        await _firestore
            .collection('stores')
            .where('name', isEqualTo: 'Angelina store')
            .get();

    String? storeId;
    if (storesQuery.docs.isEmpty) {
      print('Creating Angelina store...');
      final storeRef = await _firestore.collection('stores').add({
        'name': 'Angelina store',
        'description':
            'Convenience store offering beverages, breads, and snacks',
        'logoUrl': placeholderImage,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      storeId = storeRef.id;
    } else {
      storeId = storesQuery.docs.first.id;
    }

    print('✅ Store ID: $storeId');
    final storeRef = _firestore.collection('stores').doc(storeId);

    // Create categories
    print('📁 Creating categories...');
    await _createCategory(storeRef, 'BEVERAGES');
    await _createCategory(storeRef, 'BREADS / PASTRIES');
    await _createCategory(storeRef, 'CHIPS');
    await _createCategory(storeRef, 'BISCUITS');

    // Add BEVERAGES
    print('🥤 Adding beverages...');
    final beverages = [
      {'name': 'MINERAL WATER 350ML', 'price': 20.0},
      {'name': 'MINERAL WATER 500ML', 'price': 30.0},
      {'name': 'C2 APPLE 355ML', 'price': 35.0},
      {'name': 'C2 LEMON 355ML', 'price': 35.0},
      {'name': 'REAL LEAF 500ML', 'price': 40.0},
      {'name': 'COKE MISMO', 'price': 30.0},
      {'name': 'ROYAL MISMO', 'price': 30.0},
      {'name': 'SPRITE MISMO', 'price': 30.0},
      {'name': 'MT. DEW', 'price': 30.0},
    ];

    for (var product in beverages) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'BEVERAGES',
      );
    }

    // Add BREADS / PASTRIES
    print('🍞 Adding breads and pastries...');
    final breads = [
      {'name': 'RAISIN COOKIES', 'price': 10.0},
      {'name': 'PIANONO', 'price': 10.0},
      {'name': 'OREJAS', 'price': 10.0},
      {'name': 'SPANISH BREAD', 'price': 10.0},
      {'name': 'MOJACKO', 'price': 10.0},
      {'name': 'HAM & CHEESE', 'price': 15.0},
      {'name': 'KABABAYAN', 'price': 10.0},
      {'name': 'LAKAS UBE', 'price': 10.0},
      {'name': 'LAKAS WHITE', 'price': 15.0},
      {'name': 'KRINKLES', 'price': 10.0},
      {'name': 'HOPIA KUNDOL', 'price': 10.0},
      {'name': 'PUSIY BREAD', 'price': 10.0},
      {'name': 'CHEESE BREAD', 'price': 10.0},
      {'name': 'PAN DE GATAS', 'price': 15.0},
    ];

    for (var product in breads) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'BREADS / PASTRIES',
      );
    }

    // Add CHIPS
    print('🍟 Adding chips...');
    final chips = [
      {'name': 'MR. CHIPS (small)', 'price': 15.0},
      {'name': 'PILLOWS', 'price': 15.0},
      {'name': 'CHEEZY (big)', 'price': 45.0},
      {'name': 'PIATTOS GREEN (small)', 'price': 20.0},
      {'name': 'PIATTOS BLUE (small)', 'price': 20.0},
      {'name': 'POTATO FRIES (bbq flavor)', 'price': 20.0},
    ];

    for (var product in chips) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'CHIPS',
      );
    }

    // Add BISCUITS
    print('🍪 Adding biscuits...');
    final biscuits = [
      {'name': 'DEWBERRY (red)', 'price': 15.0},
      {'name': 'DEWBERRY (blue)', 'price': 15.0},
      {'name': 'CREAM O', 'price': 15.0},
    ];

    for (var product in biscuits) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'BISCUITS',
      );
    }

    print('✅ Angelina store menu completed!');
  }

  static Future<void> populatePotatoCorner() async {
    print('🏪 Finding POTATO CORNER...');

    // Find POTATO CORNER store
    final storesQuery =
        await _firestore
            .collection('stores')
            .where('name', isEqualTo: 'POTATO CORNER')
            .get();

    String? storeId;
    if (storesQuery.docs.isEmpty) {
      print('Creating POTATO CORNER...');
      final storeRef = await _firestore.collection('stores').add({
        'name': 'POTATO CORNER',
        'description': 'Famous for flavored fries and chicken snacks',
        'logoUrl': placeholderImage,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      storeId = storeRef.id;
    } else {
      storeId = storesQuery.docs.first.id;
    }

    print('✅ Store ID: $storeId');
    final storeRef = _firestore.collection('stores').doc(storeId);

    // Create categories
    print('📁 Creating categories...');
    await _createCategory(storeRef, 'Popular Menu');
    await _createCategory(storeRef, 'Snacks & Chicken');

    // Add Popular Menu items
    print('🍟 Adding popular menu items...');
    final popularMenu = [
      {'name': 'Flavored Fries Tera', 'price': 255.0},
      {'name': 'Flavored Fries Mega', 'price': 155.0},
      {'name': 'Tera Mix', 'price': 285.0},
      {'name': 'Mega Mix – Fries & Loopys', 'price': 230.0},
    ];

    for (var product in popularMenu) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'Popular Menu',
      );
    }

    // Add Snacks & Chicken
    print('🍗 Adding snacks and chicken items...');
    final snacksChicken = [
      {'name': 'Chicken Fries', 'price': 95.0},
      {'name': 'Loopys Mega', 'price': 155.0},
      {'name': 'Crunchy Chicken Pops', 'price': 219.0},
      {'name': 'Large Mix – Fries & Loopys', 'price': 120.0},
      {'name': 'Large Mix – Fries & Crunchy Chicken Pops', 'price': 120.0},
      {'name': 'Large Mix – Loopys & Crunchy Chicken Pops', 'price': 120.0},
      {'name': 'Mega Mix – Fries & Crunchy Chicken Pops', 'price': 169.0},
      {'name': 'Mega Mix – Loopys & Crunchy Chicken Pops', 'price': 169.0},
      {'name': 'Flavored Fries Jumbo', 'price': 115.0},
      {'name': 'Crunchy Chicken Pops Solo', 'price': 95.0},
      {'name': 'Crunchy Chicken Pops Large Mix', 'price': 120.0},
      {'name': 'Crunchy Chicken Pops Mega Mix', 'price': 150.0},
    ];

    for (var product in snacksChicken) {
      await _addProduct(
        storeRef,
        product['name'] as String,
        product['price'] as double,
        'Snacks & Chicken',
      );
    }

    print('✅ POTATO CORNER menu completed!');
  }

  static Future<void> _createCategory(
    DocumentReference storeRef,
    String categoryName,
  ) async {
    final existingCategory =
        await storeRef
            .collection('categories')
            .where('name', isEqualTo: categoryName)
            .get();

    if (existingCategory.docs.isEmpty) {
      await storeRef.collection('categories').add({
        'name': categoryName,
        'createdAt': FieldValue.serverTimestamp(),
      });
      print('  ✓ Created category: $categoryName');
    } else {
      print('  • Category already exists: $categoryName');
    }
  }

  static Future<void> _addProduct(
    DocumentReference storeRef,
    String name,
    double price,
    String category,
  ) async {
    // Check if product already exists
    final existingProduct =
        await storeRef.collection('menu').where('name', isEqualTo: name).get();

    if (existingProduct.docs.isEmpty) {
      await storeRef.collection('menu').add({
        'name': name,
        'price': price,
        'imageUrl': placeholderImage,
        'category': [category],
        'isAvailable': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      print('  ✓ Added: $name - ₱$price');
    } else {
      print('  • Already exists: $name');
    }
  }

  static Future<void> populateAll() async {
    print('\n🚀 Starting menu population...\n');

    try {
      await populateAngelinaStore();
      print('\n');
      await populatePotatoCorner();
      print('\n✨ All menus populated successfully!\n');
    } catch (e) {
      print('\n❌ Error: $e\n');
      rethrow;
    }
  }
}
