import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LocalCacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic list save
  static Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    if (_prefs == null) await init();
    
    // Handle Firestore Timestamp objects which are not natively encodable to JSON
    final String encoded = jsonEncode(list, toEncodable: (item) {
      if (item is Timestamp) {
        return item.toDate().toIso8601String();
      }
      return item;
    });
    
    await _prefs!.setString(key, encoded);
  }

  // Generic list get
  static List<Map<String, dynamic>>? getList(String key) {
    if (_prefs == null) return null;
    final String? encoded = _prefs!.getString(key);
    if (encoded == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) {
        final Map<String, dynamic> item = Map<String, dynamic>.from(e);
        // Recursively restore Timestamps
        return _restoreTimestamps(item) as Map<String, dynamic>;
      }).toList();
    } catch (e) {
      return null;
    }
  }

  // Strict ISO8601 pattern: 2024-03-27T10:00:00.000Z or similar
  static final _iso8601Pattern = RegExp(
    r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}',
  );

  static dynamic _restoreTimestamps(dynamic value) {
    if (value is Map) {
      return value.map((k, v) => MapEntry(k, _restoreTimestamps(v)));
    } else if (value is List) {
      return value.map((e) => _restoreTimestamps(e)).toList();
    } else if (value is String) {
      // Only match strings that strictly look like ISO8601 dates
      // e.g. "2024-03-27T10:00:00.000Z" — NOT URLs or random text with hyphens
      if (value.length >= 19 && _iso8601Pattern.hasMatch(value)) {
        final dt = DateTime.tryParse(value);
        if (dt != null) {
          return Timestamp.fromDate(dt);
        }
      }
    }
    return value;
  }

  // Simple existence check
  static bool hasKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}
