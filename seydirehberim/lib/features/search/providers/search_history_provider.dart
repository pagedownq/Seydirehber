import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final searchHistoryProvider = StateNotifierProvider<SearchHistoryNotifier, List<String>>((ref) {
  return SearchHistoryNotifier();
});

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  SearchHistoryNotifier() : super([]) {
    _loadHistory();
  }

  static const String _key = 'search_history';
  static const int _maxHistory = 10;

  Future<void> _loadHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final history = prefs.getStringList(_key) ?? [];
    state = history;
  }

  Future<void> addSearchTerm(String term) async {
    final cleanTerm = term.trim();
    if (cleanTerm.isEmpty) return;

    final newState = List<String>.from(state);
    
    // Varsa önce eskiyi çıkar (başa taşımak için)
    newState.remove(cleanTerm);
    
    // Başa ekle
    newState.insert(0, cleanTerm);
    
    // Sınırı aşanları sil
    if (newState.length > _maxHistory) {
      newState.removeLast();
    }

    state = newState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> removeSearchTerm(String term) async {
    final newState = List<String>.from(state);
    newState.remove(term);
    state = newState;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(_key, state);
  }

  Future<void> clearHistory() async {
    state = [];
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}
