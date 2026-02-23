// Script to update product images from local assets to Cloudinary
// Run this once via the admin panel to upload all product images

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

class ProductImageUpdater {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Cloudinary credentials (same as CloudinaryService)
  static const String cloudName = 'ddg9ffo5r';
  static const String uploadPreset = 'byteplus_menu';
  static const String apiKey = '114576144695534';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  // Image mappings for Angelina Store
  static const Map<String, String> angelinaImages = {
    // Beverages
    'MINERAL WATER 350ML':
        'assets/images/Products/Angelina Store/beverage/Mineral water.png',
    'MINERAL WATER 500ML':
        'assets/images/Products/Angelina Store/beverage/Refresh-Mineral-Water-500mL.webp',
    'C2 APPLE 355ML':
        'assets/images/Products/Angelina Store/beverage/C2Apple.webp',
    'C2 LEMON 355ML':
        'assets/images/Products/Angelina Store/beverage/C2Lemon.jpg',
    'REAL LEAF 500ML':
        'assets/images/Products/Angelina Store/beverage/RealLeaf.jpg',
    'COKE MISMO':
        'assets/images/Products/Angelina Store/beverage/coke-mismo.png',
    'ROYAL MISMO':
        'assets/images/Products/Angelina Store/beverage/royalmismo.jpg',
    'SPRITE MISMO':
        'assets/images/Products/Angelina Store/beverage/sprite-mismo.webp',
    'MT. DEW': 'assets/images/Products/Angelina Store/beverage/mtdew.webp',

    // Breads / Pastries
    'RAISIN COOKIES':
        'assets/images/Products/Angelina Store/BreadPatries/Raisin-cookies.jpg',
    'PIANONO':
        'assets/images/Products/Angelina Store/BreadPatries/pianono.jpeg',
    'OREJAS': 'assets/images/Products/Angelina Store/BreadPatries/Oreja.jpg',
    'SPANISH BREAD':
        'assets/images/Products/Angelina Store/BreadPatries/spanish-bread.png',
    'MOJACKO': 'assets/images/Products/Angelina Store/BreadPatries/mojako1.jpg',
    'HAM & CHEESE':
        'assets/images/Products/Angelina Store/BreadPatries/ham-&-cheese.jpg',
    'KABABAYAN':
        'assets/images/Products/Angelina Store/BreadPatries/Kababayan.jpeg',
    'LAKAS UBE':
        'assets/images/Products/Angelina Store/BreadPatries/LakasUbe.jpg',
    'LAKAS WHITE':
        'assets/images/Products/Angelina Store/BreadPatries/Lakas-white.jpg',
    'KRINKLES':
        'assets/images/Products/Angelina Store/BreadPatries/crinkle.webp',
    'HOPIA KUNDOL':
        'assets/images/Products/Angelina Store/BreadPatries/Hopia-kundol.jpg',
    'PUSIY BREAD':
        'assets/images/Products/Angelina Store/BreadPatries/pusiy-bread.jpg',
    'CHEESE BREAD':
        'assets/images/Products/Angelina Store/BreadPatries/cheese-bread.webp',
    'PAN DE GATAS':
        'assets/images/Products/Angelina Store/BreadPatries/pan-de-gatas.webp',

    // Chips
    'MR. CHIPS (small)':
        'assets/images/Products/Angelina Store/chips/mr.chips.webp',
    'PILLOWS': 'assets/images/Products/Angelina Store/chips/pillows.webp',
    'CHEEZY (big)': 'assets/images/Products/Angelina Store/chips/Cheezy.jpg',
    'PIATTOS GREEN (small)':
        'assets/images/Products/Angelina Store/chips/piattos-green.jpg',
    'PIATTOS BLUE (small)':
        'assets/images/Products/Angelina Store/chips/piattos-blue.webp',
    'POTATO FRIES (bbq flavor)':
        'assets/images/Products/Angelina Store/chips/potato-fries.jpg',

    // Biscuits
    'DEWBERRY (red)':
        'assets/images/Products/Angelina Store/biscuit/dewbwrry-red.jpg',
    'DEWBERRY (blue)':
        'assets/images/Products/Angelina Store/biscuit/dewberry-blue.jpg',
    'CREAM O': 'assets/images/Products/Angelina Store/biscuit/crean-o.webp',
  };

  // Image mappings for Potato Corner
  static const Map<String, String> potatoCornerImages = {
    // Popular Menu
    'Flavored Fries Tera':
        'assets/images/Products/Potato Corner/Popular Potato Corner Menu Prices/Flavored-Fries-Tera.webp',
    'Flavored Fries Mega':
        'assets/images/Products/Potato Corner/Popular Potato Corner Menu Prices/Flavored-Fries-Mega.webp',
    'Tera Mix':
        'assets/images/Products/Potato Corner/Popular Potato Corner Menu Prices/Tera-Mix.webp',
    'Mega Mix – Fries & Loopys':
        'assets/images/Products/Potato Corner/Popular Potato Corner Menu Prices/Mega-Mix-Fries-Loopys.webp',

    // Snacks & Chicken
    'Chicken Fries':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Potato-Corner-Chicken-Fries-price (1).webp',
    'Loopys Mega':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Loopys-Mega.webp',
    'Crunchy Chicken Pops':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Crunchy-Chicken-Pops.webp',
    'Large Mix – Fries & Loopys':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Large-Mix-Fries-Loopys.webp',
    'Large Mix – Fries & Crunchy Chicken Pops':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Large-Mix-Fries-Crunchy-Chicken-Pops.webp',
    'Large Mix – Loopys & Crunchy Chicken Pops':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Large-Mix-Loopys-Crunchy-Chicken-Pops.webp',
    'Mega Mix – Fries & Crunchy Chicken Pops':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Mega-Mix-Fries-Crunchy-Chicken-Pops.webp',
    'Mega Mix – Loopys & Crunchy Chicken Pops':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Mega-Mix-Loopys-Crunchy-Chicken-Pops.webp',
    'Flavored Fries Jumbo':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Flavored-Fries-Jumbo.webp',
    'Crunchy Chicken Pops Solo':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Crunchy-Chicken-Pops-Solo.webp',
    'Crunchy Chicken Pops Large Mix':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Crunchy-Chicken-Pops-Large-Mix.webp',
    'Crunchy Chicken Pops Mega Mix':
        'assets/images/Products/Potato Corner/New Snacks & Chicken/Crunchy-Chicken-Pops-Mega-Mix.webp',
  };

  /// Upload image bytes to Cloudinary
  static Future<String?> _uploadToCloudinary(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));
      request.fields['upload_preset'] = uploadPreset;
      request.fields['api_key'] = apiKey;
      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        return jsonData['secure_url'] as String?;
      } else {
        debugPrint('[ImageUpdater] Upload failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('[ImageUpdater] Upload error: $e');
      return null;
    }
  }

  /// Load asset image as bytes
  static Future<Uint8List?> _loadAssetImage(String assetPath) async {
    try {
      final byteData = await rootBundle.load(assetPath);
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('[ImageUpdater] Failed to load asset: $assetPath - $e');
      return null;
    }
  }

  /// Update images for Angelina Store
  static Future<Map<String, dynamic>> updateAngelinaStoreImages({
    required Function(String) onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    final List<String> errors = [];

    // Find Angelina store
    onProgress('🔍 Searching for Angelina store...');
    final storesQuery =
        await _firestore
            .collection('stores')
            .where('name', isEqualTo: 'Angelina store')
            .get();

    if (storesQuery.docs.isEmpty) {
      onProgress('❌ Angelina store not found!');
      return {'success': 0, 'failed': 0, 'error': 'Angelina store not found'};
    }

    final storeId = storesQuery.docs.first.id;
    onProgress('✅ Found Angelina store: $storeId');

    // Get all menu items
    final menuQuery =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .get();

    onProgress(
      '📦 Found ${menuQuery.docs.length} menu items in Angelina store',
    );
    onProgress('🎯 Starting image updates...');

    for (var doc in menuQuery.docs) {
      final data = doc.data();
      final productName = data['name']?.toString() ?? '';

      if (angelinaImages.containsKey(productName)) {
        final assetPath = angelinaImages[productName]!;
        onProgress('🔄 Processing: $productName');

        // Load asset
        final imageBytes = await _loadAssetImage(assetPath);
        if (imageBytes == null) {
          errors.add('$productName: Failed to load asset');
          onProgress('  ❌ Failed to load asset: $assetPath');
          failed++;
          continue;
        }

        // Upload to Cloudinary
        final fileName = assetPath.split('/').last;
        final cloudinaryUrl = await _uploadToCloudinary(imageBytes, fileName);

        if (cloudinaryUrl != null) {
          // Update Firestore
          await doc.reference.update({
            'imageUrl': cloudinaryUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          onProgress('  ✅ Updated: $productName');
          success++;
        } else {
          errors.add('$productName: Failed to upload to Cloudinary');
          onProgress('  ❌ Failed to upload to Cloudinary');
          failed++;
        }
      } else {
        onProgress('⚠️ No image mapping for: "$productName"');
      }
    }

    return {'success': success, 'failed': failed, 'errors': errors};
  }

  /// Update images for Potato Corner
  static Future<Map<String, dynamic>> updatePotatoCornerImages({
    required Function(String) onProgress,
  }) async {
    int success = 0;
    int failed = 0;
    final List<String> errors = [];

    // Find Potato Corner store
    onProgress('🔍 Searching for POTATO CORNER store...');

    // Debug: List all stores first
    final allStores = await _firestore.collection('stores').get();
    onProgress('📋 Found ${allStores.docs.length} stores in database:');
    for (var store in allStores.docs) {
      onProgress('  - ${store.data()['name']} (ID: ${store.id})');
    }

    final storesQuery =
        await _firestore
            .collection('stores')
            .where('name', isEqualTo: 'Potato Corner')
            .get();

    if (storesQuery.docs.isEmpty) {
      onProgress('❌ POTATO CORNER not found!');
      return {'success': 0, 'failed': 0, 'error': 'POTATO CORNER not found'};
    }

    final storeId = storesQuery.docs.first.id;
    onProgress('✅ Found POTATO CORNER: $storeId');

    // Get all menu items
    final menuQuery =
        await _firestore
            .collection('stores')
            .doc(storeId)
            .collection('menu')
            .get();

    onProgress('📦 Found ${menuQuery.docs.length} menu items in POTATO CORNER');
    onProgress('📝 Product names in database:');
    for (var doc in menuQuery.docs) {
      final name = doc.data()['name']?.toString() ?? 'UNNAMED';
      onProgress('  - "$name"');
    }

    onProgress('\n🎯 Starting image updates...');

    for (var doc in menuQuery.docs) {
      final data = doc.data();
      final productName = data['name']?.toString() ?? '';

      if (potatoCornerImages.containsKey(productName)) {
        final assetPath = potatoCornerImages[productName]!;
        onProgress('🔄 Processing: $productName');

        // Load asset
        final imageBytes = await _loadAssetImage(assetPath);
        if (imageBytes == null) {
          errors.add('$productName: Failed to load asset');
          onProgress('  ❌ Failed to load asset: $assetPath');
          failed++;
          continue;
        }

        // Upload to Cloudinary
        final fileName = assetPath.split('/').last;
        final cloudinaryUrl = await _uploadToCloudinary(imageBytes, fileName);

        if (cloudinaryUrl != null) {
          // Update Firestore
          await doc.reference.update({
            'imageUrl': cloudinaryUrl,
            'updatedAt': FieldValue.serverTimestamp(),
          });
          onProgress('  ✅ Updated: $productName');
          success++;
        } else {
          errors.add('$productName: Failed to upload to Cloudinary');
          onProgress('  ❌ Failed to upload to Cloudinary');
          failed++;
        }
      } else {
        onProgress('⚠️ No image mapping for: "$productName"');
      }
    }

    return {'success': success, 'failed': failed, 'errors': errors};
  }

  /// Update all product images
  static Future<Map<String, dynamic>> updateAllImages({
    required Function(String) onProgress,
  }) async {
    onProgress('🚀 Starting image update...\n');

    onProgress('\n📦 Updating Angelina Store images...');
    final angelinaResult = await updateAngelinaStoreImages(
      onProgress: onProgress,
    );

    onProgress('\n📦 Updating POTATO CORNER images...');
    final potatoResult = await updatePotatoCornerImages(onProgress: onProgress);

    final totalSuccess =
        (angelinaResult['success'] as int) + (potatoResult['success'] as int);
    final totalFailed =
        (angelinaResult['failed'] as int) + (potatoResult['failed'] as int);

    onProgress('\n✨ Update complete!');
    onProgress('Success: $totalSuccess');
    onProgress('Failed: $totalFailed');

    return {
      'angelina': angelinaResult,
      'potatoCorner': potatoResult,
      'totalSuccess': totalSuccess,
      'totalFailed': totalFailed,
    };
  }
}

