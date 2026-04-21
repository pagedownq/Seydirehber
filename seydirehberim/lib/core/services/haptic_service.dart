import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HapticService {
  static const String _key = 'haptics_enabled';
  static bool _enabled = true;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _enabled = prefs.getBool(_key) ?? true;
  }

  static bool get hapticsEnabled => _enabled;

  static Future<void> setEnabled(bool value) async {
    _enabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, value);
  }

  // Wrapper for common haptic methods
  static void light() {
    if (_enabled) HapticFeedback.lightImpact();
  }

  static void medium() {
    if (_enabled) HapticFeedback.mediumImpact();
  }

  static void heavy() {
    if (_enabled) HapticFeedback.heavyImpact();
  }

  static void selection() {
    if (_enabled) HapticFeedback.selectionClick();
  }

  static void vibrate() {
    if (_enabled) HapticFeedback.vibrate();
  }
}
