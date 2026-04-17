import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class BlockedUser {
  final String uid;
  final String name;
  final String? imageUrl;

  BlockedUser({
    required this.uid,
    required this.name,
    this.imageUrl,
  });

  Map<String, dynamic> toJson() => {
    'uid': uid,
    'name': name,
    'imageUrl': imageUrl,
  };

  factory BlockedUser.fromJson(Map<String, dynamic> json) => BlockedUser(
    uid: json['uid'] as String,
    name: json['name'] as String? ?? 'Bilinmeyen Kullanıcı',
    imageUrl: json['imageUrl'] as String?,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is BlockedUser && runtimeType == other.runtimeType && uid == other.uid;

  @override
  int get hashCode => uid.hashCode;
}

class BlockService {
  static const String _blockKey = 'blocked_user_details_json';
  static const String _legacyBlockKey = 'blocked_user_uids';
  static SharedPreferences? _prefs;

  static Future<void> _init() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  static Future<void> blockUser(String userId, {String? name, String? imageUrl}) async {
    await _init();
    final List<BlockedUser> blockedUsers = await getBlockedUsersList();
    
    if (!blockedUsers.any((u) => u.uid == userId)) {
      blockedUsers.add(BlockedUser(
        uid: userId, 
        name: name ?? 'Kullanıcı', 
        imageUrl: imageUrl
      ));
      
      final List<String> jsonList = blockedUsers.map((u) => json.encode(u.toJson())).toList();
      await _prefs?.setStringList(_blockKey, jsonList);
      
      // Also update legacy key for backward compatibility in checks
      final legacyList = _prefs?.getStringList(_legacyBlockKey) ?? [];
      if (!legacyList.contains(userId)) {
        legacyList.add(userId);
        await _prefs?.setStringList(_legacyBlockKey, legacyList);
      }
    }
  }

  static Future<bool> isUserBlocked(String userId) async {
    await _init();
    // Use legacy key for fast checks as it contains all blocked IDs
    final List<String> blockedUsers = _prefs?.getStringList(_legacyBlockKey) ?? [];
    return blockedUsers.contains(userId);
  }

  static Future<List<BlockedUser>> getBlockedUsersList() async {
    await _init();
    final jsonList = _prefs?.getStringList(_blockKey) ?? [];
    
    // Migration/Legacy handling: if legacy key has IDs not in jsonList
    final legacyIds = _prefs?.getStringList(_legacyBlockKey) ?? [];
    List<BlockedUser> list = jsonList.map((s) => BlockedUser.fromJson(json.decode(s))).toList();
    
    // Check if any legacy ID is missing from our detailed list
    for (var id in legacyIds) {
      if (!list.any((u) => u.uid == id)) {
        list.add(BlockedUser(uid: id, name: 'Eski Engellenen ($id)'));
      }
    }
    
    return list;
  }

  static Future<void> unblockUser(String userId) async {
    await _init();
    
    // Update main list
    final List<BlockedUser> list = await getBlockedUsersList();
    list.removeWhere((u) => u.uid == userId);
    final jsonList = list.map((u) => json.encode(u.toJson())).toList();
    await _prefs?.setStringList(_blockKey, jsonList);
    
    // Update legacy list
    final legacyList = _prefs?.getStringList(_legacyBlockKey) ?? [];
    legacyList.remove(userId);
    await _prefs?.setStringList(_legacyBlockKey, legacyList);
  }

  static Future<void> clearBlockedUsers() async {
    await _init();
    await _prefs?.remove(_blockKey);
    await _prefs?.remove(_legacyBlockKey);
  }
}
