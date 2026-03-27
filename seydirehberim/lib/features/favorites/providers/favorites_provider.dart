import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FavoriteItem {
  final String id;
  final String type; // 'company' or 'place'

  FavoriteItem({required this.id, required this.type});

  String toRawString() => '$id:$type';

  factory FavoriteItem.fromRawString(String raw) {
    final parts = raw.split(':');
    return FavoriteItem(id: parts[0], type: parts[1]);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FavoriteItem &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          type == other.type;

  @override
  int get hashCode => id.hashCode ^ type.hashCode;
}

class FavoritesNotifier extends StateNotifier<List<FavoriteItem>> {
  FavoritesNotifier() : super([]) {
    _loadFavorites();
  }

  static const String _storageKey = 'favorites_list';

  Future<void> _loadFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final List<String>? rawList = prefs.getStringList(_storageKey);
    if (rawList != null) {
      state = rawList.map((e) => FavoriteItem.fromRawString(e)).toList();
    }
  }

  Future<void> toggleFavorite(String id, String type) async {
    final item = FavoriteItem(id: id, type: type);
    final isExist = state.any((e) => e.id == id && e.type == type);

    if (isExist) {
      state = state.where((e) => !(e.id == id && e.type == type)).toList();
    } else {
      state = [...state, item];
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _storageKey,
      state.map((e) => e.toRawString()).toList(),
    );
  }

  bool isFavorite(String id, String type) {
    return state.any((e) => e.id == id && e.type == type);
  }
}

final favoritesProvider =
    StateNotifierProvider<FavoritesNotifier, List<FavoriteItem>>((ref) {
  return FavoritesNotifier();
});
