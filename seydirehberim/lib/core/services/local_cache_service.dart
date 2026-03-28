import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalCacheService {
  static SharedPreferences? _prefs;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Generic list save
  static Future<void> saveList(String key, List<Map<String, dynamic>> list) async {
    if (_prefs == null) await init();
    final String encoded = jsonEncode(list);
    await _prefs!.setString(key, encoded);
  }

  // Generic list get
  static List<Map<String, dynamic>>? getList(String key) {
    if (_prefs == null) return null;
    final String? encoded = _prefs!.getString(key);
    if (encoded == null) return null;
    try {
      final List<dynamic> decoded = jsonDecode(encoded);
      return decoded.map((e) => Map<String, dynamic>.from(e)).toList();
    } catch (e) {
      return null;
    }
  }

  // Simple existence check
  static bool hasKey(String key) {
    return _prefs?.containsKey(key) ?? false;
  }
}
