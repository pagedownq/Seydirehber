import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final analyticsServiceProvider = Provider((ref) => AnalyticsService());

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver getObserver() => FirebaseAnalyticsObserver(analytics: _analytics);

  // Screen tracking
  Future<void> logScreenView({required String screenName, String? screenClass}) async {
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass ?? screenName,
    );
  }

  // Common Events
  Future<void> logEvent(String name, {Map<String, Object>? parameters}) async {
    await _analytics.logEvent(
      name: name,
      parameters: parameters,
    );
  }

  // Specific Business Events
  Future<void> logCompanyView(String companyId, String companyName) async {
    await logEvent('view_company', parameters: {
      'company_id': companyId,
      'company_name': companyName,
    });
  }

  Future<void> logPlaceView(String placeId, String placeName) async {
    await logEvent('view_place', parameters: {
      'place_id': placeId,
      'place_name': placeName,
    });
  }

  Future<void> logEventClick(String eventId, String eventTitle) async {
    await logEvent('click_event', parameters: {
      'event_id': eventId,
      'event_title': eventTitle,
    });
  }

  Future<void> logCouponView(String couponId, String couponName) async {
    await logEvent('view_coupon', parameters: {
      'coupon_id': couponId,
      'coupon_name': couponName,
    });
  }

  Future<void> logSearch(String searchTerm) async {
    await _analytics.logSearch(searchTerm: searchTerm);
  }

  Future<void> logLogin(String method) async {
    await _analytics.logLogin(loginMethod: method);
  }

  Future<void> logSignUp(String method) async {
    await _analytics.logSignUp(signUpMethod: method);
  }

  Future<void> setUserId(String? id) async {
    await _analytics.setUserId(id: id);
  }

  Future<void> setUserProperty(String name, String value) async {
    await _analytics.setUserProperty(name: name, value: value);
  }
}
