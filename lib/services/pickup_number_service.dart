import 'package:cloud_firestore/cloud_firestore.dart';

class PickupNumberService {
  static final _db = FirebaseFirestore.instance;

  /// Gets the next pickup number in format A01, A02... A99, B01... etc.
  static Future<String> generateNextPickupNumber() async {
    final ref = _db.collection("config").doc("orderCounter");

    return FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(ref);

      int number = snap.get("number");
      String prefix = snap.get("prefix");

      // Format current pickup number (example: A01)
      String pickupNumber = "$prefix${number.toString().padLeft(2, '0')}";

      // Increment number
      number++;

      // If number > 99 → reset to 01 and advance prefix
      if (number > 99) {
        number = 1;
        prefix = _incrementPrefix(prefix);
      }

      // Save new prefix + number
      tx.update(ref, {
        "number": number,
        "prefix": prefix,
      });

      return pickupNumber;
    });
  }

  /// Converts A → B → ... → Z → AA → AB → ...
  static String _incrementPrefix(String prefix) {
    List<int> chars = prefix.codeUnits;

    for (int i = chars.length - 1; i >= 0; i--) {
      if (chars[i] < 90) { // 'Z'
        chars[i]++;
        return String.fromCharCodes(chars);
      } else {
        chars[i] = 65; // 'A'
      }
    }

    // If all Z → Append new letter (Z → AA)
    chars.insert(0, 65);
    return String.fromCharCodes(chars);
  }
}

