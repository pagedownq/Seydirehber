import 'package:shared_preferences/shared_preferences.dart';

class BlockService {
  static const String _blockKey = 'blocked_user_uids';
  static SharedPreferences? _prefs;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> blockUser(String userId) async {
    await _init();
    final List<String> blockedUsers = _prefs?.getStringList(_blockKey) ?? [];
    if (!blockedUsers.contains(userId)) {
      blockedUsers.add(userId);
      await _prefs?.setStringList(_blockKey, blockedUsers);
    }
  }

  static Future<bool> isUserBlocked(String userId) async {
    await _init();
    final List<String> blockedUsers = _prefs?.getStringList(_blockKey) ?? [];
    return blockedUsers.contains(userId);
  }

  static Future<List<String>> getBlockedUsers() async {
    await _init();
    return _prefs?.getStringList(_blockKey) ?? [];
  }

  static Future<void> clearBlockedUsers() async {
    await _init();
    await _prefs?.remove(_blockKey);
  }
}
