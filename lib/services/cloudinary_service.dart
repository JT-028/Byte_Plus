// lib/services/cloudinary_service.dart
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class CloudinaryService {
  static const String cloudName = 'Byte_Plus';
  static const String uploadPreset = 'byteplus_menu';

  static String get _uploadUrl =>
      'https://api.cloudinary.com/v1_1/$cloudName/image/upload';

  /// Uploads an image file to Cloudinary and returns the secure URL
  /// Returns null if upload fails
  static Future<String?> uploadImage(File imageFile) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      // Add the upload preset (required for unsigned uploads)
      request.fields['upload_preset'] = uploadPreset;

      // Add the image file
      request.files.add(
        await http.MultipartFile.fromPath('file', imageFile.path),
      );

      debugPrint('[Cloudinary] Uploading image...');
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        final secureUrl = jsonData['secure_url'] as String?;
        debugPrint('[Cloudinary] Upload successful: $secureUrl');
        return secureUrl;
      } else {
        final responseData = await response.stream.bytesToString();
        debugPrint(
          '[Cloudinary] Upload failed (${response.statusCode}): $responseData',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[Cloudinary] Upload error: $e');
      return null;
    }
  }

  /// Uploads image bytes (useful for web or when you have bytes instead of File)
  static Future<String?> uploadImageBytes(
    Uint8List bytes,
    String fileName,
  ) async {
    try {
      final request = http.MultipartRequest('POST', Uri.parse(_uploadUrl));

      request.fields['upload_preset'] = uploadPreset;

      request.files.add(
        http.MultipartFile.fromBytes('file', bytes, filename: fileName),
      );

      debugPrint('[Cloudinary] Uploading image bytes...');
      final response = await request.send();

      if (response.statusCode == 200) {
        final responseData = await response.stream.bytesToString();
        final jsonData = json.decode(responseData);
        final secureUrl = jsonData['secure_url'] as String?;
        debugPrint('[Cloudinary] Upload successful: $secureUrl');
        return secureUrl;
      } else {
        final responseData = await response.stream.bytesToString();
        debugPrint(
          '[Cloudinary] Upload failed (${response.statusCode}): $responseData',
        );
        return null;
      }
    } catch (e) {
      debugPrint('[Cloudinary] Upload error: $e');
      return null;
    }
  }
}
