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

  static const String _weeklyScheduledKey = 'weekly_notif_scheduled_v2';
  static const String _dailyNotifEnabledKey = 'daily_notif_enabled';
  static const String channelId = 'seydirehberim_notifications';

  // Notification IDs
  static const int _mondayId = 9101;
  static const int _thursdayId = 9102;
  static const int _fridayId = 9103;
  static const int _sundayId = 9104;

  // Tailored templates for specific days
  static const List<_NotifTemplate> _mondayMessages = [
    _NotifTemplate(title: 'Yeni Haftaya Başlarken ☀️', body: 'Bugünün nöbetçi eczanesini ve güncel otobüs saatlerini hemen öğren!', route: '/pharmacy'),
    _NotifTemplate(title: 'Harika Bir Hafta Olsun! ☕', body: 'Güne güzel bir başlangıç için Seydişehir\'in en sevilen mekanlarını keşfet.', route: '/companies/popular'),
  ];

  static const List<_NotifTemplate> _thursdayMessages = [
    _NotifTemplate(title: 'Pazar Alışverişi Zamanı! 🍎', body: 'Bugün kurulan halk pazarı nerede? Taze alışveriş için yerini hemen öğren.', route: '/pazarlar'),
    _NotifTemplate(title: 'Perşembe Fırsatları 🎫', body: 'Hafta sonu öncesi indirim kuponlarına göz attın mı? Fırsatları kaçırma!', route: '/coupons'),
  ];

  static const List<_NotifTemplate> _fridayMessages = [
    _NotifTemplate(title: 'Hafta Sonu Geldi! 🎉', body: 'Akşam kahvesi veya akşam yemeği için nereye gitmeli? Popüler mekanları keşfet.', route: '/companies/popular'),
    _NotifTemplate(title: 'Hafta Sonuna Özel 🍰', body: 'Rehbere yeni eklenen kafe, restoran ve butikleri incelemeye ne dersin?', route: '/companies/latest'),
  ];

  static const List<_NotifTemplate> _sundayMessages = [
    _NotifTemplate(title: 'Bugün Neler Var? 📅', body: 'Seydişehir\'deki en güncel etkinlikleri kaçırma, planını hemen yap!', route: '/events'),
    _NotifTemplate(title: 'Pazar Keşfi 🗺️', body: 'Seydişehir\'in saklı kalmış doğal ve tarihi güzelliklerini keşfe çık!', route: '/places'),
  ];

  FlutterLocalNotificationsPlugin get _localNotif => NotificationService().localNotificationsPlugin;

  Future<void> initialize() async {
    tz_data.initializeTimeZones();
    try {
      tz.setLocalLocation(tz.getLocation('Europe/Istanbul'));
    } catch (e) {
      debugPrint('Timezone setup error: $e');
    }

    await scheduleDailyNotifications();
  }

  Future<void> scheduleDailyNotifications() async {
    final dailyEnabled = await isDailyNotificationsEnabled();
    if (!dailyEnabled) return;

    final prefs = await SharedPreferences.getInstance();

    // Overwrite the schedules anyway to keep it fresh and updated
    await _cancelDailyNotifications();
    final random = Random();

    // Monday (Pazartesi) @ 09:30 (Day 1)
    await _scheduleWeeklyNotification(
      id: _mondayId,
      template: _mondayMessages[random.nextInt(_mondayMessages.length)],
      dayOfWeek: DateTime.monday,
      hour: 9,
      minute: 30,
    );

    // Thursday (Perşembe) @ 10:00 (Day 4)
    await _scheduleWeeklyNotification(
      id: _thursdayId,
      template: _thursdayMessages[random.nextInt(_thursdayMessages.length)],
      dayOfWeek: DateTime.thursday,
      hour: 10,
      minute: 0,
    );

    // Friday (Cuma) @ 18:00 (Day 5)
    await _scheduleWeeklyNotification(
      id: _fridayId,
      template: _fridayMessages[random.nextInt(_fridayMessages.length)],
      dayOfWeek: DateTime.friday,
      hour: 18,
      minute: 0,
    );

    // Sunday (Pazar) @ 13:00 (Day 7)
    await _scheduleWeeklyNotification(
      id: _sundayId,
      template: _sundayMessages[random.nextInt(_sundayMessages.length)],
      dayOfWeek: DateTime.sunday,
      hour: 13,
      minute: 0,
    );

    await prefs.setBool(_weeklyScheduledKey, true);
    debugPrint('[DailyNotif] Özel gün bazlı haftalık bildirimler başarıyla planlandı.');
  }

  NotificationDetails _getDetails() {
    return const NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        'Seydi Rehber Bildirimleri',
        channelDescription: 'Seydişehir güncel rehber bildirimleri.',
        importance: Importance.max,
        priority: Priority.max,
        icon: 'ic_stat_s',
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  Future<void> _scheduleWeeklyNotification({
    required int id,
    required _NotifTemplate template,
    required int dayOfWeek,
    required int hour,
    required int minute,
  }) async {
    try {
      final scheduledDate = _nextOccurrenceForDay(dayOfWeek, hour, minute);

      await _localNotif.zonedSchedule(
        id: id,
        title: template.title,
        body: template.body,
        scheduledDate: scheduledDate,
        notificationDetails: _getDetails(),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: template.route,
      );
    } catch (e) {
      debugPrint('[DailyNotif] HATA! ID=$id planlanamadı: $e');
    }
  }

  Future<void> _cancelDailyNotifications() async {
    try {
      await _localNotif.cancel(id: _mondayId);
      await _localNotif.cancel(id: _thursdayId);
      await _localNotif.cancel(id: _fridayId);
      await _localNotif.cancel(id: _sundayId);
    } catch (e) {
      debugPrint('Cancel error: $e');
    }
  }

  tz.TZDateTime _nextOccurrenceForDay(int dayOfWeek, int hour, int minute) {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    
    // Find the next occurrence of this day of the week in the future
    while (scheduledDate.weekday != dayOfWeek || scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }
    return scheduledDate;
  }

  Future<bool> isDailyNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_dailyNotifEnabledKey) ?? true;
  }

  Future<void> setDailyNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_dailyNotifEnabledKey, enabled);
    if (enabled) {
      await prefs.remove(_weeklyScheduledKey);
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
