import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;
import 'notification_service.dart';

class DailyNotificationService {
  static final DailyNotificationService _instance =
      DailyNotificationService._internal();
  factory DailyNotificationService() => _instance;
  DailyNotificationService._internal();

  static const String _lastScheduledKey = 'daily_notif_last_scheduled';
  static const String _dailyNotifEnabledKey = 'daily_notif_enabled';
  static const String channelId = 'seydirehberim_notifications';

  static const int _morningId = 9001;
  static const int _afternoonId = 9002;
  static const int _eveningId = 9003;


  static const List<_NotifTemplate> _morningMessages = [
    _NotifTemplate(title: 'Günaydın! ☀️', body: 'Bugünün hava durumuna göz attın mı? Hemen kontrol et!', route: '/weather'),
    _NotifTemplate(title: 'Günaydın Seydişehir! 📰', body: 'Yeni haberler seni bekliyor, bir göz at!', route: '/news'),
    _NotifTemplate(title: 'Günaydın! 💊', body: 'Bugünün nöbetçi eczanesi hangisi? Hemen öğren!', route: '/pharmacy'),
    _NotifTemplate(title: 'Güne Merhaba! ☕', body: 'Kahvaltını nerede yapacağına karar veremedin mi? En iyileri keşfet!', route: '/companies/popular'),
    _NotifTemplate(title: 'Ulaşım 🚌', body: 'Bugün otobüs kullanacaksan saatlere göz atmayı unutma!', route: '/otobus'),
    _NotifTemplate(title: 'Harika Bir Gün! 🗺️', body: 'Seydişehir\'de bugün gezilecek yerleri keşfetmeye ne dersin?', route: '/places'),
  ];

  static const List<_NotifTemplate> _afternoonMessages = [
    _NotifTemplate(title: 'Seydi Rehber 🎫', body: 'Fırsat kuponlarına baktın mı? İndirimli fırsatlar seni bekliyor!', route: '/coupons'),
    _NotifTemplate(title: 'Öğle Molası 🍔', body: 'Seydişehir\'deki en popüler mekanlar hangileri? Keşfet!', route: '/companies/popular'),
    _NotifTemplate(title: 'Tatlı Krizin mi Tuttu? 🍰', body: 'Rehbere yeni eklenen mekanları ve kafeleri incele.', route: '/companies/latest'),
    _NotifTemplate(title: 'Pazar Alışverişi 🍎', body: 'Seydişehir\'deki halk pazarları nerede kuruluyor? Hemen öğren.', route: '/pazarlar'),
    _NotifTemplate(title: 'Şehirde Neler Oluyor? 📅', body: 'Yaklaşan etkinlikleri kaçırma, planını şimdiden yap!', route: '/events'),
  ];

  static const List<_NotifTemplate> _eveningMessages = [
    _NotifTemplate(title: 'İyi Akşamlar! 🌙', body: 'Yarının hava durumuna şimdiden göz at!', route: '/weather'),
    _NotifTemplate(title: 'Unutma! 💊', body: 'Bugünün nöbetçi eczanesini kontrol ettin mi?', route: '/pharmacy'),
    _NotifTemplate(title: 'Günün Yorgunluğunu At ☕', body: 'Akşam kahvesi için en çok tercih edilen mekanlara göz at.', route: '/companies/popular'),
    _NotifTemplate(title: 'Haberleri Kaçırdın mı? 📰', body: 'Günün öne çıkan gelişmeleri Seydi Rehber\'de. Göz atmak ister misin?', route: '/news'),
    _NotifTemplate(title: 'Seydişehir\'i Keşfet 📱', body: 'Haritayı açıp etrafındaki yeni yerleri keşfetmeye ne dersin?', route: '/seydi-map'),
  ];

  FlutterLocalNotificationsPlugin get _localNotif => NotificationService().localNotificationsPlugin;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone setup error: $e');
    }

    // Plugin is already initialized in NotificationService
    await scheduleDailyNotifications();
  }

  Future<void> scheduleDailyNotifications() async {
    final dailyEnabled = await isDailyNotificationsEnabled();
    if (!dailyEnabled) return;

    final prefs = await SharedPreferences.getInstance();
    final lastScheduled = prefs.getString(_lastScheduledKey);
    final todayStr = _todayString();

    if (lastScheduled == todayStr) {
      debugPrint('[DailyNotif] Bugün zaten planlanmış.');
      return;
    }

    await _cancelDailyNotifications();
    final random = Random();

    await _scheduleNotification(
      id: _morningId,
      template: _morningMessages[random.nextInt(_morningMessages.length)],
      scheduledDate: _nextOccurrence(9, 0),
    );
    await _scheduleNotification(
      id: _afternoonId,
      template: _afternoonMessages[random.nextInt(_afternoonMessages.length)],
      scheduledDate: _nextOccurrence(13, 0),
    );
    await _scheduleNotification(
      id: _eveningId,
      template: _eveningMessages[random.nextInt(_eveningMessages.length)],
      scheduledDate: _nextOccurrence(19, 0),
    );

    await prefs.setString(_lastScheduledKey, todayStr);
  }


  NotificationDetails _getDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Seydi Rehber Bildirimleri',
        channelDescription: 'Günlük bildirimler.',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_stat_s',
        fullScreenIntent: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _scheduleNotification({
    required int id,
    required _NotifTemplate template,
    required tz.TZDateTime scheduledDate,
  }) async {
    try {
      final now = tz.TZDateTime.now(tz.local);
      var finalDate = scheduledDate;
      
      if (finalDate.isBefore(now)) {
        finalDate = finalDate.add(const Duration(days: 1));
      }

      await _localNotif.zonedSchedule(
        id: id,
        title: template.title,
        body: template.body,
        scheduledDate: finalDate,
        notificationDetails: _getDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: template.route,
      );
    } catch (e) {
      debugPrint('[DailyNotif] HATA! ID=$id planlanamadı: $e');
    }
  }

  Future<void> _cancelDailyNotifications() async {
    try {
      await _localNotif.cancel(id: _morningId);
      await _localNotif.cancel(id: _afternoonId);
      await _localNotif.cancel(id: _eveningId);
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  tz.TZDateTime _nextOccurrence(int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  String _todayString() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<bool> isDailyNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyNotifEnabledKey) ?? true;
  }

  Future<void> setDailyNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyNotifEnabledKey, enabled);
    if (enabled) {
      await prefs.remove(_lastScheduledKey);
      await scheduleDailyNotifications();
    } else {
      await _cancelDailyNotifications();
    }
  }
}

class _NotifTemplate {
  final String title;
  final String body;
  final String route;
  const _NotifTemplate({required this.title, required this.body, required this.route});
}
