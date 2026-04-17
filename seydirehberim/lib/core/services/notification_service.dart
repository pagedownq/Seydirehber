import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'daily_notification_service.dart';

typedef NavigateToCallback = void Function(String route);

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  NavigateToCallback? _navigateTo;
  String? _pendingRoute;

  set navigateTo(NavigateToCallback? callback) {
    _navigateTo = callback;
    if (_navigateTo != null && _pendingRoute != null) {
      final route = _pendingRoute!;
      _pendingRoute = null;
      _navigateTo!(route);
    }
  }

  NavigateToCallback? get navigateTo => _navigateTo;

  static const String channelId = 'seydirehberim_notifications';

  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    channelId,
    'Seydi Rehber Bildirimleri',
    description: 'Şehir duyuruları ve önemli bildirimler için kullanılır.',
    importance: Importance.max,
  );

  static const String _installationDateKey = 'installationDate';

  Future<void> initialize() async {
    // 1. Initialize First Use Date if not set
    await _initInstallationDate();

    // Request permissions for Android 13+
    if (Platform.isAndroid) {
      final androidPlugin = _localNotificationsPlugin
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(_channel);
    }

    // Initialize local notifications
    const initializationSettingsAndroid =
        AndroidInitializationSettings('ic_stat_s');
    const initializationSettingsIOS = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _localNotificationsPlugin.initialize(
      settings: initializationSettings,
      onDidReceiveNotificationResponse: (details) {
        if (details.payload != null) {
          if (navigateTo != null) {
            navigateTo!(details.payload!);
          } else {
            _pendingRoute = details.payload;
          }
        }
      },
    );

    // 2. Handle deep link when app is terminated
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleMessage(initialMessage);
    }

    // 3. Handle deep link when app is in background/background
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessage);


    // Handle background messages
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

    // Listen to foreground messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      RemoteNotification? notification = message.notification;
      AndroidNotification? android = message.notification?.android;

      if (notification != null && android != null) {
        String? screen = message.data['screen'];
        
        _localNotificationsPlugin.show(
          id: notification.hashCode,
          title: notification.title,
          body: notification.body,
          payload: screen,
          notificationDetails: NotificationDetails(
            android: AndroidNotificationDetails(
              _channel.id,
              _channel.name,
              channelDescription: _channel.description,
              icon: android.smallIcon,
            ),
          ),
        );
      }
    });

    // Get FCM token
    String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _saveTokenToFirestore(token);
      
      // Handle topic subscription based on user preference
      final isEnabled = await isNotificationsEnabled();
      if (isEnabled) {
        await _firebaseMessaging.subscribeToTopic('all');
        debugPrint('Auto-subscribed to "all" topic on init');
      } else {
        await _firebaseMessaging.unsubscribeFromTopic('all');
        debugPrint('Auto-unsubscribed from "all" topic on init');
      }
    }
  }

  Future<void> _initInstallationDate() async {
    final prefs = await SharedPreferences.getInstance();
    if (prefs.getString('installationDate') == null) {
      // First time opening the app
      final now = DateTime.now().toIso8601String();
      await prefs.setString(_installationDateKey, now);
    }
  }

  Future<DateTime?> getInstallationDate() async {
    final prefs = await SharedPreferences.getInstance();
    final dateStr = prefs.getString(_installationDateKey);
    if (dateStr != null) {
      return DateTime.parse(dateStr);
    }
    return null;
  }

  // --- OOB Notification Toggle Logic ---
  static const String _notificationsEnabledKey = 'notifications_enabled';

  Future<bool> isNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    // Default to true if not set
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);

    if (enabled) {
      await _firebaseMessaging.subscribeToTopic('all');
      debugPrint('Subscribed to "all" topic');
      // Ana bildirimler açıldığında günlük bildirimleri de yeniden planla
      DailyNotificationService()
          .scheduleDailyNotifications()
          .catchError((e) => debugPrint('DailyNotif reschedule error: $e'));
    } else {
      await _firebaseMessaging.unsubscribeFromTopic('all');
      debugPrint('Unsubscribed from "all" topic');
      // Ana bildirimler kapatıldığında günlük bildirimleri de iptal et
      DailyNotificationService()
          .setDailyNotificationsEnabled(false)
          .catchError((e) => debugPrint('DailyNotif cancel error: $e'));
    }
  }

  void _handleMessage(RemoteMessage message) {
    final screen = message.data['screen'];
    if (screen != null) {
      if (navigateTo != null) {
        navigateTo!(screen);
      } else {
        _pendingRoute = screen;
      }
    }
  }

  Future<void> _saveTokenToFirestore(String token) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final docRef = FirebaseFirestore.instance.collection('user_tokens').doc(token);
      
      await docRef.set({
        'token': token,
        'userId': user?.uid,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'lastUpdated': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      
      await _firebaseMessaging.subscribeToTopic('all');
    } catch (e) {
      print('Token error: $e');
    }
  }

  Future<void> showTestNotification({String? title, String? body}) async {
    const androidDetails = AndroidNotificationDetails(
      channelId,
      'Seydi Rehber Bildirimleri',
      channelDescription: 'Şehir duyuruları ve önemli bildirimler için kullanılır.',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
      icon: 'ic_stat_s',
    );
    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotificationsPlugin.show(
      id: 0,
      title: title ?? 'Test Bildirimi 🔔',
      body: body ?? 'Bildirim sistemi başarıyla çalışıyor!',
      notificationDetails: notificationDetails,
    );
  }
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Silence is golden
}
