import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer => FirebaseAnalyticsObserver(analytics: _analytics);

  /// Sayfa görüntüleme günlüğü
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
    debugPrint('📊 Analytics: Screen View -> $screenName');
  }

  /// Özel olay günlüğü (Buton tıklamaları vb.)
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
    debugPrint('📊 Analytics: Event -> $name ${parameters ?? ''}');
  }

  /// Buton tıklama günlüğü
  Future<void> logButtonClick({
    required String buttonName,
    String? screenName,
  }) async {
    await logEvent(
      name: 'button_click',
      parameters: {
        'button_id': buttonName,
        if (screenName != null) 'screen_name': screenName,
      },
    );
  }

  /// Kullanıcı girişi günlüğü
  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  /// Kullanıcı ID'si atama
  Future<void> setUserId(String id) async {
    await _analytics.setUserId(id: id);
  }

  /// Kullanıcı özelliği atama
  Future<void> setUserProperty({required String name, required String value}) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
